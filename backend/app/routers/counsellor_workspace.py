import os
from datetime import datetime, timedelta

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile
from sqlalchemy.orm import Session

from ..database import get_db
from ..dependencies import get_current_user, require_role
from ..models.counselling import CounsellorWeeklyAvailability, MentorProfile
from ..models.platform import CounsellorSessionReport, ReminderJob, SchoolCounsellorRequest
from ..models.user import User, UserRole
from ..models.wellness import CounsellingAvailability
from ..services import notification_service
from ..services.hostinger_upload import upload_to_hostinger

_VERIFICATION_DOC_ALLOWED = {".pdf", ".jpg", ".jpeg", ".png"}

router = APIRouter(tags=["Counsellor Workspace"])


def _counsellor(user: User = Depends(get_current_user)) -> User:
    if user.active_role not in (UserRole.mentor, UserRole.admin, UserRole.super_admin): raise HTTPException(403, "Counsellor access required")
    return user


def _request_json(item: SchoolCounsellorRequest, db: Session, reveal: bool) -> dict:
    manager = db.query(User).filter(User.id == item.assigned_event_manager_id).first() if item.assigned_event_manager_id else None
    counsellor = db.query(User).filter(User.id == item.counsellor_id).first()
    preferred = item.preferred_at
    suggested = item.suggested_at
    return {"id": item.id, "counsellor_user_id": item.counsellor_id, "school_name": item.school_name, "coordinator_name": item.coordinator_name, "coordinator_phone": item.coordinator_phone if reveal else "", "coordinator_email": item.coordinator_email if reveal else "", "school_address": item.school_address or "", "program": item.program or "School counselling", "topic": item.topic, "class_group": item.class_group or "", "expected_students": item.expected_students, "language": item.language or "", "special_requirements": item.special_requirements or "", "preferred_date": preferred.date().isoformat(), "preferred_hour": preferred.hour, "preferred_minute": preferred.minute, "mode": item.mode, "offline_location": item.offline_location or "", "meeting_link": item.meeting_link if reveal else None, "counsellor_name": counsellor.name if counsellor else "TBD", "assigned_event_manager": manager.name if manager else None, "assigned_event_manager_phone": manager.phone if manager and reveal else None, "preparation_notes": item.preparation_notes or "", "suggested_date": suggested.date().isoformat() if suggested else None, "suggested_hour": suggested.hour if suggested else None, "suggested_minute": suggested.minute if suggested else None, "status": item.status, "decline_reason": item.decline_reason, "decline_note": item.decline_note or "", "requested_at": item.created_at.isoformat() if item.created_at else None, "accepted_at": item.accepted_at.isoformat() if item.accepted_at else None, "confirmed_at": item.confirmed_at.isoformat() if item.confirmed_at else None, "completed_at": item.completed_at.isoformat() if item.completed_at else None}



@router.get("/counsellor/requests")
def requests(db: Session = Depends(get_db), user: User = Depends(_counsellor)):
    query = db.query(SchoolCounsellorRequest)
    if user.active_role == UserRole.mentor: query = query.filter(SchoolCounsellorRequest.counsellor_id == user.id)
    return [_request_json(item, db, item.status not in ("new_request", "declined")) for item in query.order_by(SchoolCounsellorRequest.created_at.desc()).all()]


def _owned(db: Session, request_id: int, user: User):
    item = db.query(SchoolCounsellorRequest).filter(SchoolCounsellorRequest.id == request_id).first()
    if not item or (user.active_role == UserRole.mentor and item.counsellor_id != user.id): raise HTTPException(404, "Counselling request not found")
    return item


@router.post("/counsellor/requests/{request_id}/accept")
def accept(request_id: int, db: Session = Depends(get_db), user: User = Depends(_counsellor)):
    item = _owned(db, request_id, user); item.status = "accepted"; item.accepted_at = datetime.utcnow()
    for delta, kind in ((timedelta(hours=24), "24_hours"), (timedelta(hours=2), "2_hours"), (timedelta(minutes=15), "15_minutes")):
        db.add(ReminderJob(user_id=item.counsellor_id, notification_type="counselling_reminder", entity_type="counselling_request", entity_id=item.id, scheduled_at=item.preferred_at - delta))
    notification_service.notify(db, item.requested_by, "counsellor_decision", "Counsellor accepted", f"Your request for {item.topic} was accepted.", entity_type="counselling_request", entity_id=item.id, commit=False); db.commit(); return _request_json(item, db, True)


@router.post("/counsellor/requests/{request_id}/decline")
def decline(request_id: int, payload: dict, db: Session = Depends(get_db), user: User = Depends(_counsellor)):
    item = _owned(db, request_id, user); item.status = "declined"; item.decline_reason = payload.get("reason"); item.decline_note = payload.get("note"); notification_service.notify(db, item.requested_by, "counsellor_decision", "Counselling request declined", item.decline_note or "The counsellor is unavailable.", entity_type="counselling_request", entity_id=item.id, commit=False); db.commit(); return _request_json(item, db, False)


@router.post("/counsellor/requests/{request_id}/reschedule")
def reschedule(request_id: int, payload: dict, db: Session = Depends(get_db), user: User = Depends(_counsellor)):
    item = _owned(db, request_id, user); item.status = "rescheduled"; item.suggested_at = datetime.fromisoformat(payload["suggested_at"]); notification_service.notify(db, item.requested_by, "counsellor_decision", "New counselling time suggested", f"A new time was suggested for {item.topic}.", entity_type="counselling_request", entity_id=item.id, commit=False); db.commit(); return _request_json(item, db, False)


@router.get("/counsellor/sessions")
def sessions(db: Session = Depends(get_db), user: User = Depends(_counsellor)):
    query = db.query(SchoolCounsellorRequest).filter(SchoolCounsellorRequest.status.in_(["accepted", "confirmed", "scheduled", "completed"]))
    if user.active_role == UserRole.mentor: query = query.filter(SchoolCounsellorRequest.counsellor_id == user.id)
    return [_request_json(item, db, True) for item in query.order_by(SchoolCounsellorRequest.preferred_at).all()]


@router.get("/counsellor/sessions/{session_id}")
def session(session_id: int, db: Session = Depends(get_db), user: User = Depends(_counsellor)):
    return _request_json(_owned(db, session_id, user), db, True)


@router.post("/counsellor/sessions/{session_id}/complete")
def complete(session_id: int, db: Session = Depends(get_db), user: User = Depends(_counsellor)):
    item = _owned(db, session_id, user); item.status = "completed"; item.completed_at = datetime.utcnow(); db.commit(); return _request_json(item, db, True)


@router.post("/counsellor/sessions/{session_id}/report", status_code=201)
def report(session_id: int, payload: dict, db: Session = Depends(get_db), user: User = Depends(_counsellor)):
    item = _owned(db, session_id, user)
    if item.status != "completed": raise HTTPException(409, "Complete the session before submitting a report")
    existing = db.query(CounsellorSessionReport).filter(CounsellorSessionReport.request_id == item.id).first()
    if existing: raise HTTPException(409, "Session report already submitted")
    report = CounsellorSessionReport(request_id=item.id, counsellor_id=item.counsellor_id, counsellor_notes=payload["counsellor_notes"], students_count=payload.get("students_count", item.expected_students), school_feedback=payload.get("school_feedback"), rating=payload.get("rating")); db.add(report); db.commit(); db.refresh(report); return {"id": report.id, "request_id": report.request_id, "created_at": report.created_at}


@router.get("/counsellor/availability")
def availability(db: Session = Depends(get_db), user: User = Depends(_counsellor)):
    return db.query(CounsellingAvailability).filter(CounsellingAvailability.mentor_id == user.id).all()


@router.post("/counsellor/availability", status_code=201)
def create_availability(payload: dict, db: Session = Depends(get_db), user: User = Depends(_counsellor)):
    item = CounsellingAvailability(mentor_id=user.id, mentor_name=user.name, starts_at=datetime.fromisoformat(payload["starts_at"]), ends_at=datetime.fromisoformat(payload["ends_at"]), topic=payload.get("topic"), meeting_url=payload.get("meeting_url"), slot_duration_minutes=payload.get("slot_duration_minutes", 45), recurrence_type=payload.get("recurrence_type", "none")); db.add(item); db.commit(); db.refresh(item); return item


@router.patch("/counsellor/availability/{slot_id}")
def update_availability(slot_id: int, payload: dict, db: Session = Depends(get_db), user: User = Depends(_counsellor)):
    item = db.query(CounsellingAvailability).filter(CounsellingAvailability.id == slot_id, CounsellingAvailability.mentor_id == user.id).first()
    if not item: raise HTTPException(404, "Availability not found")
    for key, value in payload.items():
        if key in ("starts_at", "ends_at", "recurrence_end_date") and value: value = datetime.fromisoformat(value)
        if hasattr(item, key): setattr(item, key, value)
    db.commit(); db.refresh(item); return item


@router.delete("/counsellor/availability/{slot_id}", status_code=204)
def delete_availability(slot_id: int, db: Session = Depends(get_db), user: User = Depends(_counsellor)):
    item = db.query(CounsellingAvailability).filter(CounsellingAvailability.id == slot_id, CounsellingAvailability.mentor_id == user.id).first()
    if not item: raise HTTPException(404, "Availability not found")
    db.delete(item); db.commit()


# ── Weekly Availability ───────────────────────────────────────────────────────

def _slot_dict(slot: CounsellorWeeklyAvailability) -> dict:
    return {
        "id": slot.id,
        "counsellor_id": slot.counsellor_id,
        "day_of_week": slot.day_of_week,
        "start_time": slot.start_time,
        "end_time": slot.end_time,
        "session_duration_minutes": slot.session_duration_minutes,
        "max_sessions": slot.max_sessions,
        "mode": slot.mode,
        "location": slot.location,
        "online_link": slot.online_link,
        "is_active": slot.is_active,
        "created_at": slot.created_at.isoformat() if slot.created_at else None,
    }


@router.get("/counsellor/weekly-availability")
def get_weekly_availability(db: Session = Depends(get_db), user: User = Depends(_counsellor)):
    slots = db.query(CounsellorWeeklyAvailability).filter(
        CounsellorWeeklyAvailability.counsellor_id == user.id
    ).order_by(CounsellorWeeklyAvailability.day_of_week, CounsellorWeeklyAvailability.start_time).all()
    return [_slot_dict(s) for s in slots]


@router.post("/counsellor/weekly-availability", status_code=201)
def add_weekly_availability(payload: dict, db: Session = Depends(get_db), user: User = Depends(_counsellor)):
    slot = CounsellorWeeklyAvailability(
        counsellor_id=user.id,
        day_of_week=payload["day_of_week"],
        start_time=payload["start_time"],
        end_time=payload["end_time"],
        session_duration_minutes=payload.get("session_duration_minutes", 45),
        max_sessions=payload.get("max_sessions", 4),
        mode=payload.get("mode", "both"),
        location=payload.get("location"),
        online_link=payload.get("online_link"),
        is_active=payload.get("is_active", True),
    )
    db.add(slot)
    db.commit()
    db.refresh(slot)
    return _slot_dict(slot)


@router.patch("/counsellor/weekly-availability/{slot_id}")
def update_weekly_availability(slot_id: int, payload: dict, db: Session = Depends(get_db), user: User = Depends(_counsellor)):
    slot = db.query(CounsellorWeeklyAvailability).filter(
        CounsellorWeeklyAvailability.id == slot_id,
        CounsellorWeeklyAvailability.counsellor_id == user.id,
    ).first()
    if not slot:
        raise HTTPException(404, "Weekly availability slot not found")
    updatable = ["day_of_week", "start_time", "end_time", "session_duration_minutes",
                 "max_sessions", "mode", "location", "online_link", "is_active"]
    for field in updatable:
        if field in payload:
            setattr(slot, field, payload[field])
    db.commit()
    db.refresh(slot)
    return _slot_dict(slot)


@router.delete("/counsellor/weekly-availability/{slot_id}", status_code=204)
def delete_weekly_availability(slot_id: int, db: Session = Depends(get_db), user: User = Depends(_counsellor)):
    slot = db.query(CounsellorWeeklyAvailability).filter(
        CounsellorWeeklyAvailability.id == slot_id,
        CounsellorWeeklyAvailability.counsellor_id == user.id,
    ).first()
    if not slot:
        raise HTTPException(404, "Weekly availability slot not found")
    db.delete(slot)
    db.commit()


# ── Verification Document Upload ──────────────────────────────────────────────

@router.post("/counsellor/upload-verification-doc")
async def upload_verification_doc(
    doc_type: str = Form(...),   # "id_proof" or "professional_cert"
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    user: User = Depends(_counsellor),
):
    if doc_type not in ("id_proof", "professional_cert"):
        raise HTTPException(400, "doc_type must be 'id_proof' or 'professional_cert'")

    relative_url = await upload_to_hostinger(
        file, subdir="counsellor_docs", allowed_extensions=_VERIFICATION_DOC_ALLOWED,
    )

    mentor = db.query(MentorProfile).filter(MentorProfile.user_id == user.id).first()
    if not mentor:
        mentor = MentorProfile(user_id=user.id, display_name=user.name or "")
        db.add(mentor)

    if doc_type == "id_proof":
        mentor.id_proof_doc_url = relative_url
    else:
        mentor.professional_cert_url = relative_url

    db.commit()
    return {"url": relative_url, "doc_type": doc_type}
