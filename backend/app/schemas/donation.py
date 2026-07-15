from __future__ import annotations

from datetime import datetime
from typing import Optional

from pydantic import BaseModel

from ..models.donation import DonationType, DonationStatus


class DonationCreate(BaseModel):
    donor_name: Optional[str] = None
    donor_mobile: Optional[str] = None
    donor_email: Optional[str] = None
    donation_type: DonationType
    category: Optional[str] = None
    amount: float = 0.0
    items_desc: Optional[str] = None
    purpose: Optional[str] = None
    transaction_id: Optional[str] = None
    proof_file: Optional[str] = None


class DonationReview(BaseModel):
    status: DonationStatus
    receipt_number: Optional[str] = None


class DonationOut(BaseModel):
    id: int
    donor_name: Optional[str]
    donor_mobile: Optional[str]
    donor_email: Optional[str]
    donation_type: DonationType
    category: Optional[str]
    amount: float
    items_desc: Optional[str]
    purpose: Optional[str]
    transaction_id: Optional[str]
    proof_file: Optional[str]
    referred_by: Optional[int]
    referred_by_name: Optional[str] = None
    status: DonationStatus
    receipt_number: Optional[str]
    verified_by: Optional[int]
    verified_at: Optional[datetime]
    created_at: Optional[datetime]

    model_config = {"from_attributes": True}


class StipendConfigOut(BaseModel):
    id: int
    percentage: float
    min_donation_threshold: float
    updated_at: Optional[datetime]

    model_config = {"from_attributes": True}


class StipendConfigUpdate(BaseModel):
    percentage: float
    min_donation_threshold: float


class StipendRecordOut(BaseModel):
    id: int
    student_id: int
    donation_id: int
    percentage: float
    stipend_amount: float
    status: str
    approved_by: Optional[int]
    paid_at: Optional[datetime]
    created_at: Optional[datetime]

    model_config = {"from_attributes": True}


class NGOPaymentDetailsOut(BaseModel):
    id: int
    upi_id: Optional[str]
    qr_code_file: Optional[str]
    bank_name: Optional[str]
    account_number: Optional[str]
    ifsc_code: Optional[str]
    account_holder: Optional[str]

    model_config = {"from_attributes": True}


class NGOPaymentDetailsUpdate(BaseModel):
    upi_id: Optional[str] = None
    bank_name: Optional[str] = None
    account_number: Optional[str] = None
    ifsc_code: Optional[str] = None
    account_holder: Optional[str] = None
    qr_code_file: Optional[str] = None
