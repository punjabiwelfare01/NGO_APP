from datetime import datetime

from pydantic import BaseModel


class ChatMessageResponse(BaseModel):
    id: int
    mentor_id: int
    student_id: int
    sender_id: int
    sender_name: str
    sender_role: str
    content: str
    created_at: datetime

    model_config = {"from_attributes": True}


class ConversationSummary(BaseModel):
    other_user_id: int
    other_user_name: str
    other_user_role: str
    last_message: str
    last_message_at: datetime
    mentor_id: int
    student_id: int
