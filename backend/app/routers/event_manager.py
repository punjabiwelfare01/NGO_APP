import json
from datetime import date, datetime
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import and_, or_
from sqlalchemy.orm import Session

from ..database import get_db
from ..dependencies import require_role
from ..models.certificate import Certificate
from ..models.event import Event
from ..models.impact import ImpactPost
from ..models.user import User, UserRole
from ..models.volunteer import (
    ActivityAssignment,
    DailyLog,
    SubmissionStatus,
    VolunteerActivity,
    WorkSubmission,
)
from ..schemas.volunteer import VolunteerActivityUpdate
from ..services import notification_service

router = APIRouter(prefix="/event-manager", tags=["Event Manager Workspace"])


def _manager(user: User = Depends(require_role(UserRole.event_manager))) -> User:
    return user


def _category(value: str) -> str:
    return {"awareness_campaign": "awarenessCampaign", "talent_hunt": "talentHunt", "counselling_drive": "counsellingDrive", "cyber_security": "cyberSecurity", "daily_challenge": "quizEvent"}.get(value, value)


def _status(value: str) -> str:
    return {"live": "ongoing", "evaluation": "ongoing", "selection": "ongoing", "pending_review": "draft"}.get(value, value)


def _assignment_status(value: str) -> str:
    return {"submitted": "workSubmitted", "event_manager_verified": "verified", "admin_approved": "approved", "certificate_generated": "certificateEligible", "completed": "certificateEligible", "in_progress": "assigned"}.get(value, value)


def _event_json(event: Event, activities: list[VolunteerActivity]) -> dict:
    activity_json = []
    for activity in activities:
        activity_json.append({"id": activity.id, "event_id": event.id, "title": activity.title, "role": "volunteerSupport", "description": activity.description, "max_students": activity.max_students or 20, "assigned_count": len(activity.assignments)})
    return {"id": event.id, "title": event.title, "category": _category(event.event_type.value), "status": _status(event.status.value), "date": (event.event_start or event.start_date or event.created_at).isoformat(), "location": next((a.location for a in activities if a.location), "Location to be confirmed"), "partner_school": None, "description": event.description or event.subtitle or "NGO event", "banner_image_url": event.banner_url, "max_volunteers": event.max_participants or sum((a.max_students or 0) for a in activities) or 20, "student_eligibility": None, "expected_work": next((a.expected_work for a in activities if a.expected_work), None), "proof_required": next((a.proof_required for a in activities if a.proof_required), None), "certificate_eligible": event.certificate_enabled, "donation_eligible": any((a.stipend_amount or 0) > 0 for a in activities), "stipend_amount": next((a.stipend_amount for a in activities if a.stipend_amount), None), "activities": activity_json, "created_at": event.created_at.isoformat() if event.created_at else date.today().isoformat()}


@router.get("/dashboard")
def dashboard(db: Session = Depends(get_db), user: User = Depends(_manager)):
    # ── Events ────────────────────────────────────────────────────────────────
    event_query = db.query(Event)
    if user.role == UserRole.event_manager:
        event_query = event_query.filter(Event.created_by == user.id)
    events = event_query.order_by(Event.created_at.desc()).all()
    event_ids = [e.id for e in events]

    # ── Activities linked to events ───────────────────────────────────────────
    event_activities = (
        db.query(VolunteerActivity).filter(VolunteerActivity.event_id.in_(event_ids)).all()
        if event_ids else []
    )
    by_event: dict = {eid: [] for eid in event_ids}
    for a in event_activities:
        by_event.setdefault(a.event_id, []).append(a)
    event_payload = {e.id: _event_json(e, by_event.get(e.id, [])) for e in events}

    # ── Standalone activities created by this EM (no event) ──────────────────
    standalone_activities = (
        db.query(VolunteerActivity)
        .filter(
            VolunteerActivity.event_id.is_(None),
            VolunteerActivity.created_by == user.id,
        )
        .all()
        if user.role == UserRole.event_manager
        else db.query(VolunteerActivity).filter(VolunteerActivity.event_id.is_(None)).all()
    )

    all_activities = event_activities + standalone_activities
    activity_ids = [a.id for a in all_activities]

    # ── Assignments ───────────────────────────────────────────────────────────
    assignments = (
        db.query(ActivityAssignment)
        .filter(ActivityAssignment.activity_id.in_(activity_ids))
        .all()
        if activity_ids else []
    )

    def _activity_stub(activity: VolunteerActivity) -> dict:
        return {
            "id": activity.id,
            "event_id": activity.event_id,
            "title": activity.title,
            "role": "volunteerSupport",
            "description": activity.description,
            "max_students": activity.max_students or 20,
            "assigned_count": len(activity.assignments),
        }

    def _stub_event_for_activity(activity: VolunteerActivity) -> dict:
        return {
            "id": activity.id,
            "title": activity.title,
            "category": "volunteerSupport",
            "status": "published",
            "date": date.today().isoformat(),
            "location": activity.location or "",
            "description": activity.description or "",
            "banner_image_url": None,
            "max_volunteers": activity.max_students or 20,
            "student_eligibility": None,
            "expected_work": activity.expected_work,
            "proof_required": activity.proof_required,
            "certificate_eligible": activity.certificate_eligible,
            "donation_eligible": False,
            "stipend_amount": activity.stipend_amount,
            "activities": [_activity_stub(activity)],
            "created_at": date.today().isoformat(),
        }

    assignment_payload = []
    for assignment in assignments:
        activity = assignment.activity
        # Resolve the event payload — use a stub for standalone activities
        event = event_payload.get(activity.event_id) if activity.event_id else None
        if event is None:
            event = _stub_event_for_activity(activity)
        # Resolve the activity entry within the event
        activity_entry = next(
            (item for item in event["activities"] if item["id"] == activity.id),
            _activity_stub(activity),
        )
        submission = (
            db.query(WorkSubmission)
            .filter(
                or_(
                    WorkSubmission.assignment_id == assignment.id,
                    and_(
                        WorkSubmission.assignment_id.is_(None),
                        WorkSubmission.student_id == assignment.student_id,
                        WorkSubmission.activity_id == assignment.activity_id,
                    ),
                )
            )
            .order_by(WorkSubmission.created_at.desc())
            .first()
        )
        stats = [
            item for item in
            db.query(WorkSubmission).filter(WorkSubmission.student_id == assignment.student_id).all()
            if str(item.status).endswith("approved")
        ]
        assignment_payload.append({
            "id": assignment.id,
            "student": {
                "id": assignment.student.id,
                "name": assignment.student.name,
                "email": assignment.student.email or "",
                "location": assignment.student.location,
                "phone": assignment.student.phone,
                "hours_served": int(sum(item.hours_worked for item in stats)),
                "activities_completed": len(stats),
            },
            "activity": activity_entry,
            "event": event,
            "status": _assignment_status(assignment.status),
            "applied_at": assignment.created_at.isoformat(),
            "instructions": assignment.notes,
            "reviewer_notes": submission.reviewer_notes if submission else None,
            "submission": None if not submission else {
                "id": submission.id,
                "assignment_id": assignment.id,
                "work_title": submission.title,
                "description": submission.description,
                "hours_worked": submission.hours_worked,
                "people_reached": submission.people_reached,
                "donation_collected": submission.donation_collected,
                "transaction_id": submission.transaction_id,
                "remarks": submission.remarks,
                "photo_urls": json.loads(submission.proof_files or "[]"),
                "submitted_at": submission.created_at.isoformat(),
            },
        })

    # ── Impact posts ──────────────────────────────────────────────────────────
    if user.role in (UserRole.admin, UserRole.super_admin):
        impacts = db.query(ImpactPost).order_by(ImpactPost.created_at.desc()).all()
    else:
        # Include posts linked to the EM's events AND standalone posts they created
        # (standalone posts have event_id = None and would otherwise be invisible).
        conditions = [ImpactPost.created_by == user.id]
        if event_ids:
            conditions.append(ImpactPost.event_id.in_(event_ids))
        impacts = (
            db.query(ImpactPost)
            .filter(or_(*conditions))
            .order_by(ImpactPost.created_at.desc())
            .all()
        )
    impact_payload = [
        {
            "id": item.id,
            "type": item.category,
            "title": item.title,
            "student_name": item.student_names,
            "team_name": item.team_name,
            "event_name": event_payload.get(item.event_id, {}).get("title", "NGO Event"),
            "location": item.location or "",
            "date": (item.published_at or item.created_at).isoformat(),
            "description": item.description,
            "appreciation_message": "Thank you to everyone who made this impact possible.",
            "students_helped": item.people_reached,
            "hours_served": item.hours_served,
            "donation_raised": item.donation_collected,
            "photo_urls": [media.url for media in item.media],
            "is_published": item.status in ("pending_review", "published"),
            "admin_approved": item.approved_by is not None,
            "verified_by_name": "NGO Admin" if item.approved_by else "Pending approval",
        }
        for item in impacts
    ]

    today = date.today()
    return {
        "stats": {
            "today_events": sum(1 for e in events if (e.event_start or e.start_date or e.created_at).date() == today),
            "active_activities": sum(1 for e in events if e.status.value in ("published", "registration_open", "live")),
            "pending_submissions": sum(1 for a in assignments if a.status == "submitted"),
            "students_assigned": len(assignments),
            "pending_impact_posts": sum(1 for p in impacts if p.status != "published"),
            "total_events_this_month": sum(1 for e in events if e.created_at and e.created_at.month == today.month and e.created_at.year == today.year),
        },
        "events": list(event_payload.values()),
        "assignments": assignment_payload,
        "impact_posts": impact_payload,
    }


@router.patch("/assignments/{assignment_id}")
def update_assignment(assignment_id: int, payload: dict, db: Session = Depends(get_db), user: User = Depends(_manager)):
    assignment = db.query(ActivityAssignment).filter(ActivityAssignment.id == assignment_id).first()
    if not assignment: raise HTTPException(404, "Assignment not found")
    mapping = {"workSubmitted": "submitted", "verified": "event_manager_verified", "approved": "admin_approved", "certificateEligible": "certificate_generated"}
    if "status" in payload: assignment.status = mapping.get(payload["status"], payload["status"])
    if payload.get("instructions") is not None: assignment.notes = payload["instructions"]
    notification_service.notify(db, assignment.student_id, "assignment_update", "Volunteer assignment updated", f"{assignment.activity.title}: {assignment.status}", entity_type="assignment", entity_id=assignment.id, commit=False)
    db.commit(); return {"ok": True}


@router.get("/activities/{activity_id}/tracking")
def get_activity_tracking(activity_id: int, db: Session = Depends(get_db), user: User = Depends(_manager)):
    activity = db.query(VolunteerActivity).filter(VolunteerActivity.id == activity_id).first()
    if not activity:
        raise HTTPException(404, "Activity not found")

    assignments = db.query(ActivityAssignment).filter(ActivityAssignment.activity_id == activity_id).all()

    def _submission_obj(sub: WorkSubmission) -> dict:
        return {
            "id": sub.id,
            "title": sub.title,
            "description": sub.description,
            "hours_worked": sub.hours_worked,
            "people_reached": sub.people_reached,
            "donation_collected": sub.donation_collected,
            "transaction_id": sub.transaction_id,
            "remarks": sub.remarks,
            "reviewer_notes": sub.reviewer_notes,
            "status": sub.status.value if sub.status else None,
            "proof_files": json.loads(sub.proof_files or "[]"),
            "submitted_at": sub.created_at.isoformat() if sub.created_at else None,
        }

    def _log_obj(log: DailyLog) -> dict:
        return {
            "id": log.id,
            "date": log.date.isoformat() if log.date else None,
            "title": log.title,
            "content": log.content,
            "reflection": log.reflection,
            "media_files": json.loads(log.media_files or "[]"),
            "status": log.status,
            "is_public": log.is_public,
            "created_at": log.created_at.isoformat() if log.created_at else None,
        }

    submitted_statuses = {"submitted", "event_manager_verified"}
    approved_statuses = {"event_manager_verified", "admin_approved", "certificate_generated", "completed"}
    pending_statuses = {"assigned", "in_progress", "resubmission_requested"}

    total_submitted = 0
    total_approved = 0
    total_pending = 0

    students_payload = []
    for assignment in assignments:
        # Count stats by assignment status
        if assignment.status in submitted_statuses:
            total_submitted += 1
        if assignment.status in approved_statuses:
            total_approved += 1
        if assignment.status in pending_statuses:
            total_pending += 1

        # Resolve all submissions for this student/assignment
        all_subs = (
            db.query(WorkSubmission)
            .filter(
                or_(
                    WorkSubmission.assignment_id == assignment.id,
                    and_(
                        WorkSubmission.assignment_id.is_(None),
                        WorkSubmission.student_id == assignment.student_id,
                        WorkSubmission.activity_id == activity_id,
                    ),
                )
            )
            .order_by(WorkSubmission.created_at.desc())
            .all()
        )

        latest_sub = all_subs[0] if all_subs else None

        # All daily logs for this student
        daily_logs = (
            db.query(DailyLog)
            .filter(DailyLog.student_id == assignment.student_id)
            .order_by(DailyLog.date.desc())
            .all()
        )

        student = assignment.student
        students_payload.append({
            "assignment_id": assignment.id,
            "student": {
                "id": student.id,
                "name": student.name,
                "email": student.email or "",
                "phone": student.phone,
                "location": student.location,
            },
            "assignment_status": _assignment_status(assignment.status),
            "assigned_at": assignment.created_at.isoformat() if assignment.created_at else None,
            "instructions": assignment.notes,
            "latest_submission": _submission_obj(latest_sub) if latest_sub else None,
            "all_submissions": [_submission_obj(s) for s in all_subs],
            "daily_logs": [_log_obj(log) for log in daily_logs],
        })

    return {
        "activity": {
            "id": activity.id,
            "title": activity.title,
            "description": activity.description,
            "location": activity.location,
            "expected_work": activity.expected_work,
            "reward_hours": activity.reward_hours,
            "max_students": activity.max_students,
            "certificate_eligible": activity.certificate_eligible,
        },
        "stats": {
            "total_assigned": len(assignments),
            "submitted": total_submitted,
            "approved": total_approved,
            "pending": total_pending,
        },
        "students": students_payload,
    }


@router.patch("/submissions/{submission_id}/review")
def review_submission(submission_id: int, payload: dict, db: Session = Depends(get_db), user: User = Depends(_manager)):
    sub = db.query(WorkSubmission).filter(WorkSubmission.id == submission_id).first()
    if not sub:
        raise HTTPException(404, "Submission not found")

    valid_statuses = {"submitted", "under_review", "approved", "rejected", "needs_correction"}
    new_status_str = payload.get("status")
    if not new_status_str or new_status_str not in valid_statuses:
        raise HTTPException(400, f"Invalid status. Must be one of: {', '.join(sorted(valid_statuses))}")

    try:
        sub.status = SubmissionStatus(new_status_str)
    except ValueError:
        raise HTTPException(400, f"Unknown status value: {new_status_str}")

    sub.reviewer_notes = payload.get("reviewer_notes")
    sub.reviewed_by = user.id
    sub.reviewed_at = datetime.utcnow()

    if new_status_str == "approved" and sub.assignment_id:
        assignment = db.query(ActivityAssignment).filter(ActivityAssignment.id == sub.assignment_id).first()
        if assignment:
            assignment.status = "event_manager_verified"

    if new_status_str in ("rejected", "needs_correction") and sub.assignment_id:
        assignment = db.query(ActivityAssignment).filter(ActivityAssignment.id == sub.assignment_id).first()
        if assignment:
            assignment.status = "resubmission_requested"

    db.commit()
    db.refresh(sub)

    return {
        "id": sub.id,
        "status": sub.status.value,
        "reviewer_notes": sub.reviewer_notes,
        "reviewed_at": sub.reviewed_at.isoformat() if sub.reviewed_at else None,
    }


# ── Activity Management ───────────────────────────────────────────────────────

def _allow_em_or_admin(user: User = Depends(require_role(UserRole.event_manager, UserRole.admin, UserRole.super_admin))) -> User:
    return user


def _activity_list_item(activity: VolunteerActivity, db: Session) -> dict:
    assignments = db.query(ActivityAssignment).filter(ActivityAssignment.activity_id == activity.id).all()
    completed_logs = [a for a in assignments if a.status in ("admin_approved", "certificate_generated", "completed")]
    pending_logs = [a for a in assignments if a.status in ("submitted", "event_manager_verified")]
    certs = db.query(Certificate).filter(Certificate.activity_id == activity.id).all() if hasattr(Certificate, "activity_id") else []
    impact = db.query(ImpactPost).filter(ImpactPost.activity_id == activity.id).first()

    creator = db.query(User).filter(User.id == activity.created_by).first() if activity.created_by else None
    event = db.query(Event).filter(Event.id == activity.event_id).first() if activity.event_id else None

    return {
        "id": activity.id,
        "title": activity.title,
        "category": activity.category.value,
        "event_id": activity.event_id,
        "event_name": event.title if event else None,
        "location": activity.location,
        "start_date": activity.start_date.isoformat() if activity.start_date else None,
        "end_date": activity.end_date.isoformat() if activity.end_date else None,
        "reward_hours": activity.reward_hours,
        "max_students": activity.max_students,
        "description": activity.description,
        "expected_work": activity.expected_work,
        "work_instructions": activity.work_instructions,
        "proof_required": activity.proof_required,
        "certificate_eligible": activity.certificate_eligible,
        "stipend_amount": activity.stipend_amount,
        "is_active": activity.is_active,
        "status": activity.status,
        "created_by": activity.created_by,
        "created_by_name": creator.name if creator else None,
        "created_at": activity.created_at.isoformat() if activity.created_at else None,
        "updated_at": activity.updated_at.isoformat() if activity.updated_at else None,
        "assigned_students": len(assignments),
        "completed_work_logs": len(completed_logs),
        "pending_approvals": len(pending_logs),
        "certificates_generated": len(certs),
        "impact_story_status": impact.status if impact else None,
    }


@router.get("/students")
def list_ngo_students(
    search: Optional[str] = Query(None),
    db: Session = Depends(get_db),
    user: User = Depends(_allow_em_or_admin),
):
    """Return all approved NGO students available for activity assignment."""
    q = db.query(User).filter(
        User.role == UserRole.student,
        User.access_status == "approved",
        User.is_active == True,
    )
    if search:
        q = q.filter(User.name.ilike(f"%{search}%"))
    students = q.order_by(User.name).all()
    return [
        {
            "id": s.id,
            "name": s.name,
            "email": s.email or "",
            "phone": s.phone,
            "location": s.location,
            "school_name": s.school_name,
            "class_name": s.class_name,
            "interests": json.loads(s.interests) if s.interests else [],
        }
        for s in students
    ]


@router.post("/activities", status_code=201)
def create_activity(
    payload: dict,
    db: Session = Depends(get_db),
    user: User = Depends(_allow_em_or_admin),
):
    """Create a new volunteer activity, optionally linked to a published event."""
    from ..models.volunteer import ActivityCategory

    title = payload.get("title", "").strip()
    if not title:
        raise HTTPException(400, "title is required")

    category_str = payload.get("category", "event_organization")
    try:
        category = ActivityCategory(category_str)
    except ValueError:
        category = ActivityCategory.event_organization

    event_id = payload.get("event_id")
    if event_id is not None:
        event = db.query(Event).filter(Event.id == event_id).first()
        if not event:
            raise HTTPException(404, f"Event {event_id} not found")

    start_date = None
    if payload.get("start_date"):
        try:
            start_date = date.fromisoformat(payload["start_date"])
        except (ValueError, TypeError):
            pass

    end_date = None
    if payload.get("end_date"):
        try:
            end_date = date.fromisoformat(payload["end_date"])
        except (ValueError, TypeError):
            pass

    activity = VolunteerActivity(
        title=title,
        category=category,
        event_id=event_id,
        description=payload.get("description") or None,
        location=payload.get("location") or None,
        expected_work=payload.get("expected_work") or None,
        work_instructions=payload.get("work_instructions") or None,
        proof_required=payload.get("proof_required") or None,
        reward_hours=float(payload.get("reward_hours") or 2.0),
        max_students=int(payload["max_students"]) if payload.get("max_students") else 20,
        certificate_eligible=bool(payload.get("certificate_eligible", True)),
        stipend_amount=float(payload["stipend_amount"]) if payload.get("stipend_amount") else None,
        start_date=start_date,
        end_date=end_date,
        status=payload.get("status", "active"),
        is_active=True,
        created_by=user.id,
    )
    db.add(activity)
    db.commit()
    db.refresh(activity)
    return _activity_list_item(activity, db)


@router.get("/activities")
def list_my_activities(
    status: Optional[str] = None,
    db: Session = Depends(get_db),
    user: User = Depends(_allow_em_or_admin),
):
    """Get activities created by the logged-in Event Manager (or all for admin)."""
    q = db.query(VolunteerActivity)
    if user.role == UserRole.event_manager:
        q = q.filter(VolunteerActivity.created_by == user.id)
    if status:
        q = q.filter(VolunteerActivity.status == status)
    activities = q.order_by(VolunteerActivity.created_at.desc()).all()
    return [_activity_list_item(a, db) for a in activities]


@router.put("/activities/{activity_id}")
def edit_activity(
    activity_id: int,
    payload: dict,
    db: Session = Depends(get_db),
    user: User = Depends(_allow_em_or_admin),
):
    """Edit an activity. EM can only edit their own; admin can edit all."""
    activity = db.query(VolunteerActivity).filter(VolunteerActivity.id == activity_id).first()
    if not activity:
        raise HTTPException(404, "Activity not found")
    if user.role == UserRole.event_manager and activity.created_by != user.id:
        raise HTTPException(403, "You can only edit activities you created")

    editable = {
        "title", "description", "category", "location", "start_date", "end_date",
        "max_students", "reward_hours", "work_instructions", "expected_work",
        "proof_required", "certificate_eligible", "stipend_amount", "status",
        "subdivision", "duration",
    }
    for key, val in payload.items():
        if key in editable:
            setattr(activity, key, val)

    db.commit()
    db.refresh(activity)
    return _activity_list_item(activity, db)


@router.get("/activities/{activity_id}/students")
def get_activity_students(
    activity_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(_allow_em_or_admin),
):
    activity = db.query(VolunteerActivity).filter(VolunteerActivity.id == activity_id).first()
    if not activity:
        raise HTTPException(404, "Activity not found")
    if user.role == UserRole.event_manager and activity.created_by != user.id:
        raise HTTPException(403, "Access denied")

    assignments = db.query(ActivityAssignment).filter(ActivityAssignment.activity_id == activity_id).all()
    result = []
    for a in assignments:
        student = a.student
        latest_sub = (
            db.query(WorkSubmission)
            .filter(WorkSubmission.student_id == student.id, WorkSubmission.activity_id == activity_id)
            .order_by(WorkSubmission.created_at.desc())
            .first()
        )
        cert = db.query(Certificate).filter(Certificate.student_id == student.id, Certificate.activity_id == activity_id).first() if hasattr(Certificate, "activity_id") else None
        result.append({
            "assignment_id": a.id,
            "student_id": student.id,
            "name": student.name,
            "email": student.email or "",
            "phone": student.phone,
            "location": student.location,
            "assignment_status": _assignment_status(a.status),
            "assigned_at": a.created_at.isoformat() if a.created_at else None,
            "work_status": latest_sub.status.value if latest_sub else None,
            "hours_worked": latest_sub.hours_worked if latest_sub else 0,
            "certificate_status": cert.status.value if cert else None,
        })
    return result


@router.post("/activities/{activity_id}/assign-students")
def assign_students_to_activity(
    activity_id: int,
    payload: dict,
    db: Session = Depends(get_db),
    user: User = Depends(_allow_em_or_admin),
):
    """Assign one or more students to an activity. payload: {student_ids: [int], notes: str}"""
    activity = db.query(VolunteerActivity).filter(VolunteerActivity.id == activity_id).first()
    if not activity:
        raise HTTPException(404, "Activity not found")
    if user.role == UserRole.event_manager and activity.created_by != user.id:
        raise HTTPException(403, "Access denied")

    student_ids = payload.get("student_ids", [])
    notes = payload.get("notes")
    created = []
    for sid in student_ids:
        existing = db.query(ActivityAssignment).filter(
            ActivityAssignment.activity_id == activity_id,
            ActivityAssignment.student_id == sid,
        ).first()
        if not existing:
            assignment = ActivityAssignment(
                student_id=sid,
                activity_id=activity_id,
                assigned_by=user.id,
                notes=notes,
                status="assigned",
            )
            db.add(assignment)
            created.append(sid)
    db.commit()
    return {"assigned": created, "already_assigned": len(student_ids) - len(created)}


@router.get("/activities/{activity_id}/work-logs")
def get_activity_work_logs(
    activity_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(_allow_em_or_admin),
):
    activity = db.query(VolunteerActivity).filter(VolunteerActivity.id == activity_id).first()
    if not activity:
        raise HTTPException(404, "Activity not found")
    if user.role == UserRole.event_manager and activity.created_by != user.id:
        raise HTTPException(403, "Access denied")

    submissions = db.query(WorkSubmission).filter(WorkSubmission.activity_id == activity_id).all()
    result = []
    for sub in submissions:
        student = db.query(User).filter(User.id == sub.student_id).first()
        logs = db.query(DailyLog).filter(DailyLog.submission_id == sub.id).all()
        result.append({
            "submission_id": sub.id,
            "student_id": sub.student_id,
            "student_name": student.name if student else "Unknown",
            "title": sub.title,
            "description": sub.description,
            "hours_worked": sub.hours_worked,
            "people_reached": sub.people_reached,
            "donation_collected": sub.donation_collected,
            "proof_files": json.loads(sub.proof_files or "[]"),
            "status": sub.status.value,
            "remarks": sub.remarks,
            "reviewer_notes": sub.reviewer_notes,
            "submitted_at": sub.created_at.isoformat() if sub.created_at else None,
            "reviewed_at": sub.reviewed_at.isoformat() if sub.reviewed_at else None,
            "daily_logs": [
                {
                    "id": log.id,
                    "date": log.date.isoformat() if log.date else None,
                    "title": log.title,
                    "content": log.content,
                    "reflection": log.reflection,
                    "media_files": json.loads(log.media_files or "[]"),
                    "status": log.status,
                }
                for log in logs
            ],
        })
    return result


# ── Admin Activity Management ─────────────────────────────────────────────────

def _admin_only(user: User = Depends(require_role(UserRole.admin, UserRole.super_admin))) -> User:
    return user


@router.get("/admin/all-activities")
def admin_all_activities(
    status: Optional[str] = Query(None),
    event_manager_id: Optional[int] = Query(None),
    category: Optional[str] = Query(None),
    db: Session = Depends(get_db),
    _: User = Depends(_admin_only),
):
    """Admin view: all activities across all Event Managers with filters."""
    q = db.query(VolunteerActivity)
    if status:
        q = q.filter(VolunteerActivity.status == status)
    if event_manager_id:
        q = q.filter(VolunteerActivity.created_by == event_manager_id)
    if category:
        q = q.filter(VolunteerActivity.category == category)
    activities = q.order_by(VolunteerActivity.created_at.desc()).all()
    return [_activity_list_item(a, db) for a in activities]


@router.get("/admin/activities-summary")
def admin_activities_summary(
    db: Session = Depends(get_db),
    _: User = Depends(_admin_only),
):
    """Admin analytics summary for activity management."""
    total = db.query(VolunteerActivity).count()
    active = db.query(VolunteerActivity).filter(VolunteerActivity.status == "active").count()
    completed = db.query(VolunteerActivity).filter(VolunteerActivity.status == "completed").count()
    draft = db.query(VolunteerActivity).filter(VolunteerActivity.status == "draft").count()
    cancelled = db.query(VolunteerActivity).filter(VolunteerActivity.status == "cancelled").count()

    total_assignments = db.query(ActivityAssignment).count()
    pending_approvals = db.query(ActivityAssignment).filter(
        ActivityAssignment.status.in_(["submitted", "event_manager_verified"])
    ).count()

    total_submissions = db.query(WorkSubmission).count()
    approved_submissions = db.query(WorkSubmission).filter(
        WorkSubmission.status == SubmissionStatus.approved
    ).count()

    return {
        "activities": {
            "total": total,
            "active": active,
            "completed": completed,
            "draft": draft,
            "cancelled": cancelled,
        },
        "assignments": {
            "total": total_assignments,
            "pending_approvals": pending_approvals,
        },
        "submissions": {
            "total": total_submissions,
            "approved": approved_submissions,
        },
    }
