from datetime import datetime
from typing import Optional

from pydantic import BaseModel


class CalendarItemResponse(BaseModel):
    id: str
    source_id: int
    item_type: str
    title: str
    subtitle: Optional[str] = None
    starts_at: datetime
    ends_at: Optional[datetime] = None
    status: Optional[str] = None
    action_url: Optional[str] = None
    color_hex: Optional[str] = None
    is_done: bool = False


class ReminderCreate(BaseModel):
    title: str
    scheduled_at: datetime


class ReminderUpdate(BaseModel):
    title: Optional[str] = None
    scheduled_at: Optional[datetime] = None
    is_done: Optional[bool] = None
    is_active: Optional[bool] = None


class ReminderResponse(BaseModel):
    id: int
    user_id: int
    title: str
    scheduled_at: datetime
    is_done: bool
    is_active: bool
    created_at: datetime

    model_config = {"from_attributes": True}
