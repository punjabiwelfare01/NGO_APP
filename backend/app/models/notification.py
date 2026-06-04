from sqlalchemy import Boolean, Column, DateTime, ForeignKey, Integer, String, func

from ..database import Base


class AdminNotification(Base):
    __tablename__ = "admin_notifications"

    id         = Column(Integer, primary_key=True, index=True)
    title      = Column(String, nullable=False)
    message    = Column(String, nullable=False)
    type       = Column(String, default="general", nullable=False)
    is_read    = Column(Boolean, default=False, nullable=False)
    user_id    = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    action_url = Column(String, nullable=True)
    created_at = Column(DateTime, server_default=func.now())
