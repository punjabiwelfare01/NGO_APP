from __future__ import annotations

from datetime import datetime
from typing import List, Optional

from sqlalchemy.orm import Session

from ..models.donation import (
    Donation, DonationStatus, NGOPaymentDetails,
    StipendConfig, StipendRecord,
)
from ..schemas.donation import (
    DonationCreate, DonationReview, NGOPaymentDetailsUpdate,
    StipendConfigUpdate,
)


# ── Donation ──────────────────────────────────────────────────────────────────

def create_donation(db: Session, data: DonationCreate, referred_by: Optional[int] = None) -> Donation:
    obj = Donation(**data.model_dump(), referred_by=referred_by)
    db.add(obj)
    db.commit()
    db.refresh(obj)
    return obj


def get_donations(db: Session, status: Optional[DonationStatus] = None) -> List[Donation]:
    q = db.query(Donation)
    if status:
        q = q.filter(Donation.status == status)
    return q.order_by(Donation.created_at.desc()).all()


def get_donations_by_student(db: Session, student_id: int) -> List[Donation]:
    return (
        db.query(Donation)
        .filter(Donation.referred_by == student_id)
        .order_by(Donation.created_at.desc())
        .all()
    )


def get_donation(db: Session, donation_id: int) -> Optional[Donation]:
    return db.query(Donation).filter(Donation.id == donation_id).first()


def review_donation(
    db: Session,
    donation_id: int,
    data: DonationReview,
    reviewer_id: int,
) -> Optional[Donation]:
    obj = get_donation(db, donation_id)
    if not obj:
        return None
    obj.status = data.status
    if data.receipt_number:
        obj.receipt_number = data.receipt_number
    obj.verified_by = reviewer_id
    obj.verified_at = datetime.utcnow()
    db.commit()
    db.refresh(obj)

    # Auto-create stipend record when donation is approved
    if data.status == DonationStatus.approved and obj.referred_by and obj.amount > 0:
        config = get_stipend_config(db)
        pct = config.percentage if config else 20.0
        threshold = config.min_donation_threshold if config else 1000.0
        if obj.amount >= threshold:
            stipend = StipendRecord(
                student_id=obj.referred_by,
                donation_id=obj.id,
                percentage=pct,
                stipend_amount=round(obj.amount * pct / 100, 2),
            )
            db.add(stipend)
            db.commit()

    return obj


# ── StipendConfig ─────────────────────────────────────────────────────────────

def get_stipend_config(db: Session) -> Optional[StipendConfig]:
    return db.query(StipendConfig).order_by(StipendConfig.id.desc()).first()


def upsert_stipend_config(
    db: Session, data: StipendConfigUpdate, admin_id: int
) -> StipendConfig:
    obj = db.query(StipendConfig).first()
    if obj:
        obj.percentage = data.percentage
        obj.min_donation_threshold = data.min_donation_threshold
        obj.updated_by = admin_id
    else:
        obj = StipendConfig(
            percentage=data.percentage,
            min_donation_threshold=data.min_donation_threshold,
            updated_by=admin_id,
        )
        db.add(obj)
    db.commit()
    db.refresh(obj)
    return obj


# ── StipendRecord ─────────────────────────────────────────────────────────────

def get_stipends_for_student(db: Session, student_id: int) -> List[StipendRecord]:
    return (
        db.query(StipendRecord)
        .filter(StipendRecord.student_id == student_id)
        .order_by(StipendRecord.created_at.desc())
        .all()
    )


def get_all_stipends(db: Session) -> List[StipendRecord]:
    return db.query(StipendRecord).order_by(StipendRecord.created_at.desc()).all()


def approve_stipend(db: Session, stipend_id: int, admin_id: int) -> Optional[StipendRecord]:
    obj = db.query(StipendRecord).filter(StipendRecord.id == stipend_id).first()
    if not obj:
        return None
    obj.status = "approved"
    obj.approved_by = admin_id
    db.commit()
    db.refresh(obj)
    return obj


def mark_stipend_paid(db: Session, stipend_id: int) -> Optional[StipendRecord]:
    obj = db.query(StipendRecord).filter(StipendRecord.id == stipend_id).first()
    if not obj:
        return None
    obj.status = "paid"
    obj.paid_at = datetime.utcnow()
    db.commit()
    db.refresh(obj)
    return obj


# ── NGOPaymentDetails ─────────────────────────────────────────────────────────

def get_ngo_payment_details(db: Session) -> Optional[NGOPaymentDetails]:
    return (
        db.query(NGOPaymentDetails)
        .filter(NGOPaymentDetails.is_active.is_(True))
        .first()
    )


def upsert_ngo_payment_details(
    db: Session, data: NGOPaymentDetailsUpdate, admin_id: int
) -> NGOPaymentDetails:
    obj = db.query(NGOPaymentDetails).filter(NGOPaymentDetails.is_active.is_(True)).first()
    if obj:
        for k, v in data.model_dump(exclude_none=True).items():
            setattr(obj, k, v)
        obj.updated_by = admin_id
    else:
        obj = NGOPaymentDetails(**data.model_dump(), updated_by=admin_id)
        db.add(obj)
    db.commit()
    db.refresh(obj)
    return obj
