from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from ..crud.emergency_crud import (
    create_contact,
    delete_contact,
    get_active_contacts,
    get_all_contacts,
    update_contact,
)
from ..database import get_db
from ..dependencies import admin_only, get_current_user
from ..models.user import User
from ..schemas.emergency import (
    EmergencyContactCreate,
    EmergencyContactResponse,
    EmergencyContactUpdate,
)

router = APIRouter(prefix="/emergency-contacts", tags=["Emergency Contacts"])


@router.get("", response_model=list[EmergencyContactResponse])
def list_contacts(
    db: Session = Depends(get_db),
    _: User = Depends(get_current_user),
):
    """All authenticated users can view active emergency contacts."""
    return get_active_contacts(db)


@router.get("/all", response_model=list[EmergencyContactResponse])
def list_all_contacts(
    db: Session = Depends(get_db),
    _: User = Depends(admin_only),
):
    """Admin only — returns all contacts including inactive ones."""
    return get_all_contacts(db)


@router.post("", response_model=EmergencyContactResponse, status_code=201)
def add_contact(
    payload: EmergencyContactCreate,
    db: Session = Depends(get_db),
    _: User = Depends(admin_only),
):
    return create_contact(db, payload)


@router.patch("/{contact_id}", response_model=EmergencyContactResponse)
def edit_contact(
    contact_id: int,
    payload: EmergencyContactUpdate,
    db: Session = Depends(get_db),
    _: User = Depends(admin_only),
):
    contact = update_contact(db, contact_id, payload)
    if not contact:
        raise HTTPException(status_code=404, detail="Contact not found")
    return contact


@router.delete("/{contact_id}", status_code=204)
def remove_contact(
    contact_id: int,
    db: Session = Depends(get_db),
    _: User = Depends(admin_only),
):
    if not delete_contact(db, contact_id):
        raise HTTPException(status_code=404, detail="Contact not found")
