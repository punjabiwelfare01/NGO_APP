from datetime import datetime
from typing import Literal

from pydantic import BaseModel, field_validator


class SafetyQuestionBase(BaseModel):
    question_text: str
    option_a: str
    option_b: str
    option_c: str
    correct_option: Literal["a", "b", "c"]
    explanation: str
    category: str = "general"
    is_active: bool = True


class SafetyQuestionCreate(SafetyQuestionBase):
    pass


class SafetyQuestionUpdate(BaseModel):
    question_text: str | None = None
    option_a: str | None = None
    option_b: str | None = None
    option_c: str | None = None
    correct_option: Literal["a", "b", "c"] | None = None
    explanation: str | None = None
    category: str | None = None
    is_active: bool | None = None


class SafetyQuestionResponse(SafetyQuestionBase):
    id: int
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


# Student-facing response hides correct_option until answered
class SafetyQuestionPublic(BaseModel):
    id: int
    question_text: str
    option_a: str
    option_b: str
    option_c: str
    explanation: str
    category: str

    model_config = {"from_attributes": True}


class AnswerSubmit(BaseModel):
    chosen_option: Literal["a", "b", "c"]


class AnswerResult(BaseModel):
    correct: bool
    correct_option: Literal["a", "b", "c"]
    explanation: str
    xp_earned: int
