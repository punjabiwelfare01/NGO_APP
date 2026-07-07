"""Single entry point for volunteer work submission.

Unifies what used to be two separate code paths — one for submitting
against a known ActivityAssignment, one for a bare activity_id with no
assignment — into one flow: resolve (or auto-create) the assignment, then
create a fresh submission or update an in-flight one in place (resubmit).
"""
from __future__ import annotations

from sqlalchemy import and_, or_
from sqlalchemy.orm import Session
from fastapi import HTTPException

from ..models.user import User, UserRole
from ..models.volunteer import ActivityAssignment, ReviewTarget, SubmissionStatus, VolunteerActivity, WorkSubmission
from ..schemas.volunteer import WorkSubmissionCreate

# Assignment has already been through the full approval pipeline — the
# underlying submission is locked and can no longer be edited/resubmitted.
_LOCKED_ASSIGNMENT_STATUSES = ("admin_approved", "certificate_generated", "completed")

# Assignment has a submission in flight — a new call for the same
# activity should update it in place rather than create a duplicate.
_RESUBMITTABLE_ASSIGNMENT_STATUSES = ("submitted", "resubmission_requested", "event_manager_verified")


def submit_work(db: Session, student_id: int, data: WorkSubmissionCreate) -> WorkSubmission:
    activity = db.query(VolunteerActivity).filter(VolunteerActivity.id == data.activity_id).first()
    if not activity:
        raise HTTPException(404, "Activity not found")

    assignment = _resolve_assignment(db, student_id, data.activity_id, data.assignment_id)

    if assignment.status in _LOCKED_ASSIGNMENT_STATUSES:
        raise HTTPException(409, "Work is already approved — it cannot be resubmitted")

    existing = _find_existing_submission(db, student_id, assignment)
    if existing and assignment.status in _RESUBMITTABLE_ASSIGNMENT_STATUSES:
        submission = _apply_update(existing, data, assignment)
        if data.review_target is not None:
            submission.review_target = data.review_target
    else:
        submission = _build_new(student_id, data, assignment)
        submission.review_target = data.review_target or _default_review_target(db, activity)
        db.add(submission)
        assignment.status = "submitted"

    db.commit()
    db.refresh(submission)
    return submission


def _resolve_assignment(
    db: Session, student_id: int, activity_id: int, assignment_id: int | None,
) -> ActivityAssignment:
    if assignment_id is not None:
        assignment = (
            db.query(ActivityAssignment).filter(ActivityAssignment.id == assignment_id).first()
        )
        if not assignment or assignment.student_id != student_id:
            raise HTTPException(404, "Assignment not found")
        return assignment

    assignment = (
        db.query(ActivityAssignment)
        .filter(
            ActivityAssignment.student_id == student_id,
            ActivityAssignment.activity_id == activity_id,
        )
        .order_by(ActivityAssignment.created_at.desc())
        .first()
    )
    # A locked assignment represents a finished, already-certified cycle —
    # start a fresh one instead of permanently blocking further
    # participation in a recurring activity (e.g. a volunteer who tutors
    # the same activity again after their first round was certified).
    if assignment and assignment.status not in _LOCKED_ASSIGNMENT_STATUSES:
        return assignment

    assignment = ActivityAssignment(student_id=student_id, activity_id=activity_id, status="assigned")
    db.add(assignment)
    db.flush()
    return assignment


def _find_existing_submission(
    db: Session, student_id: int, assignment: ActivityAssignment,
) -> WorkSubmission | None:
    return (
        db.query(WorkSubmission)
        .filter(
            or_(
                WorkSubmission.assignment_id == assignment.id,
                and_(
                    WorkSubmission.assignment_id.is_(None),
                    WorkSubmission.student_id == student_id,
                    WorkSubmission.activity_id == assignment.activity_id,
                ),
            )
        )
        .order_by(WorkSubmission.created_at.desc())
        .first()
    )


def _apply_update(
    existing: WorkSubmission, data: WorkSubmissionCreate, assignment: ActivityAssignment,
) -> WorkSubmission:
    existing.title = data.title
    existing.description = data.description
    existing.hours_worked = data.hours_worked
    existing.people_reached = data.people_reached
    existing.donation_collected = data.donation_collected
    existing.transaction_id = data.transaction_id
    existing.remarks = data.remarks
    if data.proof_files is not None:
        existing.proof_files = data.proof_files
    existing.status = SubmissionStatus.submitted
    if existing.assignment_id is None:
        existing.assignment_id = assignment.id
    assignment.status = "submitted"
    return existing


def _build_new(
    student_id: int, data: WorkSubmissionCreate, assignment: ActivityAssignment,
) -> WorkSubmission:
    dump = data.model_dump()
    dump["assignment_id"] = assignment.id
    return WorkSubmission(**dump, student_id=student_id)


def _default_review_target(db: Session, activity: VolunteerActivity) -> ReviewTarget:
    """Auto-route: an activity created by an event manager goes to that
    event manager's queue; everything else (admin-created, or no creator
    on record) goes to the admin queue."""
    if activity.created_by is not None:
        creator = db.query(User).filter(User.id == activity.created_by).first()
        if creator and creator.role == UserRole.event_manager:
            return ReviewTarget.event_manager
    return ReviewTarget.admin
