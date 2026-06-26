import enum

from sqlalchemy import (
    Boolean, Column, DateTime, Enum as SAEnum,
    Float, ForeignKey, Integer, String, func,
)

from ..database import Base


class DonationType(str, enum.Enum):
    money       = "money"
    things      = "things"
    service     = "service"
    sponsorship = "sponsorship"


class DonationStatus(str, enum.Enum):
    pending  = "pending"
    verified = "verified"
    approved = "approved"
    rejected = "rejected"


class Donation(Base):
    __tablename__ = "donations"

    id              = Column(Integer, primary_key=True, index=True)
    donor_name      = Column(String, nullable=True)
    donor_mobile    = Column(String, nullable=True)
    donor_email     = Column(String, nullable=True)
    donation_type   = Column(SAEnum(DonationType), nullable=False)
    category        = Column(String, nullable=True)      # Education, Medical, etc.
    amount          = Column(Float, default=0.0)
    items_desc      = Column(String, nullable=True)      # For things/service donations
    purpose         = Column(String, nullable=True)
    transaction_id  = Column(String, nullable=True)
    proof_file      = Column(String, nullable=True)
    referred_by     = Column(Integer, ForeignKey("users.id"), nullable=True)
    status          = Column(SAEnum(DonationStatus), default=DonationStatus.pending)
    receipt_number  = Column(String, nullable=True)
    verified_by     = Column(Integer, ForeignKey("users.id"), nullable=True)
    verified_at     = Column(DateTime, nullable=True)
    created_at      = Column(DateTime, server_default=func.now())


class StipendConfig(Base):
    __tablename__ = "stipend_config"

    id                     = Column(Integer, primary_key=True, index=True)
    percentage             = Column(Float, default=20.0, nullable=False)
    min_donation_threshold = Column(Float, default=1000.0, nullable=False)
    updated_by             = Column(Integer, ForeignKey("users.id"), nullable=True)
    updated_at             = Column(DateTime, server_default=func.now(), onupdate=func.now())


class StipendRecord(Base):
    __tablename__ = "stipend_records"

    id              = Column(Integer, primary_key=True, index=True)
    student_id      = Column(Integer, ForeignKey("users.id"), nullable=False)
    donation_id     = Column(Integer, ForeignKey("donations.id"), nullable=False)
    percentage      = Column(Float, nullable=False)
    stipend_amount  = Column(Float, nullable=False)
    status          = Column(String, default="pending", nullable=False)  # pending/approved/paid
    approved_by     = Column(Integer, ForeignKey("users.id"), nullable=True)
    paid_at         = Column(DateTime, nullable=True)
    created_at      = Column(DateTime, server_default=func.now())


class NGOPaymentDetails(Base):
    __tablename__ = "ngo_payment_details"

    id              = Column(Integer, primary_key=True, index=True)
    upi_id          = Column(String, nullable=True)
    qr_code_file    = Column(String, nullable=True)
    bank_name       = Column(String, nullable=True)
    account_number  = Column(String, nullable=True)
    ifsc_code       = Column(String, nullable=True)
    account_holder  = Column(String, nullable=True)
    is_active       = Column(Boolean, default=True, nullable=False)
    updated_by      = Column(Integer, ForeignKey("users.id"), nullable=True)
    updated_at      = Column(DateTime, server_default=func.now(), onupdate=func.now())
