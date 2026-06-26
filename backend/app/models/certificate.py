import enum

from sqlalchemy import (
    Boolean, Column, Date, DateTime, Enum as SAEnum,
    ForeignKey, Integer, String, func,
)
from sqlalchemy.orm import relationship

from ..database import Base


class CertificateType(str, enum.Enum):
    volunteer              = "volunteer"
    internship             = "internship"
    donation_drive         = "donation_drive"
    event_organizer        = "event_organizer"
    appreciation           = "appreciation"
    school_awareness       = "school_awareness"
    event_participation    = "event_participation"
    counselling_support    = "counselling_support"
    course_completion      = "course_completion"
    social_work            = "social_work"
    event_manager          = "event_manager"
    donation_collection    = "donation_collection"


class CertificateStatus(str, enum.Enum):
    draft             = "draft"
    pending_signature = "pending_signature"
    issued            = "issued"
    revoked           = "revoked"
    approved          = "approved"
    rejected          = "rejected"
    generated         = "generated"
    # Backward-compatible values for existing records.
    pending           = "pending"
    signed            = "signed"


class Certificate(Base):
    __tablename__ = "certificates"

    id                = Column(Integer, primary_key=True, index=True)
    certificate_id    = Column(String, unique=True, nullable=False)   # NGO-CERT-2024-001
    student_id        = Column(Integer, ForeignKey("users.id"), nullable=False)
    event_id          = Column(Integer, ForeignKey("events.id"), nullable=True)
    activity_id       = Column(Integer, ForeignKey("volunteer_activities.id"), nullable=True)
    assignment_id     = Column(Integer, ForeignKey("activity_assignments.id"), nullable=True)
    submission_id     = Column(Integer, ForeignKey("work_submissions.id"), nullable=True)
    certificate_type  = Column(SAEnum(CertificateType), nullable=False)
    activity_name     = Column(String, nullable=False)
    duration          = Column(String, nullable=True)       # "3 months" / "10 hours"
    signatory_name    = Column(String, nullable=True)
    signatory_title   = Column(String, nullable=True)
    issue_date        = Column(Date, nullable=True)
    certificate_file  = Column(String, nullable=True)       # PDF path after manual signing
    status            = Column(SAEnum(CertificateStatus), default=CertificateStatus.draft)
    is_verified       = Column(Boolean, default=False)
    qr_token          = Column(String, nullable=True)       # Token for QR verification URL
    issued_by         = Column(Integer, ForeignKey("users.id"), nullable=True)
    revoked_by        = Column(Integer, ForeignKey("users.id"), nullable=True)
    revoked_at        = Column(DateTime, nullable=True)
    revoke_reason     = Column(String, nullable=True)
    rejection_reason  = Column(String, nullable=True)
    created_at        = Column(DateTime, server_default=func.now())

    student = relationship("User", foreign_keys=[student_id], lazy="joined")
