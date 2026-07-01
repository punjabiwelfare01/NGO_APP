from sqlalchemy import Column, DateTime, ForeignKey, Integer, String, Text, func
from sqlalchemy.orm import relationship

from ..database import Base


class SchoolPartnerProfile(Base):
    __tablename__ = "school_partner_profiles"

    id                      = Column(Integer, primary_key=True, index=True)
    user_id                 = Column(Integer, ForeignKey("users.id"), unique=True, nullable=False)
    school_type             = Column(String, nullable=True)   # "Government", "Private", "Aided", "International"
    school_board            = Column(String, nullable=True)   # "CBSE", "ICSE", "State Board", "IB", "Other"
    registration_number     = Column(String, nullable=True)
    address                 = Column(Text, nullable=True)
    city                    = Column(String, nullable=True)
    state                   = Column(String, nullable=True)
    pin_code                = Column(String, nullable=True)
    coordinator_designation = Column(String, nullable=True)
    alternate_phone         = Column(String, nullable=True)
    created_at              = Column(DateTime, server_default=func.now())
    updated_at              = Column(DateTime, server_default=func.now(), onupdate=func.now())

    user = relationship("User", foreign_keys=[user_id])
