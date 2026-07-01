import enum

from sqlalchemy import Boolean, Column, Date, DateTime, Enum as SAEnum, Integer, String, func
from sqlalchemy.orm import relationship

from ..database import Base


class UserRole(str, enum.Enum):
    super_admin     = "super_admin"
    admin           = "admin"
    event_manager   = "event_manager"
    mentor          = "mentor"
    content_creator = "content_creator"
    support_staff   = "support_staff"
    school_partner  = "school_partner"
    student         = "student"
    guest           = "guest"


class User(Base):
    __tablename__ = "users"

    id              = Column(Integer, primary_key=True, index=True)
    name            = Column(String, nullable=False)
    email           = Column(String, unique=True, nullable=True, index=True)
    hashed_password = Column(String, nullable=True)
    age             = Column(Integer, nullable=True)
    date_of_birth   = Column(Date, nullable=True)
    level           = Column(Integer, default=1)
    xp              = Column(Integer, default=0)
    role            = Column(SAEnum(UserRole), default=UserRole.student, nullable=False)
    access_status   = Column(String, default="pending", nullable=False)
    is_active       = Column(Boolean, default=True, nullable=False)
    parent_email    = Column(String, nullable=True)
    class_name      = Column(String, nullable=True)
    school_name     = Column(String, nullable=True)
    location        = Column(String, nullable=True)
    phone           = Column(String, nullable=True)
    requested_role      = Column(String, nullable=True)
    verification_note   = Column(String, nullable=True)
    reset_token         = Column(String, nullable=True)
    reset_token_expires = Column(DateTime, nullable=True)
    photo_url           = Column(String, nullable=True)
    interests           = Column(String, nullable=True)   # JSON array of interest strings
    created_at          = Column(DateTime, server_default=func.now())

    course_progress     = relationship("UserCourseProgress",  back_populates="user", cascade="all, delete-orphan")
    counselling_sessions= relationship("CounsellingSession",  foreign_keys="[CounsellingSession.user_id]", back_populates="user", cascade="all, delete-orphan")
    badges              = relationship("UserBadge",           back_populates="user", cascade="all, delete-orphan")

    @property
    def class_level(self) -> str | None:
        return self.class_name
