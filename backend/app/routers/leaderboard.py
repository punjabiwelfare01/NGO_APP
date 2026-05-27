from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from ..database import get_db
from ..models.user import User
from ..schemas.user import LeaderboardEntry

router = APIRouter(prefix="/leaderboard", tags=["Leaderboard"])


# Leaderboard is intentionally public — discovering top players drives engagement.

@router.get("/", response_model=list[LeaderboardEntry],
            summary="Top learners by XP [public]")
def get_leaderboard(limit: int = 10, db: Session = Depends(get_db)):
    users = db.query(User).order_by(User.xp.desc()).limit(limit).all()
    return [
        LeaderboardEntry(rank=idx + 1, user_id=u.id, name=u.name, xp=u.xp, level=u.level)
        for idx, u in enumerate(users)
    ]


@router.get("/{user_id}/rank", response_model=LeaderboardEntry,
            summary="Get a specific user's rank [public]")
def get_user_rank(user_id: int, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    rank = db.query(User).filter(User.xp > user.xp).count() + 1
    return LeaderboardEntry(rank=rank, user_id=user.id, name=user.name, xp=user.xp, level=user.level)
