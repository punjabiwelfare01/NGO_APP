from sqlalchemy.orm import Session

from ..models.badge import Badge, UserBadge


def get_badges(db: Session) -> list[Badge]:
    return db.query(Badge).all()


def get_badge(db: Session, badge_id: int) -> Badge | None:
    return db.query(Badge).filter(Badge.id == badge_id).first()


def get_user_badges(db: Session, user_id: int) -> list[UserBadge]:
    return db.query(UserBadge).filter(UserBadge.user_id == user_id).all()


def award_badge(db: Session, user_id: int, badge_id: int) -> UserBadge:
    existing = (
        db.query(UserBadge)
        .filter(UserBadge.user_id == user_id, UserBadge.badge_id == badge_id)
        .first()
    )
    if existing:
        return existing
    record = UserBadge(user_id=user_id, badge_id=badge_id)
    db.add(record)
    db.commit()
    db.refresh(record)
    return record
