from fastapi import APIRouter, Depends, File, Form, HTTPException, Request, UploadFile
from sqlalchemy.orm import Session

from ..database import get_db
from ..dependencies import get_current_user, get_optional_user, require_role
from ..models.impact import ImpactPostMedia
from ..models.user import User, UserRole
from ..repositories import impact_repository
from ..schemas.impact import ImpactMetricsOut, ImpactPostCreate, ImpactPostOut, ImpactPostUpdate, ImpactShareOut
from ..services import impact_service
from ..services.hostinger_upload import upload_to_hostinger

router = APIRouter(prefix="/impact", tags=["Impact"])

_ALLOWED_MEDIA_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp", ".mp4", ".mov", ".pdf"}


def _base(request: Request) -> str:
    return str(request.base_url).rstrip("/")


_IMPACT_CREATOR_ROLES = (UserRole.mentor, UserRole.event_manager, UserRole.admin, UserRole.super_admin)


@router.get("/posts", response_model=list[ImpactPostOut])
def posts(
    request: Request,
    status: str = "published",
    category: str | None = None,
    mine: bool = False,
    db: Session = Depends(get_db),
    user: User | None = Depends(get_optional_user),
):
    if mine:
        if not user or user.active_role not in _IMPACT_CREATOR_ROLES:
            raise HTTPException(403, "Not allowed")
        posts = impact_repository.list_posts(db, status=None, category=category, created_by=user.id)
        return [impact_service.serialize_post(db, item, user.id, _base(request)) for item in posts]
    if status != "published" and (not user or user.active_role not in (UserRole.event_manager, UserRole.admin, UserRole.super_admin)):
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
def create(data: ImpactPostCreate, request: Request, db: Session = Depends(get_db), user: User = Depends(require_role(UserRole.mentor))):
    item = impact_repository.create_post(db, data, user.id)
    return impact_service.serialize_post(db, item, user.id, _base(request))


@router.post("/upload-media", status_code=201)
async def upload_media(
    file: UploadFile = File(...),
    media_type: str = Form(default="image"),
    user: User = Depends(require_role(UserRole.mentor)),
):
    """Upload an impact media file immediately and return its URL.
    Pass the URL in the `media` list when creating or updating an impact post.
    """
    url = await upload_to_hostinger(file, subdir="impact", allowed_extensions=_ALLOWED_MEDIA_EXTENSIONS)
    return {"url": url, "media_type": media_type}


@router.post("/posts/{post_id}/media", status_code=201)
async def add_media(
    post_id: int,
    file: UploadFile = File(...),
    caption: str = Form(default=""),
    is_cover: str = Form(default="false"),
    display_order: int = Form(default=0),
    media_type: str = Form(default="image"),
    db: Session = Depends(get_db),
    user: User = Depends(require_role(UserRole.mentor)),
):
    item = impact_repository.get_post(db, post_id)
    if not item:
        raise HTTPException(404, "Impact post not found")
    if user.active_role in (UserRole.event_manager, UserRole.mentor) and item.created_by != user.id:
        raise HTTPException(403, "Access denied")

    url = await upload_to_hostinger(file, subdir="impact", allowed_extensions=_ALLOWED_MEDIA_EXTENSIONS)
    media = ImpactPostMedia(
        post_id=post_id,
        media_type=media_type,
        url=url,
        caption=caption or None,
        position=display_order,
    )
    db.add(media)
    db.commit()
    db.refresh(media)
    return {"media_url": url, "id": media.id}


@router.patch("/posts/{post_id}", response_model=ImpactPostOut)
def update(post_id: int, data: ImpactPostUpdate, request: Request, db: Session = Depends(get_db), user: User = Depends(require_role(UserRole.mentor))):
    item = impact_repository.get_post(db, post_id)
    if not item:
        raise HTTPException(404, "Impact post not found")
    if user.active_role in (UserRole.event_manager, UserRole.mentor) and item.created_by != user.id:
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


@router.delete("/posts/{post_id}", status_code=204)
def delete(post_id: int, db: Session = Depends(get_db), user: User = Depends(require_role(UserRole.admin))):
    item = impact_repository.get_post(db, post_id)
    if not item:
        raise HTTPException(404, "Impact post not found")
    impact_repository.delete_post(db, item)


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
