import json
from datetime import date, datetime
from typing import List, Optional

from pydantic import BaseModel, field_validator

from ..models.user import UserRole


class UserCreate(BaseModel):
    name: str
    age: Optional[int] = None
    date_of_birth: Optional[date] = None
    role: UserRole = UserRole.student
    parent_email: Optional[str] = None
    class_name: Optional[str] = None
    school_name: Optional[str] = None
    location: Optional[str] = None
    phone: Optional[str] = None


class UserUpdate(BaseModel):
    name: Optional[str] = None
    age: Optional[int] = None
    date_of_birth: Optional[date] = None
    parent_email: Optional[str] = None
    class_name: Optional[str] = None
    school_name: Optional[str] = None
    location: Optional[str] = None
    phone: Optional[str] = None
    interests: Optional[List[str]] = None


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
    date_of_birth: Optional[date] = None
    level: int
    xp: int
    role: str = "student"
    access_status: str = "pending"
    is_active: bool = True
    parent_email: Optional[str] = None
    class_level: Optional[str] = None
    class_name: Optional[str] = None
    school_name: Optional[str] = None
    location: Optional[str] = None
    phone: Optional[str] = None
    requested_role: Optional[str] = None
    verification_note: Optional[str] = None
    gov_id_type: Optional[str] = None
    gov_id_doc_url: Optional[str] = None
    photo_url: Optional[str] = None
    created_at: datetime
    interests: Optional[List[str]] = None

    @field_validator("interests", mode="before")
    @classmethod
    def parse_interests(cls, v):
        if isinstance(v, str):
            try:
                return json.loads(v)
            except (json.JSONDecodeError, ValueError):
                return []
        return v

    model_config = {"from_attributes": True}


class UserStats(BaseModel):
    user_id: int
    weekly_learning_hours: float
    skill_growth_percent: int
    quiz_rank: int
    courses_enrolled: int = 0
    lessons_completed: int = 0
    study_streak_days: int = 0


class LeaderboardEntry(BaseModel):
    rank: int
    user_id: int
    name: str
    xp: int
    level: int
