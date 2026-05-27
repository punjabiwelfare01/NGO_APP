from sqlalchemy import Boolean, Column, DateTime, Integer, String, Text, func

from ..database import Base


class EmergencyContact(Base):
    __tablename__ = "emergency_contacts"

    id          = Column(Integer, primary_key=True, index=True)
    name        = Column(String, nullable=False)
    phone       = Column(String, nullable=False)
    description = Column(Text, nullable=True)
    is_active   = Column(Boolean, default=True, nullable=False)
    created_at  = Column(DateTime, server_default=func.now())
    updated_at  = Column(DateTime, server_default=func.now(), onupdate=func.now())
