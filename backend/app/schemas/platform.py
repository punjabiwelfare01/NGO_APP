from datetime import datetime
from typing import Any, Optional

from pydantic import BaseModel


class NotificationOut(BaseModel):
    id: int
    type: str
    title: str
    message: str
    action_url: Optional[str]
    entity_type: Optional[str]
    entity_id: Optional[int]
    is_read: bool
    read_at: Optional[datetime]
    created_at: Optional[datetime]
    model_config = {"from_attributes": True}


class UserSettingsOut(BaseModel):
    language: str = "en"
    profile_visibility: str = "ngo_members"
    show_impact_name: bool = True
    data_download_enabled: bool = True
    in_app_enabled: bool = True
    email_enabled: bool = True
    event_reminders: bool = True
    counselling_reminders: bool = True
    assignment_updates: bool = True
    impact_updates: bool = True


class UserSettingsUpdate(BaseModel):
    language: Optional[str] = None
    profile_visibility: Optional[str] = None
    show_impact_name: Optional[bool] = None
    data_download_enabled: Optional[bool] = None
    in_app_enabled: Optional[bool] = None
    email_enabled: Optional[bool] = None
    event_reminders: Optional[bool] = None
    counselling_reminders: Optional[bool] = None
    assignment_updates: Optional[bool] = None
    impact_updates: Optional[bool] = None


class ProfileReportOut(BaseModel):
    id: str
    type: str
    title: str
    status: str
    summary: str
    created_at: Optional[datetime] = None
    details: dict[str, Any] = {}


class NGOProfileData(BaseModel):
    name: str = "Punjabi Welfare Trust"
    registration_number: Optional[str] = None
    email: Optional[str] = None
    phone: Optional[str] = None
    address: Optional[str] = None
    website: Optional[str] = None
    logo_url: Optional[str] = None
    model_config = {"from_attributes": True}


class BankData(BaseModel):
    account_holder: Optional[str] = None
    bank_name: Optional[str] = None
    account_number: Optional[str] = None
    ifsc_code: Optional[str] = None
    upi_id: Optional[str] = None
    qr_url: Optional[str] = None
    confirmation: Optional[str] = None
    model_config = {"from_attributes": True}


class PermissionData(BaseModel):
    permissions: list[str]


class AppSettingsData(BaseModel):
    values: dict[str, Any]


class AnnouncementCreate(BaseModel):
    title: str
    message: str
    audience_role: Optional[str] = None
    is_active: bool = True
    publish_at: Optional[datetime] = None
    expires_at: Optional[datetime] = None


class AnnouncementUpdate(BaseModel):
    title: Optional[str] = None
    message: Optional[str] = None
    audience_role: Optional[str] = None
    is_active: Optional[bool] = None
    publish_at: Optional[datetime] = None
    expires_at: Optional[datetime] = None


class AnnouncementOut(AnnouncementCreate):
    id: int
    created_by: int
    created_at: Optional[datetime]
    model_config = {"from_attributes": True}


class AuditLogOut(BaseModel):
    id: int
    actor_id: int
    action: str
    entity_type: Optional[str]
    entity_id: Optional[str]
    details_json: Optional[str]
    ip_address: Optional[str]
    created_at: Optional[datetime]
    model_config = {"from_attributes": True}
