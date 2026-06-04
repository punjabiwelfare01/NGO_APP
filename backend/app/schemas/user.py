from datetime import datetime
from typing import Optional

from pydantic import BaseModel

from ..models.user import UserRole


class UserCreate(BaseModel):
    name: str
    age: Optional[int] = None
    role: UserRole = UserRole.student
    parent_email: Optional[str] = None


class UserUpdate(BaseModel):
    name: Optional[str] = None
    age: Optional[int] = None
    parent_email: Optional[str] = None


class UserRoleUpdate(BaseModel):
    role: UserRole


class UserStatusUpdate(BaseModel):
    is_active: bool


class XPAdd(BaseModel):
    amount: int


class UserResponse(BaseModel):
    id: int
    name: str
    email: Optional[str] = None
    age: Optional[int] = None
    level: int
    xp: int
    role: str = "student"
    access_status: str = "pending_verification"
    is_active: bool = True
    parent_email: Optional[str] = None
    class_name: Optional[str] = None
    school_name: Optional[str] = None
    location: Optional[str] = None
    phone: Optional[str] = None
    requested_role: Optional[str] = None
    verification_note: Optional[str] = None
    created_at: datetime

    model_config = {"from_attributes": True}


class UserStats(BaseModel):
    user_id: int
    weekly_learning_hours: float
    skill_growth_percent: int
    quiz_rank: int


class LeaderboardEntry(BaseModel):
    rank: int
    user_id: int
    name: str
    xp: int
    level: int
