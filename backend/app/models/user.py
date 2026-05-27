import enum

from sqlalchemy import Boolean, Column, DateTime, Enum as SAEnum, Integer, String, func
from sqlalchemy.orm import relationship

from ..database import Base


class UserRole(str, enum.Enum):
    super_admin     = "super_admin"
    admin           = "admin"
    mentor          = "mentor"
    content_creator = "content_creator"
    student         = "student"
    guest           = "guest"


class User(Base):
    __tablename__ = "users"

    id              = Column(Integer, primary_key=True, index=True)
    name            = Column(String, nullable=False)
    email           = Column(String, unique=True, nullable=True, index=True)
    hashed_password = Column(String, nullable=True)
    age             = Column(Integer, nullable=False)
    level           = Column(Integer, default=1)
    xp              = Column(Integer, default=0)
    role            = Column(SAEnum(UserRole), default=UserRole.student, nullable=False)
    is_active       = Column(Boolean, default=True, nullable=False)
    parent_email    = Column(String, nullable=True)
    created_at      = Column(DateTime, server_default=func.now())

    course_progress     = relationship("UserCourseProgress",  back_populates="user", cascade="all, delete-orphan")
    counselling_sessions= relationship("CounsellingSession",  foreign_keys="[CounsellingSession.user_id]", back_populates="user", cascade="all, delete-orphan")
    badges              = relationship("UserBadge",           back_populates="user", cascade="all, delete-orphan")
