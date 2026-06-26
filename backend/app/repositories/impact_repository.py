from sqlalchemy import func
from sqlalchemy.orm import Session, selectinload

from ..models.impact import ImpactPost, ImpactPostMedia, ImpactPostReaction


def list_posts(db: Session, status: str = "published", category: str | None = None):
    query = db.query(ImpactPost).options(selectinload(ImpactPost.media)).filter(ImpactPost.status == status)
    if category:
        query = query.filter(ImpactPost.category == category)
    return query.order_by(ImpactPost.published_at.desc(), ImpactPost.created_at.desc()).all()


def get_post(db: Session, post_id: int):
    return db.query(ImpactPost).options(selectinload(ImpactPost.media)).filter(ImpactPost.id == post_id).first()


def create_post(db: Session, data, creator_id: int):
    payload = data.model_dump(exclude={"media"})
    post = ImpactPost(**payload, created_by=creator_id)
    for media in data.media:
        post.media.append(ImpactPostMedia(**media.model_dump()))
    db.add(post)
    db.commit()
    db.refresh(post)
    return get_post(db, post.id)


def update_post(db: Session, post: ImpactPost, data):
    for key, value in data.model_dump(exclude_none=True).items():
        setattr(post, key, value)
    db.commit()
    db.refresh(post)
    return post


def reaction(db: Session, post_id: int, user_id: int):
    existing = db.query(ImpactPostReaction).filter(
        ImpactPostReaction.post_id == post_id,
        ImpactPostReaction.user_id == user_id,
    ).first()
    post = get_post(db, post_id)
    if not post:
        return None, False
    if existing:
        db.delete(existing)
        post.appreciation_count = max(0, post.appreciation_count - 1)
        active = False
    else:
        db.add(ImpactPostReaction(post_id=post_id, user_id=user_id))
        post.appreciation_count += 1
        active = True
    db.commit()
    db.refresh(post)
    return post, active


def has_reacted(db: Session, post_id: int, user_id: int) -> bool:
    return db.query(ImpactPostReaction.id).filter(
        ImpactPostReaction.post_id == post_id,
        ImpactPostReaction.user_id == user_id,
    ).first() is not None


def metrics(db: Session):
    row = db.query(
        func.count(ImpactPost.id),
        func.coalesce(func.sum(ImpactPost.people_reached), 0),
        func.coalesce(func.sum(ImpactPost.donation_collected), 0),
        func.coalesce(func.sum(ImpactPost.hours_served), 0),
        func.coalesce(func.sum(ImpactPost.appreciation_count), 0),
        func.coalesce(func.sum(ImpactPost.share_count), 0),
    ).filter(ImpactPost.status == "published").one()
    return row
