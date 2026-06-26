from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.orm import Session

from ..database import get_db
from ..dependencies import get_current_user, get_optional_user, require_role
from ..models.user import User, UserRole
from ..repositories import impact_repository
from ..schemas.impact import ImpactMetricsOut, ImpactPostCreate, ImpactPostOut, ImpactPostUpdate, ImpactShareOut
from ..services import impact_service

router = APIRouter(prefix="/impact", tags=["Impact"])


def _base(request: Request) -> str:
    return str(request.base_url).rstrip("/")


@router.get("/posts", response_model=list[ImpactPostOut])
def posts(
    request: Request,
    status: str = "published",
    category: str | None = None,
    db: Session = Depends(get_db),
    user: User | None = Depends(get_optional_user),
):
    if status != "published" and (not user or user.role not in (UserRole.event_manager, UserRole.admin, UserRole.super_admin)):
        raise HTTPException(403, "Published posts only")
    return [impact_service.serialize_post(db, post, user.id if user else None, _base(request)) for post in impact_repository.list_posts(db, status, category)]


@router.get("/posts/{post_id}", response_model=ImpactPostOut)
def post(post_id: int, request: Request, db: Session = Depends(get_db), user: User | None = Depends(get_optional_user)):
    item = impact_repository.get_post(db, post_id)
    if not item or (item.status != "published" and not user):
        raise HTTPException(404, "Impact post not found")
    return impact_service.serialize_post(db, item, user.id if user else None, _base(request))


@router.get("/metrics", response_model=ImpactMetricsOut)
def impact_metrics(db: Session = Depends(get_db)):
    row = impact_repository.metrics(db)
    return {"posts": row[0], "people_reached": row[1], "donation_collected": row[2], "hours_served": row[3], "appreciations": row[4], "shares": row[5]}


@router.post("/posts", response_model=ImpactPostOut, status_code=201)
def create(data: ImpactPostCreate, request: Request, db: Session = Depends(get_db), user: User = Depends(require_role(UserRole.event_manager))):
    item = impact_repository.create_post(db, data, user.id)
    return impact_service.serialize_post(db, item, user.id, _base(request))


@router.patch("/posts/{post_id}", response_model=ImpactPostOut)
def update(post_id: int, data: ImpactPostUpdate, request: Request, db: Session = Depends(get_db), user: User = Depends(require_role(UserRole.event_manager))):
    item = impact_repository.get_post(db, post_id)
    if not item:
        raise HTTPException(404, "Impact post not found")
    if user.role == UserRole.event_manager and item.created_by != user.id:
        raise HTTPException(403, "Access denied")
    item = impact_repository.update_post(db, item, data)
    return impact_service.serialize_post(db, item, user.id, _base(request))


@router.post("/posts/{post_id}/publish", response_model=ImpactPostOut)
def publish(post_id: int, request: Request, db: Session = Depends(get_db), user: User = Depends(require_role(UserRole.admin))):
    item = impact_repository.get_post(db, post_id)
    if not item:
        raise HTTPException(404, "Impact post not found")
    item = impact_service.publish(db, item, user.id)
    return impact_service.serialize_post(db, item, user.id, _base(request))


@router.post("/posts/{post_id}/appreciate", response_model=ImpactPostOut)
def appreciate(post_id: int, request: Request, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    item = impact_repository.get_post(db, post_id)
    if not item or item.status != "published":
        raise HTTPException(404, "Impact post not found")
    item, _ = impact_repository.reaction(db, post_id, user.id)
    return impact_service.serialize_post(db, item, user.id, _base(request))


@router.post("/posts/{post_id}/share", response_model=ImpactShareOut)
def share(post_id: int, request: Request, db: Session = Depends(get_db)):
    item = impact_repository.get_post(db, post_id)
    if not item or item.status != "published":
        raise HTTPException(404, "Impact post not found")
    item.share_count += 1
    db.commit()
    db.refresh(item)
    return {"post_id": item.id, "public_url": f"{_base(request)}/public/impact/{item.id}", "share_count": item.share_count}
