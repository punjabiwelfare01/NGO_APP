from datetime import datetime
from typing import Optional

from pydantic import BaseModel

from ..models.user import UserRole


class UserCreate(BaseModel):
    name: str
    age: int
    role: UserRole = UserRole.student
    parent_email: Optional[str] = None


class UserUpdate(BaseModel):
    name: Optional[str] = None
    age: Optional[int] = None
    parent_email: Optional[str] = None


class XPAdd(BaseModel):
    amount: int


class UserResponse(BaseModel):
    id: int
    name: str
    email: Optional[str] = None
    age: int
    level: int
    xp: int
    role: str = "student"
    is_active: bool = True
    parent_email: Optional[str]
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
