from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field


class ImpactMediaCreate(BaseModel):
    media_type: str = "image"
    url: str
    caption: Optional[str] = None
    position: int = 0


class ImpactMediaOut(ImpactMediaCreate):
    id: int
    model_config = {"from_attributes": True}


class ImpactPostCreate(BaseModel):
    category: str = "achievement"
    title: str
    description: str
    event_id: Optional[int] = None
    activity_id: Optional[int] = None
    certificate_id: Optional[int] = None
    student_names: Optional[str] = None
    team_name: Optional[str] = None
    location: Optional[str] = None
    partner_name: Optional[str] = None
    people_reached: int = Field(default=0, ge=0)
    donation_collected: float = Field(default=0, ge=0)
    hours_served: float = Field(default=0, ge=0)
    media: list[ImpactMediaCreate] = []


class ImpactPostUpdate(BaseModel):
    category: Optional[str] = None
    title: Optional[str] = None
    description: Optional[str] = None
    status: Optional[str] = None
    student_names: Optional[str] = None
    team_name: Optional[str] = None
    location: Optional[str] = None
    partner_name: Optional[str] = None
    people_reached: Optional[int] = Field(default=None, ge=0)
    donation_collected: Optional[float] = Field(default=None, ge=0)
    hours_served: Optional[float] = Field(default=None, ge=0)
    media: Optional[list[ImpactMediaCreate]] = None


class ImpactPostOut(BaseModel):
    id: int
    category: str
    title: str
    description: str
    status: str
    event_id: Optional[int]
    activity_id: Optional[int]
    certificate_id: Optional[int]
    student_names: Optional[str]
    team_name: Optional[str]
    location: Optional[str]
    partner_name: Optional[str]
    people_reached: int
    donation_collected: float
    hours_served: float
    appreciation_count: int
    share_count: int
    created_by: int
    approved_by: Optional[int]
    published_at: Optional[datetime]
    created_at: Optional[datetime]
    media: list[ImpactMediaOut] = []
    appreciated_by_me: bool = False
    public_url: Optional[str] = None

    model_config = {"from_attributes": True}


class ImpactMetricsOut(BaseModel):
    posts: int
    people_reached: int
    donation_collected: float
    hours_served: float
    appreciations: int
    shares: int


class ImpactShareOut(BaseModel):
    post_id: int
    public_url: str
    share_count: int
