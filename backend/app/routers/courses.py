from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from ..crud import course_crud
from ..database import get_db
from ..dependencies import content_creator_or_above, get_current_user
from ..models.user import User, UserRole
from ..schemas.course import (
    CategoryResponse,
    CourseResponse,
    LessonCreate,
    LessonResponse,
    LessonUpdate,
    ProgressUpdate,
    UserCourseProgressResponse,
)

router = APIRouter(tags=["Courses"])


# ── categories & courses ───────────────────────────────────────────────────────

@router.get("/categories", response_model=list[CategoryResponse])
def list_categories(db: Session = Depends(get_db)):
    return course_crud.get_categories(db)


@router.get("/courses", response_model=list[CourseResponse])
def list_courses(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    return course_crud.get_courses(db, skip=skip, limit=limit)


@router.get("/courses/{course_id}", response_model=CourseResponse)
def get_course(course_id: int, db: Session = Depends(get_db)):
    course = course_crud.get_course(db, course_id)
    if not course:
        raise HTTPException(status_code=404, detail="Course not found")
    return course


# ── user course progress ───────────────────────────────────────────────────────

@router.get("/users/{user_id}/courses", response_model=list[UserCourseProgressResponse],
            summary="Get a user's course progress [self, mentor, admin]")
def get_user_courses(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if current_user.id != user_id and current_user.role not in (
        UserRole.mentor, UserRole.admin, UserRole.super_admin
    ):
        raise HTTPException(status_code=403, detail="Access denied")
    return course_crud.get_user_course_progress(db, user_id)


@router.put("/users/{user_id}/courses/{course_id}/progress",
            response_model=UserCourseProgressResponse,
            summary="Update course progress [self only]")
def update_progress(
    user_id: int,
    course_id: int,
    payload: ProgressUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if current_user.id != user_id and current_user.role not in (
        UserRole.admin, UserRole.super_admin
    ):
        raise HTTPException(status_code=403, detail="Access denied")
    course = course_crud.get_course(db, course_id)
    if not course:
        raise HTTPException(status_code=404, detail="Course not found")
    return course_crud.upsert_course_progress(db, user_id, course_id, payload.progress)


# ── lessons ────────────────────────────────────────────────────────────────────

@router.get("/courses/{course_id}/lessons", response_model=list[LessonResponse],
            summary="List lessons for a course [any authenticated]")
def list_lessons(
    course_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    course = course_crud.get_course(db, course_id)
    if not course:
        raise HTTPException(status_code=404, detail="Course not found")

    is_manager = current_user.role in (
        UserRole.admin, UserRole.super_admin, UserRole.mentor, UserRole.content_creator
    )
    if is_manager:
        return course_crud.get_all_lessons_admin(db, course_id)
    return course_crud.get_lessons(db, course_id, user_id=current_user.id)


@router.post("/courses/{course_id}/lessons", response_model=LessonResponse, status_code=201,
             summary="Create a lesson [content_creator, mentor, admin]")
def create_lesson(
    course_id: int,
    data: LessonCreate,
    db: Session = Depends(get_db),
    _: User = Depends(content_creator_or_above),
):
    course = course_crud.get_course(db, course_id)
    if not course:
        raise HTTPException(status_code=404, detail="Course not found")
    lesson = course_crud.create_lesson(db, course_id, data)
    from ..crud.course_crud import _build_lesson_response
    return _build_lesson_response(lesson)


@router.patch("/courses/{course_id}/lessons/{lesson_id}", response_model=LessonResponse,
              summary="Update a lesson [content_creator, mentor, admin]")
def update_lesson(
    course_id: int,
    lesson_id: int,
    data: LessonUpdate,
    db: Session = Depends(get_db),
    _: User = Depends(content_creator_or_above),
):
    lesson = course_crud.update_lesson(db, lesson_id, data)
    if not lesson or lesson.course_id != course_id:
        raise HTTPException(status_code=404, detail="Lesson not found")
    from ..crud.course_crud import _build_lesson_response
    return _build_lesson_response(lesson)


@router.delete("/courses/{course_id}/lessons/{lesson_id}", status_code=204,
               summary="Delete a lesson [content_creator, mentor, admin]")
def delete_lesson(
    course_id: int,
    lesson_id: int,
    db: Session = Depends(get_db),
    _: User = Depends(content_creator_or_above),
):
    deleted = course_crud.delete_lesson(db, lesson_id)
    if not deleted:
        raise HTTPException(status_code=404, detail="Lesson not found")


@router.post("/courses/{course_id}/lessons/{lesson_id}/complete", status_code=204,
             summary="Mark a lesson as complete [any authenticated student]")
def complete_lesson(
    course_id: int,
    lesson_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    course_crud.mark_lesson_complete(db, current_user.id, lesson_id)
