from sqlalchemy.orm import Session

from ..models.wellness import CounsellingAvailability, CounsellingSession
from ..schemas.wellness import (
    CounsellingCreate,
    CounsellingSlotCreate,
    CounsellingSlotUpdate,
    CounsellingUpdate,
)


def get_user_counselling_sessions(db: Session, user_id: int) -> list[CounsellingSession]:
    return (
        db.query(CounsellingSession)
        .filter(CounsellingSession.user_id == user_id)
        .order_by(CounsellingSession.scheduled_at)
        .all()
    )


def get_mentor_sessions(db: Session, mentor_id: int) -> list[CounsellingSession]:
    return (
        db.query(CounsellingSession)
        .filter(CounsellingSession.mentor_id == mentor_id)
        .order_by(CounsellingSession.scheduled_at)
        .all()
    )


def create_counselling_session(
    db: Session, user_id: int, payload: CounsellingCreate
) -> CounsellingSession:
    session = CounsellingSession(user_id=user_id, **payload.model_dump())
    db.add(session)
    db.commit()
    db.refresh(session)
    return session


def list_available_slots(db: Session) -> list[CounsellingAvailability]:
    return (
        db.query(CounsellingAvailability)
        .filter(CounsellingAvailability.is_active.is_(True))
        .filter(CounsellingAvailability.booked_count < CounsellingAvailability.capacity)
        .order_by(CounsellingAvailability.starts_at)
        .all()
    )


def list_mentor_slots(db: Session, mentor_id: int) -> list[CounsellingAvailability]:
    return (
        db.query(CounsellingAvailability)
        .filter(CounsellingAvailability.mentor_id == mentor_id)
        .order_by(CounsellingAvailability.starts_at)
        .all()
    )


def get_availability_slot(db: Session, slot_id: int) -> CounsellingAvailability | None:
    return db.query(CounsellingAvailability).filter(CounsellingAvailability.id == slot_id).first()


def delete_availability_slot(db: Session, slot_id: int) -> bool:
    """Hard-delete if no bookings, otherwise soft-deactivate."""
    slot = db.query(CounsellingAvailability).filter(CounsellingAvailability.id == slot_id).first()
    if not slot:
        return False
    if slot.booked_count == 0:
        db.delete(slot)
    else:
        slot.is_active = False
    db.commit()
    return True


def create_availability_slot(
    db: Session,
    mentor_id: int,
    mentor_name: str,
    payload: CounsellingSlotCreate,
) -> CounsellingAvailability:
    slot = CounsellingAvailability(
        mentor_id=mentor_id,
        mentor_name=mentor_name,
        **payload.model_dump(),
    )
    db.add(slot)
    db.commit()
    db.refresh(slot)
    return slot


def update_availability_slot(
    db: Session,
    slot_id: int,
    payload: CounsellingSlotUpdate,
) -> CounsellingAvailability | None:
    slot = get_availability_slot(db, slot_id)
    if not slot:
        return None
    for key, value in payload.model_dump(exclude_unset=True).items():
        setattr(slot, key, value)
    db.commit()
    db.refresh(slot)
    return slot


def book_availability_slot(
    db: Session,
    user_id: int,
    slot_id: int,
    topic: str,
) -> CounsellingSession | None:
    slot = db.query(CounsellingAvailability).filter(CounsellingAvailability.id == slot_id).first()
    if not slot or not slot.is_available:
        return None
    session = CounsellingSession(
        user_id=user_id,
        slot_id=slot.id,
        mentor_id=slot.mentor_id,
        counsellor_name=slot.mentor_name,
        topic=topic or slot.topic or "Counselling session",
        scheduled_at=slot.starts_at,
        ends_at=slot.ends_at,
        meeting_url=slot.meeting_url,
    )
    slot.booked_count += 1
    db.add(session)
    db.commit()
    db.refresh(session)
    return session


def update_counselling_session(
    db: Session, session_id: int, update: CounsellingUpdate
) -> CounsellingSession | None:
    session = db.query(CounsellingSession).filter(CounsellingSession.id == session_id).first()
    if not session:
        return None
    for key, value in update.model_dump(exclude_unset=True).items():
        setattr(session, key, value)
    db.commit()
    db.refresh(session)
    return session
