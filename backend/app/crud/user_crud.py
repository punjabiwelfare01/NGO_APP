import json
from datetime import date, timedelta

from sqlalchemy.orm import Session

from ..config import settings
from ..models.course import UserCourseProgress, UserLessonProgress
from ..models.user import User
from ..schemas.user import UserCreate, UserUpdate


def get_user(db: Session, user_id: int) -> User | None:
    return db.query(User).filter(User.id == user_id).first()


def get_users(db: Session, skip: int = 0, limit: int = 100) -> list[User]:
    return db.query(User).offset(skip).limit(limit).all()


def create_user(db: Session, user: UserCreate) -> User:
    db_user = User(**user.model_dump())
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user


def update_user(db: Session, user_id: int, update: UserUpdate) -> User | None:
    user = get_user(db, user_id)
    if not user:
        return None
    for key, value in update.model_dump(exclude_unset=True).items():
        if key == "interests" and value is not None:
            setattr(user, key, json.dumps(value))
        else:
            setattr(user, key, value)
    db.commit()
    db.refresh(user)
    return user


def add_xp(db: Session, user_id: int, amount: int) -> User | None:
    user = get_user(db, user_id)
    if not user:
        return None
    user.xp = max(0, user.xp + amount)
    user.level = user.xp // settings.xp_per_level + 1
    db.commit()
    db.refresh(user)
    return user


def get_user_stats(db: Session, user_id: int) -> dict:
    user = get_user(db, user_id)
    if not user:
        return {}

    # Quiz rank — count users with more XP
    rank = db.query(User).filter(User.xp > user.xp).count() + 1

    # Total XP earned from completed game sessions as a proxy for skill growth
    total_possible_xp = db.query(User).order_by(User.xp.desc()).first()
    skill_growth = (
        round((user.xp / total_possible_xp.xp) * 100) if total_possible_xp and total_possible_xp.xp > 0 else 0
    )
    courses_enrolled = (
        db.query(UserCourseProgress)
        .filter(UserCourseProgress.user_id == user_id)
        .count()
    )
    lessons_completed = (
        db.query(UserLessonProgress)
        .filter(
            UserLessonProgress.user_id == user_id,
            UserLessonProgress.completed == True,
        )
        .count()
    )

    return {
        "user_id": user_id,
        "weekly_learning_hours": 6.5,   # placeholder — wire to real tracking later
        "skill_growth_percent": skill_growth,
        "quiz_rank": rank,
        "courses_enrolled": courses_enrolled,
        "lessons_completed": lessons_completed,
        "study_streak_days": _study_streak_days(db, user_id),
    }


def _study_streak_days(db: Session, user_id: int) -> int:
    rows = (
        db.query(UserLessonProgress.completed_at)
        .filter(
            UserLessonProgress.user_id == user_id,
            UserLessonProgress.completed == True,
            UserLessonProgress.completed_at.isnot(None),
        )
        .all()
    )
    completed_dates = {row[0].date() for row in rows if row[0] is not None}
    if not completed_dates:
        return 0

    cursor = date.today()
    if cursor not in completed_dates:
        cursor -= timedelta(days=1)

    streak = 0
    while cursor in completed_dates:
        streak += 1
        cursor -= timedelta(days=1)
    return streak
