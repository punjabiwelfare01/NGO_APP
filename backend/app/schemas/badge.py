from datetime import datetime
from pydantic import BaseModel


class BadgeResponse(BaseModel):
    id: int
    icon_name: str
    label: str
    category: str

    model_config = {"from_attributes": True}


class UserBadgeResponse(BaseModel):
    id: int
    badge_id: int
    earned_at: datetime
    badge: BadgeResponse

    model_config = {"from_attributes": True}
