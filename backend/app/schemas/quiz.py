from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field, field_validator


class QuestionCreate(BaseModel):
    text:          str
    options:       list[str] = Field(min_length=2, max_length=6)
    correct_index: int = Field(ge=0)
    explanation:   Optional[str] = None
    points:        int = Field(default=10, ge=1)
    order_index:   int = Field(default=0, ge=0)

    @field_validator("correct_index")
    @classmethod
    def correct_index_must_match_options(cls, value: int, info):
        options = info.data.get("options") if info.data else None
        if options is not None and value >= len(options):
            raise ValueError("correct_index must point to one of the options")
        return value


class QuestionUpdate(BaseModel):
    text:          Optional[str] = None
    options:       Optional[list[str]] = Field(default=None, min_length=2, max_length=6)
    correct_index: Optional[int] = Field(default=None, ge=0)
    explanation:   Optional[str] = None
    points:        Optional[int] = Field(default=None, ge=1)
    order_index:   Optional[int] = Field(default=None, ge=0)


class QuestionResponse(BaseModel):
    id:            int
    text:          str
    options:       list[str]
    correct_index: int
    explanation:   Optional[str] = None
    points:        int
    order_index:   int

    model_config = {"from_attributes": True}


class QuizCreate(BaseModel):
    title:              str
    description:        Optional[str] = None
    category:           Optional[str] = None
    difficulty:         str = "medium"
    xp_reward:          int = Field(default=100, ge=0)
    time_limit_seconds: int = Field(default=300, ge=30)


class QuizUpdate(BaseModel):
    title:              Optional[str] = None
    description:        Optional[str] = None
    category:           Optional[str] = None
    difficulty:         Optional[str] = None
    xp_reward:          Optional[int] = Field(default=None, ge=0)
    time_limit_seconds: Optional[int] = Field(default=None, ge=30)
    is_active:          Optional[bool] = None


class QuizResponse(BaseModel):
    id:                 int
    title:              str
    description:        Optional[str] = None
    category:           Optional[str] = None
    difficulty:         str
    xp_reward:          int
    time_limit_seconds: int
    is_active:          bool
    question_count:     int = 0

    model_config = {"from_attributes": True}


class QuizWithQuestions(BaseModel):
    id:                 int
    title:              str
    description:        Optional[str] = None
    category:           Optional[str] = None
    difficulty:         str
    xp_reward:          int
    time_limit_seconds: int
    questions:          list[QuestionResponse]

    model_config = {"from_attributes": True}


class AttemptCreate(BaseModel):
    answers:             list[int]         # selected index per question (-1 = skipped)
    time_taken_seconds:  Optional[int] = Field(default=None, ge=0)


class AnswerResult(BaseModel):
    question_id:    int
    question_text:  str
    selected_index: int
    correct_index:  int
    is_correct:     bool
    explanation:    Optional[str] = None


class AttemptResponse(BaseModel):
    id:                 int
    quiz_id:            int
    score:              float
    correct_count:      int
    total_questions:    int
    xp_earned:          int
    time_taken_seconds: Optional[int] = None
    completed_at:       datetime
    answer_results:     list[AnswerResult]

    model_config = {"from_attributes": True}


class DailyChallengeResponse(BaseModel):
    challenge_date: str
    quiz:           QuizWithQuestions
    completed:      bool = False


class QuizLeaderboardEntry(BaseModel):
    rank:         int
    user_id:      int
    user_name:    str
    score:        float
    xp_earned:    int
    completed_at: datetime


class SetDailyChallengeRequest(BaseModel):
    quiz_id:        int
    challenge_date: str   # YYYY-MM-DD
