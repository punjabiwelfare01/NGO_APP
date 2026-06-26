from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from ..database import get_db
from ..dependencies import get_current_user
from ..models.platform import SchoolCounsellorRequest
from ..models.user import User, UserRole
from ..services import notification_service

router = APIRouter(prefix="/school", tags=["School Partner"])


def _school_json(item: SchoolCounsellorRequest, db: Session) -> dict:
    """Serialise a school counsellor request from the school partner's perspective.

    Contact details are visible once the counsellor has accepted.
    """
    reveal = item.status not in ("new_request", "declined", "cancelled")
    manager = (
        db.query(User).filter(User.id == item.assigned_event_manager_id).first()
        if item.assigned_event_manager_id
        else None
    )
    counsellor = db.query(User).filter(User.id == item.counsellor_id).first()
    preferred = item.preferred_at
    suggested = item.suggested_at
    return {
        "id": item.id,
        "counsellor_name": counsellor.name if counsellor else "TBD",
        "school_name": item.school_name,
        "coordinator_name": item.coordinator_name,
        "coordinator_phone": item.coordinator_phone if reveal else "",
        "coordinator_email": item.coordinator_email if reveal else "",
        "school_address": item.school_address or "",
        "program": item.program or "School counselling",
        "topic": item.topic,
        "class_group": item.class_group or "",
        "expected_students": item.expected_students,
        "language": item.language or "",
        "special_requirements": item.special_requirements or "",
        "preferred_date": preferred.date().isoformat(),
        "preferred_hour": preferred.hour,
        "preferred_minute": preferred.minute,
        "mode": item.mode,
        "offline_location": item.offline_location or "",
        "meeting_link": item.meeting_link if reveal else None,
        "assigned_event_manager": manager.name if manager else None,
        "assigned_event_manager_phone": manager.phone if manager and reveal else None,
        "preparation_notes": item.preparation_notes or "",
        "suggested_date": suggested.date().isoformat() if suggested else None,
        "suggested_hour": suggested.hour if suggested else None,
        "suggested_minute": suggested.minute if suggested else None,
        "status": item.status,
        "decline_reason": item.decline_reason,
        "decline_note": item.decline_note or "",
        "requested_at": item.created_at.isoformat(),
        "accepted_at": item.accepted_at.isoformat() if item.accepted_at else None,
        "confirmed_at": item.confirmed_at.isoformat() if item.confirmed_at else None,
        "completed_at": item.completed_at.isoformat() if item.completed_at else None,
    }


def _owned_request(db: Session, request_id: int, user: User) -> SchoolCounsellorRequest:
    item = (
        db.query(SchoolCounsellorRequest)
        .filter(
            SchoolCounsellorRequest.id == request_id,
            SchoolCounsellorRequest.requested_by == user.id,
        )
        .first()
    )
    if not item:
        raise HTTPException(status_code=404, detail="Request not found")
    return item


# ── Submit ─────────────────────────────────────────────────────────────────────

@router.post("/counsellor-requests", status_code=201,
             summary="Submit a school counselling request [authenticated]")
def create_request(
    payload: dict,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    counsellor_id = int(payload["counsellor_id"])
    preferred = datetime.fromisoformat(payload["preferred_at"])
    item = SchoolCounsellorRequest(
        counsellor_id=counsellor_id,
        requested_by=user.id,
        school_name=payload["school_name"],
        coordinator_name=payload["coordinator_name"],
        coordinator_phone=payload.get("coordinator_phone"),
        coordinator_email=payload.get("coordinator_email"),
        school_address=payload.get("school_address"),
        program=payload.get("program"),
        topic=payload["topic"],
        class_group=payload.get("class_group"),
        expected_students=payload.get("expected_students", 0),
        language=payload.get("language"),
        special_requirements=payload.get("special_requirements"),
        preferred_at=preferred,
        mode=payload.get("mode", "offline"),
        offline_location=payload.get("offline_location"),
    )
    db.add(item)
    db.flush()
    notification_service.notify(
        db, counsellor_id, "counselling_request",
        "New school counselling request",
        f"{item.school_name}: {item.topic}",
        entity_type="counselling_request", entity_id=item.id, commit=False,
    )
    for admin in db.query(User).filter(
        User.role.in_([UserRole.admin, UserRole.super_admin])
    ).all():
        notification_service.notify(
            db, admin.id, "counselling_request",
            "New school counselling request",
            f"{item.school_name} requested counselling: {item.topic}",
            entity_type="counselling_request", entity_id=item.id, commit=False,
        )
    db.commit()
    db.refresh(item)
    return _school_json(item, db)


# ── List & Detail ──────────────────────────────────────────────────────────────

@router.get("/my-requests",
            summary="List all my submitted counselling requests [authenticated]")
def my_requests(
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    items = (
        db.query(SchoolCounsellorRequest)
        .filter(SchoolCounsellorRequest.requested_by == user.id)
        .order_by(SchoolCounsellorRequest.created_at.desc())
        .all()
    )
    return [_school_json(item, db) for item in items]


@router.get("/my-requests/{request_id}",
            summary="Get detail for one of my submitted requests [authenticated]")
def my_request_detail(
    request_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    item = _owned_request(db, request_id, user)
    return _school_json(item, db)


# ── Actions ────────────────────────────────────────────────────────────────────

@router.patch("/my-requests/{request_id}/confirm-time",
              summary="Confirm a counsellor-suggested reschedule time [authenticated]")
def confirm_time(
    request_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    item = _owned_request(db, request_id, user)
    if item.status != "rescheduled":
        raise HTTPException(
            status_code=409,
            detail="Can only confirm time when status is 'rescheduled'",
        )
    if not item.suggested_at:
        raise HTTPException(status_code=409, detail="No suggested time to confirm")

    item.preferred_at = item.suggested_at
    item.suggested_at = None
    item.status = "pending_confirmation"
    notification_service.notify(
        db, item.counsellor_id, "counsellor_decision",
        "School confirmed new session time",
        f"{item.school_name} accepted the rescheduled time for '{item.topic}'.",
        entity_type="counselling_request", entity_id=item.id, commit=False,
    )
    db.commit()
    return _school_json(item, db)


@router.patch("/my-requests/{request_id}/cancel",
              summary="Cancel one of my submitted requests [authenticated]")
def cancel_request(
    request_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    item = _owned_request(db, request_id, user)
    if item.status in ("completed", "cancelled"):
        raise HTTPException(
            status_code=409,
            detail=f"Cannot cancel a request with status '{item.status}'",
        )
    item.status = "cancelled"
    notification_service.notify(
        db, item.counsellor_id, "counsellor_decision",
        "School cancelled counselling request",
        f"{item.school_name} cancelled the request for '{item.topic}'.",
        entity_type="counselling_request", entity_id=item.id, commit=False,
    )
    db.commit()
    return _school_json(item, db)
