from datetime import datetime
from typing import Optional

from pydantic import BaseModel


class EmergencyContactCreate(BaseModel):
    name: str
    phone: str
    description: Optional[str] = None
    is_active: bool = True


class EmergencyContactUpdate(BaseModel):
    name: Optional[str] = None
    phone: Optional[str] = None
    description: Optional[str] = None
    is_active: Optional[bool] = None


class EmergencyContactResponse(BaseModel):
    id: int
    name: str
    phone: str
    description: Optional[str]
    is_active: bool
    created_at: datetime

    model_config = {"from_attributes": True}
