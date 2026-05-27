from sqlalchemy.orm import Session

from ..models.emergency import EmergencyContact
from ..schemas.emergency import EmergencyContactCreate, EmergencyContactUpdate


def get_all_contacts(db: Session) -> list[EmergencyContact]:
    return db.query(EmergencyContact).order_by(EmergencyContact.id).all()


def get_active_contacts(db: Session) -> list[EmergencyContact]:
    return (
        db.query(EmergencyContact)
        .filter(EmergencyContact.is_active.is_(True))
        .order_by(EmergencyContact.id)
        .all()
    )


def create_contact(db: Session, payload: EmergencyContactCreate) -> EmergencyContact:
    contact = EmergencyContact(**payload.model_dump())
    db.add(contact)
    db.commit()
    db.refresh(contact)
    return contact


def update_contact(
    db: Session, contact_id: int, payload: EmergencyContactUpdate
) -> EmergencyContact | None:
    contact = db.query(EmergencyContact).filter(EmergencyContact.id == contact_id).first()
    if not contact:
        return None
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(contact, field, value)
    db.commit()
    db.refresh(contact)
    return contact


def delete_contact(db: Session, contact_id: int) -> bool:
    contact = db.query(EmergencyContact).filter(EmergencyContact.id == contact_id).first()
    if not contact:
        return False
    db.delete(contact)
    db.commit()
    return True
