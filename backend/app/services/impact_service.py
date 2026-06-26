from datetime import datetime

from sqlalchemy.orm import Session

from ..repositories import impact_repository
from ..schemas.impact import ImpactPostOut


def serialize_post(db: Session, post, user_id: int | None, public_url: str) -> dict:
    payload = ImpactPostOut.model_validate(post).model_dump()
    payload["appreciated_by_me"] = bool(user_id and impact_repository.has_reacted(db, post.id, user_id))
    payload["public_url"] = f"{public_url.rstrip('/')}/public/impact/{post.id}"
    return payload


def publish(db: Session, post, approver_id: int):
    post.status = "published"
    post.approved_by = approver_id
    post.published_at = datetime.utcnow()
    db.commit()
    db.refresh(post)
    return post
