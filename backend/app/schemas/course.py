from datetime import datetime
from typing import Optional
from pydantic import BaseModel, field_validator


class CategoryResponse(BaseModel):
    id: int
    title: str
    icon_name: str
    color_hex: str

    model_config = {"from_attributes": True}


class CategoryCreate(BaseModel):
    title: str
    icon_name: str
    color_hex: str


class CategoryUpdate(BaseModel):
    title: Optional[str] = None
    icon_name: Optional[str] = None
    color_hex: Optional[str] = None


class CourseCreate(BaseModel):
    title: str
    duration: str
    level: str
    icon_name: str
    color_hex: str
    category_id: Optional[int] = None
    course_type: str = "skill"
    class_level: Optional[str] = None
    subject: Optional[str] = None
    skill_category: Optional[str] = None
    recommended_class_min: Optional[int] = None
    recommended_class_max: Optional[int] = None
    is_published: bool = True
    learn_items: Optional[list[str]] = None
    skill_tags: Optional[list[str]] = None
    course_description: Optional[str] = None
    offer_price: Optional[int] = None
    original_price: Optional[int] = None
    offer_label: Optional[str] = None


class CourseUpdate(BaseModel):
    title: Optional[str] = None
    duration: Optional[str] = None
    level: Optional[str] = None
    icon_name: Optional[str] = None
    color_hex: Optional[str] = None
    category_id: Optional[int] = None
    course_type: Optional[str] = None
    class_level: Optional[str] = None
    subject: Optional[str] = None
    skill_category: Optional[str] = None
    recommended_class_min: Optional[int] = None
    recommended_class_max: Optional[int] = None
    is_published: Optional[bool] = None
    learn_items: Optional[list[str]] = None
    skill_tags: Optional[list[str]] = None
    course_description: Optional[str] = None
    offer_price: Optional[int] = None
    original_price: Optional[int] = None
    offer_label: Optional[str] = None


class CourseResponse(BaseModel):
    id: int
    title: str
    duration: str
    level: str
    icon_name: str
    color_hex: str
    category_id: Optional[int]
    course_type: str = "skill"
    class_level: Optional[str] = None
    subject: Optional[str] = None
    skill_category: Optional[str] = None
    recommended_class_min: Optional[int] = None
    recommended_class_max: Optional[int] = None
    is_published: bool = True
    lesson_count: int = 0
    learn_items: Optional[list[str]] = None
    skill_tags: Optional[list[str]] = None
    course_description: Optional[str] = None
    offer_price: Optional[int] = None
    original_price: Optional[int] = None
    offer_label: Optional[str] = None

    model_config = {"from_attributes": True}


class LearningResourceDetailResponse(BaseModel):
    id: int
    name: str
    type: str
    url: Optional[str]
    size: Optional[str] = None


class LessonDetailResponse(BaseModel):
    id: int
    title: str
    description: Optional[str]
    content_type: str
    content: Optional[str]
    video_url: Optional[str]
    class_level: Optional[str] = None
    subject: Optional[str] = None
    duration_minutes: Optional[int]
    is_completed: bool = False
    is_published: bool = True
    resources: list[LearningResourceDetailResponse] = []


class CourseDetailResponse(BaseModel):
    id: int
    title: str
    description: str
    difficulty: str
    course_type: str = "skill"
    class_level: Optional[str] = None
    subject: Optional[str] = None
    skill_category: Optional[str] = None
    duration_minutes: Optional[int]
    duration: str
    progress: int
    preview_video_url: Optional[str]
    lessons: list[LessonDetailResponse] = []


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
    class_level: Optional[str] = None
    subject: Optional[str] = None
    chapter: Optional[str] = None
    order: int = 0
    duration_minutes: Optional[int] = None
    is_published: bool = True


class LessonUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    content_type: Optional[str] = None
    content_url: Optional[str] = None
    content_text: Optional[str] = None
    class_level: Optional[str] = None
    subject: Optional[str] = None
    chapter: Optional[str] = None
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
    class_level: Optional[str] = None
    subject: Optional[str] = None
    chapter: Optional[str] = None
    order: int
    duration_minutes: Optional[int]
    is_published: bool
    completed: bool = False   # injected per-user — not stored on Lesson model

    model_config = {"from_attributes": True}


# ── LearningResource schemas ────────────────────────────────────────────────────

RESOURCE_TYPES = {
    "video",
    "pdf",
    "pdf_notes",
    "image",
    "note",
    "link",
    "zip",
    "code_file",
}


class LearningResourceCreate(BaseModel):
    type: str
    title: str
    file_url: Optional[str] = None
    text_content: Optional[str] = None

    @field_validator("type")
    @classmethod
    def validate_type(cls, v: str) -> str:
        if v not in RESOURCE_TYPES:
            raise ValueError(f"type must be one of {sorted(RESOURCE_TYPES)}")
        return v


class LearningResourceUpdate(BaseModel):
    type: Optional[str] = None
    title: Optional[str] = None
    file_url: Optional[str] = None
    text_content: Optional[str] = None

    @field_validator("type")
    @classmethod
    def validate_type(cls, v: Optional[str]) -> Optional[str]:
        if v is not None and v not in RESOURCE_TYPES:
            raise ValueError(f"type must be one of {sorted(RESOURCE_TYPES)}")
        return v


class LearningResourceResponse(BaseModel):
    id: int
    lesson_id: int
    type: str
    title: str
    file_url: Optional[str]
    text_content: Optional[str]
    uploaded_by: Optional[int]
    created_at: datetime

    model_config = {"from_attributes": True}
