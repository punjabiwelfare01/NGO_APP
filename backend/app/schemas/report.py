from datetime import datetime
from typing import Optional

from pydantic import BaseModel


class EventReportGenerate(BaseModel):
    summary: Optional[str] = None
    outcomes: Optional[str] = None
    school_feedback: Optional[str] = None
    impact_post_id: Optional[int] = None


class EventReportOut(BaseModel):
    id: int
    event_id: int
    status: str
    summary: Optional[str]
    outcomes: Optional[str]
    school_feedback: Optional[str]
    data_json: Optional[str]
    pdf_path: Optional[str]
    public_token: Optional[str]
    impact_post_id: Optional[int]
    created_by: int
    finalized_by: Optional[int]
    finalized_at: Optional[datetime]
    created_at: Optional[datetime]
    updated_at: Optional[datetime]
    model_config = {"from_attributes": True}


class EventReportShareOut(BaseModel):
    report_id: int
    public_url: str
