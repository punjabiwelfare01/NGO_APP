from datetime import datetime
from typing import Optional
from pydantic import BaseModel, field_validator


class CategoryResponse(BaseModel):
    id: int
    title: str
    icon_name: str
    color_hex: str

    model_config = {"from_attributes": True}


class CourseResponse(BaseModel):
    id: int
    title: str
    duration: str
    level: str
    icon_name: str
    color_hex: str
    category_id: Optional[int]
    lesson_count: int = 0

    model_config = {"from_attributes": True}


class ProgressUpdate(BaseModel):
    progress: float  # 0.0 → 1.0

    @field_validator("progress")
    @classmethod
    def clamp(cls, v: float) -> float:
        return max(0.0, min(1.0, v))


class UserCourseProgressResponse(BaseModel):
    course_id: int
    progress: float
    completed: bool
    last_accessed: datetime
    course: CourseResponse

    model_config = {"from_attributes": True}


# ── Lesson schemas ─────────────────────────────────────────────────────────────

class LessonCreate(BaseModel):
    title: str
    description: Optional[str] = None
    content_type: str = "text"          # text | video
    content_url: Optional[str] = None
    content_text: Optional[str] = None
    order: int = 0
    duration_minutes: Optional[int] = None
    is_published: bool = True


class LessonUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    content_type: Optional[str] = None
    content_url: Optional[str] = None
    content_text: Optional[str] = None
    order: Optional[int] = None
    duration_minutes: Optional[int] = None
    is_published: Optional[bool] = None


class LessonResponse(BaseModel):
    id: int
    course_id: int
    title: str
    description: Optional[str]
    content_type: str
    content_url: Optional[str]
    content_text: Optional[str]
    order: int
    duration_minutes: Optional[int]
    is_published: bool
    completed: bool = False   # injected per-user — not stored on Lesson model

    model_config = {"from_attributes": True}
