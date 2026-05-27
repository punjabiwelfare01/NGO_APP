from datetime import datetime

from sqlalchemy.orm import Session

from ..models.course import Course, Lesson, SkillCategory, UserCourseProgress, UserLessonProgress
from ..schemas.course import LessonCreate, LessonResponse, LessonUpdate


def get_categories(db: Session) -> list[SkillCategory]:
    return db.query(SkillCategory).all()


def get_courses(db: Session, skip: int = 0, limit: int = 100) -> list[Course]:
    return db.query(Course).offset(skip).limit(limit).all()


def get_course(db: Session, course_id: int) -> Course | None:
    return db.query(Course).filter(Course.id == course_id).first()


def get_user_course_progress(db: Session, user_id: int) -> list[UserCourseProgress]:
    return (
        db.query(UserCourseProgress)
        .filter(UserCourseProgress.user_id == user_id)
        .all()
    )


def upsert_course_progress(
    db: Session, user_id: int, course_id: int, progress: float
) -> UserCourseProgress:
    record = (
        db.query(UserCourseProgress)
        .filter(
            UserCourseProgress.user_id == user_id,
            UserCourseProgress.course_id == course_id,
        )
        .first()
    )
    if record is None:
        record = UserCourseProgress(
            user_id=user_id,
            course_id=course_id,
            progress=progress,
            completed=progress >= 1.0,
        )
        db.add(record)
    else:
        record.progress = progress
        record.completed = progress >= 1.0
    db.commit()
    db.refresh(record)
    return record


# ── Lesson CRUD ────────────────────────────────────────────────────────────────

def _build_lesson_response(lesson: Lesson, completed: bool = False) -> LessonResponse:
    return LessonResponse(
        id=lesson.id,
        course_id=lesson.course_id,
        title=lesson.title,
        description=lesson.description,
        content_type=lesson.content_type,
        content_url=lesson.content_url,
        content_text=lesson.content_text,
        order=lesson.order,
        duration_minutes=lesson.duration_minutes,
        is_published=lesson.is_published,
        completed=completed,
    )


def get_lessons(db: Session, course_id: int, user_id: int | None = None) -> list[LessonResponse]:
    lessons = (
        db.query(Lesson)
        .filter(Lesson.course_id == course_id, Lesson.is_published == True)
        .order_by(Lesson.order)
        .all()
    )
    if not user_id:
        return [_build_lesson_response(l) for l in lessons]

    completed_ids = {
        row.lesson_id
        for row in db.query(UserLessonProgress).filter(
            UserLessonProgress.user_id == user_id,
            UserLessonProgress.completed == True,
        ).all()
    }
    return [_build_lesson_response(l, completed=l.id in completed_ids) for l in lessons]


def get_all_lessons_admin(db: Session, course_id: int) -> list[LessonResponse]:
    lessons = (
        db.query(Lesson)
        .filter(Lesson.course_id == course_id)
        .order_by(Lesson.order)
        .all()
    )
    return [_build_lesson_response(l) for l in lessons]


def create_lesson(db: Session, course_id: int, data: LessonCreate) -> Lesson:
    lesson = Lesson(course_id=course_id, **data.model_dump())
    db.add(lesson)
    db.commit()
    db.refresh(lesson)
    return lesson


def update_lesson(db: Session, lesson_id: int, data: LessonUpdate) -> Lesson | None:
    lesson = db.query(Lesson).filter(Lesson.id == lesson_id).first()
    if not lesson:
        return None
    for field, value in data.model_dump(exclude_none=True).items():
        setattr(lesson, field, value)
    db.commit()
    db.refresh(lesson)
    return lesson


def delete_lesson(db: Session, lesson_id: int) -> bool:
    lesson = db.query(Lesson).filter(Lesson.id == lesson_id).first()
    if not lesson:
        return False
    db.delete(lesson)
    db.commit()
    return True


def mark_lesson_complete(db: Session, user_id: int, lesson_id: int) -> None:
    record = (
        db.query(UserLessonProgress)
        .filter(
            UserLessonProgress.user_id == user_id,
            UserLessonProgress.lesson_id == lesson_id,
        )
        .first()
    )
    if record is None:
        record = UserLessonProgress(
            user_id=user_id,
            lesson_id=lesson_id,
            completed=True,
            completed_at=datetime.now(),
        )
        db.add(record)
    else:
        record.completed = True
        record.completed_at = datetime.now()
    db.commit()

    # Recompute course progress automatically
    lesson = db.query(Lesson).filter(Lesson.id == lesson_id).first()
    if lesson:
        _recompute_course_progress(db, user_id, lesson.course_id)


def _recompute_course_progress(db: Session, user_id: int, course_id: int) -> None:
    total = (
        db.query(Lesson)
        .filter(Lesson.course_id == course_id, Lesson.is_published == True)
        .count()
    )
    if total == 0:
        return
    completed_count = (
        db.query(UserLessonProgress)
        .join(Lesson, UserLessonProgress.lesson_id == Lesson.id)
        .filter(
            UserLessonProgress.user_id == user_id,
            UserLessonProgress.completed == True,
            Lesson.course_id == course_id,
            Lesson.is_published == True,
        )
        .count()
    )
    upsert_course_progress(db, user_id, course_id, completed_count / total)
