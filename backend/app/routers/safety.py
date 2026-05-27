from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from ..crud import safety_crud
from ..database import get_db
from ..dependencies import get_current_user, require_role, content_creator_or_above
from ..models.user import User, UserRole
from ..schemas.safety import (
    AnswerResult,
    AnswerSubmit,
    SafetyQuestionCreate,
    SafetyQuestionPublic,
    SafetyQuestionResponse,
    SafetyQuestionUpdate,
)

router = APIRouter(prefix="/safety-awareness", tags=["Safety Awareness"])


# ── Student endpoints ──────────────────────────────────────────────────────────

@router.get(
    "/daily",
    response_model=SafetyQuestionPublic | None,
    summary="Get today's unanswered safety question [any authenticated user]",
)
def get_daily(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return safety_crud.get_daily_question(db, current_user.id)


@router.post(
    "/{question_id}/answer",
    response_model=AnswerResult,
    summary="Submit an answer [any authenticated user]",
)
def submit_answer(
    question_id: int,
    payload: AnswerSubmit,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = safety_crud.submit_answer(
        db, current_user.id, question_id, payload.chosen_option
    )
    if "error" in result:
        raise HTTPException(status_code=404, detail=result["error"])
    return result


@router.get(
    "/my-stats",
    summary="Get current user's answer stats",
)
def my_stats(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return safety_crud.get_user_stats(db, current_user.id)


# ── Admin endpoints ────────────────────────────────────────────────────────────

@router.get(
    "/",
    response_model=list[SafetyQuestionResponse],
    summary="List all questions [admin/content_creator]",
)
def list_questions(
    db: Session = Depends(get_db),
    _: User = Depends(content_creator_or_above),
):
    return safety_crud.get_all_questions(db)


@router.post(
    "/",
    response_model=SafetyQuestionResponse,
    status_code=201,
    summary="Create a question [admin/content_creator]",
)
def create_question(
    payload: SafetyQuestionCreate,
    db: Session = Depends(get_db),
    _: User = Depends(content_creator_or_above),
):
    return safety_crud.create_question(db, payload)


@router.patch(
    "/{question_id}",
    response_model=SafetyQuestionResponse,
    summary="Update a question [admin/content_creator]",
)
def update_question(
    question_id: int,
    payload: SafetyQuestionUpdate,
    db: Session = Depends(get_db),
    _: User = Depends(content_creator_or_above),
):
    q = safety_crud.update_question(db, question_id, payload)
    if not q:
        raise HTTPException(status_code=404, detail="Question not found")
    return q


@router.delete(
    "/{question_id}",
    status_code=204,
    summary="Delete a question [admin only]",
)
def delete_question(
    question_id: int,
    db: Session = Depends(get_db),
    _: User = Depends(require_role(UserRole.admin, UserRole.super_admin)),
):
    if not safety_crud.delete_question(db, question_id):
        raise HTTPException(status_code=404, detail="Question not found")
