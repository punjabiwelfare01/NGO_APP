from sqlalchemy import Boolean, Column, DateTime, ForeignKey, Integer, String, func
from sqlalchemy.orm import relationship
from ..database import Base


class CounsellingAvailability(Base):
    __tablename__ = "counselling_availability"

    id = Column(Integer, primary_key=True, index=True)
    mentor_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    mentor_name = Column(String, nullable=False)
    starts_at = Column(DateTime, nullable=False)
    ends_at = Column(DateTime, nullable=False)
    topic = Column(String, nullable=True)
    capacity = Column(Integer, default=1, nullable=False)
    booked_count = Column(Integer, default=0, nullable=False)
    meeting_url = Column(String, nullable=True)
    is_active = Column(Boolean, default=True, nullable=False)
    slot_duration_minutes = Column(Integer, default=45, nullable=False)
    recurrence_type = Column(String, default="none", nullable=False)  # none | daily | weekly
    recurrence_end_date = Column(DateTime, nullable=True)
    created_at = Column(DateTime, server_default=func.now())

    mentor = relationship("User", foreign_keys=[mentor_id])

    @property
    def available_count(self) -> int:
        return max(0, self.capacity - self.booked_count)

    @property
    def is_available(self) -> bool:
        return self.is_active and self.available_count > 0


class CounsellingSession(Base):
    __tablename__ = "counselling_sessions"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    slot_id = Column(Integer, ForeignKey("counselling_availability.id"), nullable=True)
    mentor_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    counsellor_name = Column(String, nullable=False)
    topic = Column(String, nullable=False)
    scheduled_at = Column(DateTime, nullable=False)
    ends_at = Column(DateTime, nullable=True)
    # upcoming | completed | cancelled
    status = Column(String, default="upcoming", nullable=False)
    meeting_url = Column(String, nullable=True)
    notes = Column(String, nullable=True)
    created_at = Column(DateTime, server_default=func.now())

    user = relationship("User", foreign_keys=[user_id], back_populates="counselling_sessions")
    slot = relationship("CounsellingAvailability", foreign_keys=[slot_id])
    mentor = relationship("User", foreign_keys=[mentor_id])
