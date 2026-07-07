from __future__ import annotations

import json
from datetime import date
from typing import List, Optional

from sqlalchemy.orm import Session

from ..models.volunteer import (
    ActivityApplication, ActivityAssignment, ActivityCategory, DailyLog,
    ImpactStory, ReviewTarget, SubmissionStatus, VolunteerActivity, WorkSubmission,
)
from ..schemas.volunteer import (
    ActivityAssignmentCreate, DailyLogCreate, DailyLogUpdate,
    ImpactStoryCreate, VolunteerActivityCreate, VolunteerActivityUpdate,
    WorkSubmissionReview,
)


# ── VolunteerActivity ─────────────────────────────────────────────────────────

def create_activity(db: Session, data: VolunteerActivityCreate, creator_id: int) -> VolunteerActivity:
    obj = VolunteerActivity(**data.model_dump(), created_by=creator_id)
    db.add(obj)
    db.commit()
    db.refresh(obj)
    return obj


def get_activities(
    db: Session,
    category: Optional[ActivityCategory] = None,
    active_only: bool = True,
) -> List[VolunteerActivity]:
    q = db.query(VolunteerActivity)
    if active_only:
        q = q.filter(VolunteerActivity.is_active.is_(True))
    if category:
        q = q.filter(VolunteerActivity.category == category)
    return q.order_by(VolunteerActivity.id.desc()).all()


def get_activity(db: Session, activity_id: int) -> Optional[VolunteerActivity]:
    return db.query(VolunteerActivity).filter(VolunteerActivity.id == activity_id).first()


def get_activities_by_creator(db: Session, creator_id: int) -> List[VolunteerActivity]:
    return (
        db.query(VolunteerActivity)
        .filter(VolunteerActivity.created_by == creator_id)
        .order_by(VolunteerActivity.created_at.desc())
        .all()
    )


def update_activity(db: Session, activity_id: int, data: VolunteerActivityUpdate) -> Optional[VolunteerActivity]:
    obj = get_activity(db, activity_id)
    if not obj:
        return None
    for k, v in data.model_dump(exclude_none=True).items():
        setattr(obj, k, v)
    db.commit()
    db.refresh(obj)
    return obj


# ── ActivityAssignment ────────────────────────────────────────────────────────

def assign_activity(db: Session, data: ActivityAssignmentCreate, assigner_id: int) -> ActivityAssignment:
    obj = ActivityAssignment(**data.model_dump(), assigned_by=assigner_id)
    db.add(obj)
    db.commit()
    db.refresh(obj)
    return obj


def get_assignments_for_student(db: Session, student_id: int) -> List[ActivityAssignment]:
    return (
        db.query(ActivityAssignment)
        .filter(ActivityAssignment.student_id == student_id)
        .order_by(ActivityAssignment.created_at.desc())
        .all()
    )


def get_all_assignments(db: Session) -> List[ActivityAssignment]:
    return db.query(ActivityAssignment).order_by(ActivityAssignment.created_at.desc()).all()


def get_assignment(db: Session, assignment_id: int) -> Optional[ActivityAssignment]:
    return db.query(ActivityAssignment).filter(ActivityAssignment.id == assignment_id).first()


def apply_for_activity(
    db: Session, activity_id: int, student_id: int, note: Optional[str] = None
) -> ActivityApplication:
    existing = db.query(ActivityApplication).filter(
        ActivityApplication.activity_id == activity_id,
        ActivityApplication.student_id == student_id,
    ).first()
    if existing:
        return existing
    application = ActivityApplication(
        activity_id=activity_id,
        student_id=student_id,
        note=note,
        status="applied",
    )
    assignment = ActivityAssignment(
        activity_id=activity_id,
        student_id=student_id,
        status="applied",
        notes=note,
    )
    db.add_all([application, assignment])
    db.commit()
    db.refresh(application)
    return application


def get_application(db: Session, activity_id: int, student_id: int) -> Optional[ActivityApplication]:
    return db.query(ActivityApplication).filter(
        ActivityApplication.activity_id == activity_id,
        ActivityApplication.student_id == student_id,
    ).first()


def get_applications_for_student(db: Session, student_id: int) -> List[ActivityApplication]:
    return db.query(ActivityApplication).filter(
        ActivityApplication.student_id == student_id
    ).order_by(ActivityApplication.applied_at.desc()).all()


# ── WorkSubmission ────────────────────────────────────────────────────────────

def get_submissions_for_student(db: Session, student_id: int) -> List[WorkSubmission]:
    return (
        db.query(WorkSubmission)
        .filter(WorkSubmission.student_id == student_id)
        .order_by(WorkSubmission.created_at.desc())
        .all()
    )


def get_pending_submissions(db: Session) -> List[WorkSubmission]:
    return (
        db.query(WorkSubmission)
        .filter(
            WorkSubmission.review_target == ReviewTarget.admin,
            WorkSubmission.status.in_([
                SubmissionStatus.submitted, SubmissionStatus.under_review,
            ]),
        )
        .order_by(WorkSubmission.created_at.desc())
        .all()
    )


def get_approved_submissions(db: Session) -> List[WorkSubmission]:
    return (
        db.query(WorkSubmission)
        .filter(
            WorkSubmission.review_target == ReviewTarget.admin,
            WorkSubmission.status == SubmissionStatus.approved,
        )
        .order_by(WorkSubmission.reviewed_at.desc())
        .all()
    )


def get_submission(db: Session, submission_id: int) -> Optional[WorkSubmission]:
    return db.query(WorkSubmission).filter(WorkSubmission.id == submission_id).first()


def review_submission(
    db: Session,
    submission_id: int,
    data: WorkSubmissionReview,
    reviewer_id: int,
) -> Optional[WorkSubmission]:
    from datetime import datetime
    obj = get_submission(db, submission_id)
    if not obj:
        return None
    obj.status = data.status
    obj.reviewer_notes = data.reviewer_notes
    obj.reviewed_by = reviewer_id
    obj.reviewed_at = datetime.utcnow()
    if obj.assignment_id:
        assignment = get_assignment(db, obj.assignment_id)
        if assignment:
            assignment.status = (
                "admin_approved" if data.status == SubmissionStatus.approved
                else "rejected" if data.status == SubmissionStatus.rejected
                else "submitted"
            )
    db.commit()
    db.refresh(obj)
    return obj


# ── DailyLog ──────────────────────────────────────────────────────────────────

def create_daily_log(db: Session, data: DailyLogCreate, student_id: int) -> DailyLog:
    obj = DailyLog(**data.model_dump(), student_id=student_id)
    db.add(obj)
    db.commit()
    db.refresh(obj)
    return obj


def get_logs_for_student(db: Session, student_id: int) -> List[DailyLog]:
    return (
        db.query(DailyLog)
        .filter(DailyLog.student_id == student_id)
        .order_by(DailyLog.date.desc())
        .all()
    )


def get_public_logs(db: Session) -> List[DailyLog]:
    return (
        db.query(DailyLog)
        .filter(DailyLog.is_public.is_(True))
        .order_by(DailyLog.date.desc())
        .all()
    )


def get_log(db: Session, log_id: int) -> Optional[DailyLog]:
    return db.query(DailyLog).filter(DailyLog.id == log_id).first()


def update_log(db: Session, log_id: int, data: DailyLogUpdate) -> Optional[DailyLog]:
    obj = get_log(db, log_id)
    if not obj:
        return None
    for k, v in data.model_dump(exclude_none=True).items():
        setattr(obj, k, v)
    db.commit()
    db.refresh(obj)
    return obj


def approve_log(db: Session, log_id: int) -> Optional[DailyLog]:
    obj = get_log(db, log_id)
    if not obj:
        return None
    obj.status = "approved"
    obj.is_public = True
    db.commit()
    db.refresh(obj)
    return obj


# ── ImpactStory ───────────────────────────────────────────────────────────────

def create_impact_story(db: Session, data: ImpactStoryCreate, creator_id: int) -> ImpactStory:
    obj = ImpactStory(**data.model_dump(), created_by=creator_id)
    db.add(obj)
    db.commit()
    db.refresh(obj)
    return obj


def get_public_stories(db: Session, featured_only: bool = False) -> List[ImpactStory]:
    q = db.query(ImpactStory).filter(ImpactStory.is_public.is_(True))
    if featured_only:
        q = q.filter(ImpactStory.is_featured.is_(True))
    return q.order_by(ImpactStory.created_at.desc()).all()


def publish_story(db: Session, story_id: int) -> Optional[ImpactStory]:
    obj = db.query(ImpactStory).filter(ImpactStory.id == story_id).first()
    if not obj:
        return None
    obj.is_public = True
    db.commit()
    db.refresh(obj)
    return obj


# ── Volunteer stats ───────────────────────────────────────────────────────────

def get_volunteer_stats(db: Session, student_id: int) -> dict:
    from ..models.certificate import Certificate, CertificateStatus

    total_hours = (
        db.query(WorkSubmission)
        .filter(
            WorkSubmission.student_id == student_id,
            WorkSubmission.status == SubmissionStatus.approved,
        )
        .all()
    )
    hours = sum(s.hours_worked for s in total_hours)
    donations = sum(s.donation_collected for s in total_hours)
    completed = len(total_hours)

    pending = (
        db.query(WorkSubmission)
        .filter(
            WorkSubmission.student_id == student_id,
            WorkSubmission.status.in_([
                SubmissionStatus.submitted, SubmissionStatus.under_review,
            ]),
        )
        .count()
    )

    certs = (
        db.query(Certificate)
        .filter(
            Certificate.student_id == student_id,
            Certificate.status == CertificateStatus.issued,
        )
        .count()
    )

    if hours >= 100:
        rank = "Platinum"
    elif hours >= 50:
        rank = "Gold"
    elif hours >= 20:
        rank = "Silver"
    else:
        rank = "Bronze"

    return {
        "total_hours": round(hours, 1),
        "activities_completed": completed,
        "donation_raised": round(donations, 2),
        "certificates_earned": certs,
        "pending_approvals": pending,
        "volunteer_rank": rank,
    }


def get_student_work_summary(db: Session, student_id: int) -> dict:
    summary = get_volunteer_stats(db, student_id)
    assignments = get_assignments_for_student(db, student_id)
    counts = {
        "applied": 0,
        "assigned": 0,
        "in_progress": 0,
        "submitted": 0,
        "verified": 0,
        "completed": 0,
    }
    for assignment in assignments:
        status = assignment.status
        if status in counts:
            counts[status] += 1
        elif status in ("event_manager_verified", "admin_approved", "certificate_generated"):
            counts["verified"] += 1
        elif status == "rejected":
            continue
    summary.update(counts)
    summary["open_activities"] = db.query(VolunteerActivity).filter(
        VolunteerActivity.is_active.is_(True)
    ).count()
    return summary
