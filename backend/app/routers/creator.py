from __future__ import annotations

from datetime import datetime
from typing import Any

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import or_
from sqlalchemy.orm import Session

from ..database import get_db
from ..dependencies import content_creator_or_above
from ..models.course import Course, Lesson
from ..models.event import Event, EventStatus
from ..models.quiz import Quiz, QuizAttempt
from ..models.user import User, UserRole

router = APIRouter(prefix="/creator", tags=["Creator Content"])


def _is_admin(user: User) -> bool:
    return user.role in (UserRole.admin, UserRole.super_admin)


def _can_access_event(event: Event, user: User) -> bool:
    return _is_admin(user) or event.created_by == user.id


def _event_status(status: EventStatus) -> str:
    if status in (EventStatus.published, EventStatus.registration_open, EventStatus.live):
        return "published"
    if status == EventStatus.pending_review:
        return "pending_review"
    if status == EventStatus.archived:
        return "archived"
    if status == EventStatus.completed:
        return "completed"
    return "draft"


def _dt(value: datetime | None) -> str | None:
    return value.isoformat() if value else None


def _course_item(course: Course) -> dict[str, Any]:
    progress_rows = list(course.user_progress or [])
    views = len(progress_rows)
    completion = (
        round(sum(row.progress for row in progress_rows) / views * 100)
        if views
        else 0
    )
    return {
        "id": course.id,
        "title": course.title,
        "type": "course",
        "status": "published",
        "views": views,
        "completion_rate": completion,
        "created_at": None,
        "updated_at": None,
        "category": course.category.title if course.category else None,
        "subtitle": f"{course.lesson_count} lessons added",
        "meta": {
            "level": course.level,
            "duration": course.duration,
            "lesson_count": course.lesson_count,
        },
    }


def _lesson_item(lesson: Lesson) -> dict[str, Any]:
    progress_rows = list(lesson.user_progress or [])
    views = len(progress_rows)
    completed = len([row for row in progress_rows if row.completed])
    completion = round(completed / views * 100) if views else 0
    return {
        "id": lesson.id,
        "title": lesson.title,
        "type": "lesson",
        "status": "published" if lesson.is_published else "draft",
        "views": views,
        "completion_rate": completion,
        "created_at": _dt(lesson.created_at),
        "updated_at": _dt(lesson.created_at),
        "category": lesson.course.category.title if lesson.course and lesson.course.category else None,
        "subtitle": lesson.content_type.title(),
        "meta": {
            "course_id": lesson.course_id,
            "course_title": lesson.course.title if lesson.course else None,
            "lesson_type": lesson.content_type,
            "duration_minutes": lesson.duration_minutes,
        },
    }


def _quiz_item(quiz: Quiz) -> dict[str, Any]:
    attempts = list(quiz.attempts or [])
    views = len(attempts)
    completion = round(sum(attempt.score for attempt in attempts) / views) if views else 0
    return {
        "id": quiz.id,
        "title": quiz.title,
        "type": "quiz",
        "status": "published" if quiz.is_active else "draft",
        "views": views,
        "completion_rate": completion,
        "created_at": _dt(quiz.created_at),
        "updated_at": _dt(quiz.created_at),
        "category": quiz.category,
        "subtitle": f"{quiz.question_count} questions",
        "meta": {
            "difficulty": quiz.difficulty.value,
            "xp_reward": quiz.xp_reward,
            "time_limit_seconds": quiz.time_limit_seconds,
        },
    }


def _event_item(event: Event) -> dict[str, Any]:
    return {
        "id": event.id,
        "title": event.title,
        "type": "event",
        "status": _event_status(event.status),
        "views": event.participant_count,
        "completion_rate": None,
        "created_at": _dt(event.created_at),
        "updated_at": _dt(event.updated_at),
        "category": event.event_type.value,
        "subtitle": event.subtitle or event.event_type.value.replace("_", " ").title(),
        "meta": {
            "event_type": event.event_type.value,
            "registration_start": _dt(event.registration_start),
            "registration_end": _dt(event.registration_end),
            "event_start": _dt(event.event_start),
            "event_end": _dt(event.event_end),
        },
    }


def _matches(item: dict[str, Any], status: str | None, type_: str | None, search: str | None) -> bool:
    if status and item["status"] != status:
        return False
    if type_ and item["type"] != type_:
        return False
    if search:
        needle = search.lower()
        haystack = f"{item['title']} {item.get('subtitle') or ''} {item.get('category') or ''}".lower()
        return needle in haystack
    return True


def _all_items(db: Session, user: User) -> list[dict[str, Any]]:
    event_query = db.query(Event)
    if not _is_admin(user):
        event_query = event_query.filter(Event.created_by == user.id)

    items = [
        *[_course_item(course) for course in db.query(Course).all()],
        *[_lesson_item(lesson) for lesson in db.query(Lesson).all()],
        *[
            _quiz_item(quiz)
            for quiz in db.query(Quiz).filter(or_(Quiz.created_by == user.id, Quiz.created_by.is_(None))).all()
        ],
        *[_event_item(event) for event in event_query.all()],
    ]
    items.sort(key=lambda item: item.get("updated_at") or item.get("created_at") or "", reverse=True)
    return items


@router.get("/content")
def list_creator_content(
    status: str | None = Query(default=None),
    type: str | None = Query(default=None),
    search: str | None = Query(default=None),
    db: Session = Depends(get_db),
    current_user: User = Depends(content_creator_or_above),
):
    normalized_status = status.lower() if status else None
    normalized_type = type.lower() if type else None
    items = [
        item
        for item in _all_items(db, current_user)
        if _matches(item, normalized_status, normalized_type, search)
    ]
    return {"items": items}


def _object_or_404(db: Session, user: User, type_: str, id_: int):
    if type_ == "course":
        obj = db.query(Course).filter(Course.id == id_).first()
    elif type_ == "lesson":
        obj = db.query(Lesson).filter(Lesson.id == id_).first()
    elif type_ == "quiz":
        obj = db.query(Quiz).filter(Quiz.id == id_).first()
        if obj and not _is_admin(user) and obj.created_by not in (user.id, None):
            raise HTTPException(status_code=403, detail="Access denied")
    elif type_ == "event":
        obj = db.query(Event).filter(Event.id == id_).first()
        if obj and not _can_access_event(obj, user):
            raise HTTPException(status_code=403, detail="Access denied")
    else:
        raise HTTPException(status_code=400, detail="Unsupported content type")
    if not obj:
        raise HTTPException(status_code=404, detail="Content not found")
    return obj


def _item_for_object(obj) -> dict[str, Any]:
    if isinstance(obj, Course):
        return _course_item(obj)
    if isinstance(obj, Lesson):
        return _lesson_item(obj)
    if isinstance(obj, Quiz):
        return _quiz_item(obj)
    return _event_item(obj)


@router.get("/content/{type}/{id}")
def get_creator_content(
    type: str,
    id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(content_creator_or_above),
):
    obj = _object_or_404(db, current_user, type.lower(), id)
    return _item_for_object(obj)


@router.patch("/content/{type}/{id}")
def update_creator_content(
    type: str,
    id: int,
    data: dict[str, Any],
    db: Session = Depends(get_db),
    current_user: User = Depends(content_creator_or_above),
):
    obj = _object_or_404(db, current_user, type.lower(), id)
    allowed_fields = {"title", "description", "subtitle", "course_description"}
    for field, value in data.items():
        if field in allowed_fields and hasattr(obj, field):
            setattr(obj, field, value)
    db.commit()
    db.refresh(obj)
    return _item_for_object(obj)


@router.delete("/content/{type}/{id}", status_code=204)
def delete_creator_content(
    type: str,
    id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(content_creator_or_above),
):
    obj = _object_or_404(db, current_user, type.lower(), id)
    db.delete(obj)
    db.commit()


@router.post("/content/{type}/{id}/submit-review")
def submit_creator_content_review(
    type: str,
    id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(content_creator_or_above),
):
    obj = _object_or_404(db, current_user, type.lower(), id)
    if isinstance(obj, Event):
        obj.status = EventStatus.pending_review
    elif isinstance(obj, Lesson):
        obj.is_published = False
    elif isinstance(obj, Quiz):
        obj.is_active = False
    db.commit()
    db.refresh(obj)
    return _item_for_object(obj)


@router.post("/content/{type}/{id}/publish")
def publish_creator_content(
    type: str,
    id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(content_creator_or_above),
):
    obj = _object_or_404(db, current_user, type.lower(), id)
    if isinstance(obj, Event):
        obj.status = EventStatus.published
    elif isinstance(obj, Lesson):
        obj.is_published = True
    elif isinstance(obj, Quiz):
        obj.is_active = True
    db.commit()
    db.refresh(obj)
    return _item_for_object(obj)


@router.post("/content/{type}/{id}/unpublish")
def unpublish_creator_content(
    type: str,
    id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(content_creator_or_above),
):
    obj = _object_or_404(db, current_user, type.lower(), id)
    if isinstance(obj, Event):
        obj.status = EventStatus.draft
    elif isinstance(obj, Lesson):
        obj.is_published = False
    elif isinstance(obj, Quiz):
        obj.is_active = False
    db.commit()
    db.refresh(obj)
    return _item_for_object(obj)
