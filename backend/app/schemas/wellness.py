from datetime import datetime
from enum import Enum
from typing import Optional
from pydantic import BaseModel, Field


class SessionStatus(str, Enum):
    upcoming = "upcoming"
    completed = "completed"
    cancelled = "cancelled"


class CounsellingCreate(BaseModel):
    counsellor_name: str
    topic: str
    scheduled_at: datetime
    ends_at: Optional[datetime] = None
    meeting_url: Optional[str] = None
    slot_id: Optional[int] = None
    mentor_id: Optional[int] = None


class CounsellingSlotCreate(BaseModel):
    starts_at: datetime
    ends_at: datetime
    topic: Optional[str] = None
    capacity: int = Field(default=1, ge=1)
    meeting_url: Optional[str] = None


class CounsellingSlotUpdate(BaseModel):
    starts_at: Optional[datetime] = None
    ends_at: Optional[datetime] = None
    topic: Optional[str] = None
    capacity: Optional[int] = Field(default=None, ge=1)
    meeting_url: Optional[str] = None
    is_active: Optional[bool] = None


class CounsellingSlotBook(BaseModel):
    topic: str


class CounsellingUpdate(BaseModel):
    status: Optional[SessionStatus] = None
    notes: Optional[str] = None
    meeting_url: Optional[str] = None


class CounsellingResponse(BaseModel):
    id: int
    slot_id: Optional[int] = None
    mentor_id: Optional[int] = None
    counsellor_name: str
    topic: str
    scheduled_at: datetime
    ends_at: Optional[datetime] = None
    status: str
    meeting_url: Optional[str] = None
    notes: Optional[str]
    created_at: datetime

    model_config = {"from_attributes": True}


class CounsellingSlotResponse(BaseModel):
    id: int
    mentor_id: int
    mentor_name: str
    starts_at: datetime
    ends_at: datetime
    topic: Optional[str] = None
    capacity: int
    booked_count: int
    available_count: int
    meeting_url: Optional[str] = None
    is_active: bool
    is_available: bool
    created_at: datetime

    model_config = {"from_attributes": True}
