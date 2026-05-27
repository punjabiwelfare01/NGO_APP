from sqlalchemy.orm import Session
from sqlalchemy import func

from ..models.safety import SafetyAwarenessQuestion, UserSafetyAnswer
from ..schemas.safety import SafetyQuestionCreate, SafetyQuestionUpdate


XP_REWARD = 5


# ── Admin CRUD ─────────────────────────────────────────────────────────────────

def get_all_questions(db: Session) -> list[SafetyAwarenessQuestion]:
    return (
        db.query(SafetyAwarenessQuestion)
        .order_by(SafetyAwarenessQuestion.created_at.desc())
        .all()
    )


def get_question(db: Session, question_id: int) -> SafetyAwarenessQuestion | None:
    return db.query(SafetyAwarenessQuestion).filter(
        SafetyAwarenessQuestion.id == question_id
    ).first()


def create_question(
    db: Session, payload: SafetyQuestionCreate
) -> SafetyAwarenessQuestion:
    q = SafetyAwarenessQuestion(**payload.model_dump())
    db.add(q)
    db.commit()
    db.refresh(q)
    return q


def update_question(
    db: Session, question_id: int, payload: SafetyQuestionUpdate
) -> SafetyAwarenessQuestion | None:
    q = get_question(db, question_id)
    if not q:
        return None
    for key, value in payload.model_dump(exclude_unset=True).items():
        setattr(q, key, value)
    db.commit()
    db.refresh(q)
    return q


def delete_question(db: Session, question_id: int) -> bool:
    q = get_question(db, question_id)
    if not q:
        return False
    db.delete(q)
    db.commit()
    return True


# ── Student facing ─────────────────────────────────────────────────────────────

def get_daily_question(
    db: Session, user_id: int
) -> SafetyAwarenessQuestion | None:
    """Return a random active question not yet answered by this user today."""
    from datetime import date, datetime, timezone
    today_start = datetime.combine(date.today(), datetime.min.time())

    answered_today = (
        db.query(UserSafetyAnswer.question_id)
        .filter(
            UserSafetyAnswer.user_id == user_id,
            UserSafetyAnswer.answered_at >= today_start,
        )
        .subquery()
    )

    q = (
        db.query(SafetyAwarenessQuestion)
        .filter(
            SafetyAwarenessQuestion.is_active.is_(True),
            SafetyAwarenessQuestion.id.notin_(answered_today),
        )
        .order_by(func.random())
        .first()
    )
    return q


def get_unanswered_question(
    db: Session, user_id: int
) -> SafetyAwarenessQuestion | None:
    """Return a random active question never answered by this user."""
    answered_ids = (
        db.query(UserSafetyAnswer.question_id)
        .filter(UserSafetyAnswer.user_id == user_id)
        .subquery()
    )
    return (
        db.query(SafetyAwarenessQuestion)
        .filter(
            SafetyAwarenessQuestion.is_active.is_(True),
            SafetyAwarenessQuestion.id.notin_(answered_ids),
        )
        .order_by(func.random())
        .first()
    )


def submit_answer(
    db: Session, user_id: int, question_id: int, chosen_option: str
) -> dict:
    q = get_question(db, question_id)
    if not q:
        return {"error": "Question not found"}

    is_correct = chosen_option == q.correct_option
    xp = XP_REWARD if is_correct else 0

    record = UserSafetyAnswer(
        user_id=user_id,
        question_id=question_id,
        chosen_option=chosen_option,
        is_correct=is_correct,
    )
    db.add(record)
    db.commit()

    return {
        "correct": is_correct,
        "correct_option": q.correct_option,
        "explanation": q.explanation,
        "xp_earned": xp,
    }


def get_user_stats(db: Session, user_id: int) -> dict:
    total = db.query(UserSafetyAnswer).filter(
        UserSafetyAnswer.user_id == user_id
    ).count()
    correct = db.query(UserSafetyAnswer).filter(
        UserSafetyAnswer.user_id == user_id,
        UserSafetyAnswer.is_correct.is_(True),
    ).count()
    return {"total_answered": total, "correct": correct}
