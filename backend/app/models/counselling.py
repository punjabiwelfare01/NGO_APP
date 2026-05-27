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

    user = relationship("User", foreign_keys=[user_id])


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
