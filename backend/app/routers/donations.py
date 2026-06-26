from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from ..crud import donation_crud
from ..database import get_db
from ..dependencies import get_current_user, require_role
from ..models.donation import DonationStatus
from ..models.user import User, UserRole
from ..schemas.donation import (
    DonationCreate, DonationOut, DonationReview,
    NGOPaymentDetailsOut, NGOPaymentDetailsUpdate,
    StipendConfigOut, StipendConfigUpdate,
    StipendRecordOut,
)

router = APIRouter(prefix="/donations", tags=["Donations"])


# ── NGO Payment Details (public read, admin write) ────────────────────────────

@router.get("/ngo-payment", response_model=Optional[NGOPaymentDetailsOut])
def get_ngo_payment(db: Session = Depends(get_db)):
    return donation_crud.get_ngo_payment_details(db)


@router.put("/ngo-payment", response_model=NGOPaymentDetailsOut)
def update_ngo_payment(
    data: NGOPaymentDetailsUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role(UserRole.admin, UserRole.super_admin)),
):
    return donation_crud.upsert_ngo_payment_details(db, data, current_user.id)


# ── Stipend Config (admin only) ───────────────────────────────────────────────

@router.get("/stipend-config", response_model=Optional[StipendConfigOut])
def get_stipend_config(
    db: Session = Depends(get_db),
    _: User = Depends(require_role(UserRole.admin, UserRole.super_admin)),
):
    return donation_crud.get_stipend_config(db)


@router.put("/stipend-config", response_model=StipendConfigOut)
def update_stipend_config(
    data: StipendConfigUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role(UserRole.admin, UserRole.super_admin)),
):
    return donation_crud.upsert_stipend_config(db, data, current_user.id)


# ── Donations ─────────────────────────────────────────────────────────────────

@router.post("", response_model=DonationOut)
def submit_donation(
    data: DonationCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return donation_crud.create_donation(db, data, referred_by=current_user.id)


@router.get("/me", response_model=List[DonationOut])
def my_donations(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return donation_crud.get_donations_by_student(db, current_user.id)


@router.get("", response_model=List[DonationOut])
def all_donations(
    status: Optional[DonationStatus] = None,
    db: Session = Depends(get_db),
    _: User = Depends(require_role(UserRole.admin, UserRole.super_admin)),
):
    return donation_crud.get_donations(db, status=status)


@router.patch("/{donation_id}/review", response_model=DonationOut)
def review_donation(
    donation_id: int,
    data: DonationReview,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role(UserRole.admin, UserRole.super_admin)),
):
    obj = donation_crud.review_donation(db, donation_id, data, current_user.id)
    if not obj:
        raise HTTPException(404, "Donation not found")
    return obj


# ── Stipend Records ───────────────────────────────────────────────────────────

@router.get("/stipends/me", response_model=List[StipendRecordOut])
def my_stipends(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return donation_crud.get_stipends_for_student(db, current_user.id)


@router.get("/stipends", response_model=List[StipendRecordOut])
def all_stipends(
    db: Session = Depends(get_db),
    _: User = Depends(require_role(UserRole.admin, UserRole.super_admin)),
):
    return donation_crud.get_all_stipends(db)


@router.patch("/stipends/{stipend_id}/approve", response_model=StipendRecordOut)
def approve_stipend(
    stipend_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role(UserRole.admin, UserRole.super_admin)),
):
    obj = donation_crud.approve_stipend(db, stipend_id, current_user.id)
    if not obj:
        raise HTTPException(404, "Stipend record not found")
    return obj


@router.patch("/stipends/{stipend_id}/pay", response_model=StipendRecordOut)
def mark_stipend_paid(
    stipend_id: int,
    db: Session = Depends(get_db),
    _: User = Depends(require_role(UserRole.admin, UserRole.super_admin)),
):
    obj = donation_crud.mark_stipend_paid(db, stipend_id)
    if not obj:
        raise HTTPException(404, "Stipend record not found")
    return obj
