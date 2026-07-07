from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field


class MentorProfileCreate(BaseModel):
    display_name: str
    bio: Optional[str] = None
    expertise: Optional[str] = None
    category: Optional[str] = None
    profile_image_url: Optional[str] = None


class MentorProfileUpdate(BaseModel):
    display_name: Optional[str] = None
    bio: Optional[str] = None
    expertise: Optional[str] = None
    category: Optional[str] = None
    profile_image_url: Optional[str] = None
    is_active: Optional[bool] = None
    featured: Optional[bool] = None


class MentorProfileResponse(BaseModel):
    id: int
    user_id: int
    display_name: str
    bio: Optional[str] = None
    expertise: Optional[str] = None
    category: Optional[str] = None
    profile_image_url: Optional[str] = None
    is_active: bool
    featured: bool = False
    rating: float
    session_count: int
    created_at: Optional[datetime] = None

    model_config = {"from_attributes": True}


class CounsellingAnalyticsResponse(BaseModel):
    total_mentors: int
    active_mentors: int
    total_bookings: int
    upcoming_bookings: int
    completed_sessions: int
