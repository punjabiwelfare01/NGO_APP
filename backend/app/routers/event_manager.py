import json
from datetime import date

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import and_, or_
from sqlalchemy.orm import Session

from ..database import get_db
from ..dependencies import require_role
from ..models.event import Event
from ..models.impact import ImpactPost
from ..models.user import User, UserRole
from ..models.volunteer import ActivityAssignment, VolunteerActivity, WorkSubmission
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
        impacts = (
            db.query(ImpactPost)
            .filter(ImpactPost.event_id.in_(event_ids))
            .order_by(ImpactPost.created_at.desc())
            .all()
            if event_ids else []
        )
    impact_payload = [
        {
            "id": item.id,
            "type": "eventSuccessReport",
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
