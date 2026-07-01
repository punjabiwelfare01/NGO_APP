from sqlalchemy import Boolean, Column, DateTime, Float, ForeignKey, Integer, String, Text, func
from sqlalchemy.orm import relationship

from ..database import Base


class MentorProfile(Base):
    __tablename__ = "mentor_profiles"

    id                = Column(Integer, primary_key=True, index=True)
    user_id           = Column(Integer, ForeignKey("users.id"), unique=True, nullable=False)
    display_name      = Column(String, nullable=False)
    bio               = Column(Text, nullable=True)
    expertise         = Column(String, nullable=True)
    category          = Column(String, nullable=True)
    profile_image_url = Column(String, nullable=True)
    is_active         = Column(Boolean, default=True, nullable=False)
    rating            = Column(Float, default=0.0, nullable=False)
    session_count     = Column(Integer, default=0, nullable=False)
    google_calendar_id = Column(String, nullable=True)
    created_at        = Column(DateTime, server_default=func.now())

    # Extended profile fields
    gender                  = Column(String, nullable=True)
    date_of_birth           = Column(String, nullable=True)
    address                 = Column(Text, nullable=True)
    city                    = Column(String, nullable=True)
    state                   = Column(String, nullable=True)
    pin_code                = Column(String, nullable=True)
    qualification           = Column(String, nullable=True)
    years_of_experience     = Column(Integer, nullable=True)
    organization            = Column(String, nullable=True)
    counselling_mode        = Column(String, nullable=True)   # online / offline / both
    languages_known         = Column(String, nullable=True)   # comma-separated
    id_proof_type           = Column(String, nullable=True)
    id_proof_number         = Column(String, nullable=True)
    id_proof_doc_url        = Column(String, nullable=True)
    professional_cert_url   = Column(String, nullable=True)
    verification_status     = Column(String, default="pending", nullable=True)  # pending/verified/rejected/correction_required
    verified_by             = Column(String, nullable=True)
    verified_at             = Column(String, nullable=True)
    admin_remark            = Column(String, nullable=True)

    user = relationship("User", foreign_keys=[user_id])


class CounsellorWeeklyAvailability(Base):
    __tablename__ = "counsellor_weekly_availability"

    id                       = Column(Integer, primary_key=True, index=True)
    counsellor_id            = Column(Integer, ForeignKey("users.id"), nullable=False)
    day_of_week              = Column(Integer, nullable=False)   # 0=Monday … 6=Sunday
    start_time               = Column(String, nullable=False)    # "HH:MM"
    end_time                 = Column(String, nullable=False)    # "HH:MM"
    session_duration_minutes = Column(Integer, default=45, nullable=False)
    max_sessions             = Column(Integer, default=4, nullable=False)
    mode                     = Column(String, default="both", nullable=False)
    location                 = Column(String, nullable=True)
    online_link              = Column(String, nullable=True)
    is_active                = Column(Boolean, default=True, nullable=False)
    created_at               = Column(DateTime, server_default=func.now())

    counsellor = relationship("User", foreign_keys=[counsellor_id])


class CounsellingNotification(Base):
    __tablename__ = "counselling_notifications"

    id          = Column(Integer, primary_key=True, index=True)
    user_id     = Column(Integer, ForeignKey("users.id"), nullable=False)
    type        = Column(String, nullable=False)   # confirmation | reminder | cancellation
    message     = Column(Text, nullable=False)
    booking_ref = Column(String, nullable=True)
    is_read     = Column(Boolean, default=False, nullable=False)
    created_at  = Column(DateTime, server_default=func.now())

    user = relationship("User", foreign_keys=[user_id])
