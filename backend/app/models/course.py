from sqlalchemy import Boolean, Column, Float, Integer, JSON, String, ForeignKey, DateTime, Text, func
from sqlalchemy.orm import relationship
from ..database import Base


class SkillCategory(Base):
    __tablename__ = "skill_categories"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, nullable=False)
    icon_name = Column(String, nullable=False)
    color_hex = Column(String, nullable=False)

    courses = relationship("Course", back_populates="category")


class Course(Base):
    __tablename__ = "courses"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, nullable=False)
    duration = Column(String, nullable=False)
    level = Column(String, nullable=False)  # Beginner / Intermediate / Advanced
    icon_name = Column(String, nullable=False)
    color_hex = Column(String, nullable=False)
    category_id = Column(Integer, ForeignKey("skill_categories.id"), nullable=True)
    course_type = Column(String, nullable=False, default="skill")  # academic | skill
    class_level = Column(String, nullable=True)
    subject = Column(String, nullable=True)
    skill_category = Column(String, nullable=True)
    recommended_class_min = Column(Integer, nullable=True)
    recommended_class_max = Column(Integer, nullable=True)
    is_published = Column(Boolean, nullable=False, default=True)

    # Admin-editable sales/preview card fields
    learn_items = Column(JSON, nullable=True)       # list[str] | null
    skill_tags = Column(JSON, nullable=True)        # list[str] | null
    course_description = Column(Text, nullable=True)
    offer_price = Column(Integer, nullable=True)
    original_price = Column(Integer, nullable=True)
    offer_label = Column(String, nullable=True)

    category = relationship("SkillCategory", back_populates="courses")
    user_progress = relationship("UserCourseProgress", back_populates="course", cascade="all, delete-orphan")
    lessons = relationship("Lesson", back_populates="course", order_by="Lesson.order", cascade="all, delete-orphan")

    @property
    def lesson_count(self) -> int:
        return len(self.lessons)


class UserCourseProgress(Base):
    __tablename__ = "user_course_progress"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    course_id = Column(Integer, ForeignKey("courses.id"), nullable=False)
    progress = Column(Float, default=0.0)   # 0.0 → 1.0
    completed = Column(Boolean, default=False)
    last_accessed = Column(DateTime, server_default=func.now(), onupdate=func.now())

    user = relationship("User", back_populates="course_progress")
    course = relationship("Course", back_populates="user_progress")


class Lesson(Base):
    __tablename__ = "lessons"

    id = Column(Integer, primary_key=True, index=True)
    course_id = Column(Integer, ForeignKey("courses.id"), nullable=False)
    title = Column(String, nullable=False)
    description = Column(String, nullable=True)
    content_type = Column(String, nullable=False, default="text")  # text | video
    content_url = Column(String, nullable=True)   # used when content_type == 'video'
    content_text = Column(Text, nullable=True)    # used when content_type == 'text'
    class_level = Column(String, nullable=True)
    subject = Column(String, nullable=True)
    chapter = Column(String, nullable=True)
    order = Column(Integer, nullable=False, default=0)
    duration_minutes = Column(Integer, nullable=True)
    is_published = Column(Boolean, nullable=False, default=True)
    created_at = Column(DateTime, server_default=func.now())

    course = relationship("Course", back_populates="lessons")
    user_progress = relationship("UserLessonProgress", back_populates="lesson", cascade="all, delete-orphan")
    resources = relationship("LearningResource", back_populates="lesson", cascade="all, delete-orphan", order_by="LearningResource.id")


class UserLessonProgress(Base):
    __tablename__ = "user_lesson_progress"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    lesson_id = Column(Integer, ForeignKey("lessons.id"), nullable=False)
    completed = Column(Boolean, nullable=False, default=False)
    completed_at = Column(DateTime, nullable=True)

    lesson = relationship("Lesson", back_populates="user_progress")


class LearningResource(Base):
    __tablename__ = "learning_resources"

    id = Column(Integer, primary_key=True, index=True)
    lesson_id = Column(Integer, ForeignKey("lessons.id"), nullable=False)
    type = Column(String, nullable=False)          # video | pdf | image | note | link
    title = Column(String, nullable=False)
    file_url = Column(String, nullable=True)
    text_content = Column(Text, nullable=True)
    uploaded_by = Column(Integer, ForeignKey("users.id"), nullable=True)
    created_at = Column(DateTime, server_default=func.now())

    lesson = relationship("Lesson", back_populates="resources")
    uploader = relationship("User", foreign_keys=[uploaded_by])
