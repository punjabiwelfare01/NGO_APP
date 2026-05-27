from datetime import datetime
from typing import List, Optional

from pydantic import BaseModel

from ..models.event import EventStatus, EventType, SelectionMethod


class EventCreate(BaseModel):
    title: str
    subtitle: Optional[str] = None
    description: Optional[str] = None
    event_type: EventType = EventType.quiz
    quiz_id: Optional[int] = None
    quiz_title: Optional[str] = None
    is_daily_challenge: bool = False
    status: EventStatus = EventStatus.draft
    banner_url: Optional[str] = None
    thumbnail_url: Optional[str] = None
    theme_color: str = "#41A7F5"
    age_min: Optional[int] = None
    age_max: Optional[int] = None
    min_quiz_score: Optional[float] = None
    required_challenges: int = 0
    max_participants: Optional[int] = None
    selection_method: SelectionMethod = SelectionMethod.lucky_draw
    max_selections: Optional[int] = None
    counselling_enabled: bool = False
    certificate_enabled: bool = False
    scholarship_enabled: bool = False
    mentorship_enabled: bool = False
    auto_publish: bool = False
    auto_close: bool = False
    auto_result_publish: bool = False
    auto_notification: bool = True
    push_notification: bool = True
    in_app_notification: bool = True
    email_notification: bool = False
    registration_start: Optional[datetime] = None
    registration_end: Optional[datetime] = None
    event_start: Optional[datetime] = None
    event_end: Optional[datetime] = None
    start_date: Optional[datetime] = None
    end_date: Optional[datetime] = None
    result_date: Optional[datetime] = None
    counselling_date: Optional[datetime] = None


class EventUpdate(BaseModel):
    title: Optional[str] = None
    subtitle: Optional[str] = None
    description: Optional[str] = None
    event_type: Optional[EventType] = None
    quiz_id: Optional[int] = None
    quiz_title: Optional[str] = None
    is_daily_challenge: Optional[bool] = None
    status: Optional[EventStatus] = None
    banner_url: Optional[str] = None
    thumbnail_url: Optional[str] = None
    theme_color: Optional[str] = None
    age_min: Optional[int] = None
    age_max: Optional[int] = None
    min_quiz_score: Optional[float] = None
    required_challenges: Optional[int] = None
    max_participants: Optional[int] = None
    selection_method: Optional[SelectionMethod] = None
    max_selections: Optional[int] = None
    counselling_enabled: Optional[bool] = None
    certificate_enabled: Optional[bool] = None
    scholarship_enabled: Optional[bool] = None
    mentorship_enabled: Optional[bool] = None
    auto_publish: Optional[bool] = None
    auto_close: Optional[bool] = None
    auto_result_publish: Optional[bool] = None
    auto_notification: Optional[bool] = None
    push_notification: Optional[bool] = None
    in_app_notification: Optional[bool] = None
    email_notification: Optional[bool] = None
    registration_start: Optional[datetime] = None
    registration_end: Optional[datetime] = None
    event_start: Optional[datetime] = None
    event_end: Optional[datetime] = None
    start_date: Optional[datetime] = None
    end_date: Optional[datetime] = None
    result_date: Optional[datetime] = None
    counselling_date: Optional[datetime] = None


class EventResponse(BaseModel):
    id: int
    title: str
    subtitle: Optional[str] = None
    description: Optional[str] = None
    event_type: str
    quiz_id: Optional[int] = None
    is_daily_challenge: bool = False
    status: str
    created_by: int
    banner_url: Optional[str] = None
    thumbnail_url: Optional[str] = None
    theme_color: str
    age_min: Optional[int] = None
    age_max: Optional[int] = None
    min_quiz_score: Optional[float] = None
    required_challenges: int
    max_participants: Optional[int] = None
    selection_method: str
    max_selections: Optional[int] = None
    counselling_enabled: bool
    certificate_enabled: bool
    scholarship_enabled: bool
    mentorship_enabled: bool
    auto_publish: bool
    auto_close: bool
    auto_result_publish: bool
    auto_notification: bool
    push_notification: bool
    in_app_notification: bool
    email_notification: bool
    registration_start: Optional[datetime] = None
    registration_end: Optional[datetime] = None
    event_start: Optional[datetime] = None
    event_end: Optional[datetime] = None
    start_date: Optional[datetime] = None
    end_date: Optional[datetime] = None
    result_date: Optional[datetime] = None
    counselling_date: Optional[datetime] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    participant_count: int = 0

    model_config = {"from_attributes": True}


class EventParticipantResponse(BaseModel):
    id: int
    event_id: int
    user_id: int
    slot_id: Optional[int] = None
    score: float
    status: str
    registered_at: Optional[datetime] = None

    model_config = {"from_attributes": True}


class EventSelectionResponse(BaseModel):
    id: int
    event_id: int
    user_id: int
    selection_method: str
    counselling_assigned: bool
    selected_at: Optional[datetime] = None
    selection_note: Optional[str] = None

    model_config = {"from_attributes": True}


class AttachQuizRequest(BaseModel):
    quiz_title: str
    quiz_id: Optional[int] = None
    is_primary: bool = True


class RunSelectionRequest(BaseModel):
    user_ids: Optional[List[int]] = None
    max_count: Optional[int] = None


class LinkEventQuizRequest(BaseModel):
    event_id: int
    quiz_id: int


class EventSlotCreate(BaseModel):
    title: str
    starts_at: datetime
    ends_at: Optional[datetime] = None
    capacity: int = 1


class EventSlotResponse(BaseModel):
    id: int
    event_id: int
    title: str
    starts_at: datetime
    ends_at: Optional[datetime] = None
    capacity: int
    booked_count: int = 0
    available_count: int = 0

    model_config = {"from_attributes": True}


class BookSlotRequest(BaseModel):
    slot_id: Optional[int] = None
