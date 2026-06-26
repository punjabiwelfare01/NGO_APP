import uuid
from pathlib import Path

import aiofiles
from fastapi import APIRouter, Depends, HTTPException, UploadFile

from ..database import get_db
from ..dependencies import content_creator_or_above, get_current_user
from ..models.user import User
from ..schemas.user import UserResponse
from sqlalchemy.orm import Session

router = APIRouter(tags=["Upload"])

_UPLOADS_DIR = Path(__file__).parent.parent.parent / "uploads"
_UPLOADS_DIR.mkdir(exist_ok=True)

# Videos are stored separately and served via the authenticated /video/stream/ endpoint.
_VIDEOS_DIR = Path(__file__).parent.parent.parent / "videos_uploaded"
_VIDEOS_DIR.mkdir(exist_ok=True)

_PHOTO_DIR = Path(__file__).parent.parent.parent / "uploads" / "profile_photos"
_PHOTO_DIR.mkdir(parents=True, exist_ok=True)

_VIDEO_EXTENSIONS = {".mp4", ".mov", ".avi", ".mkv", ".webm"}

_ALLOWED_EXTENSIONS = {
    ".pdf", ".png", ".jpg", ".jpeg", ".gif", ".webp",
    ".txt", ".docx", ".zip",
} | _VIDEO_EXTENSIONS

_IMAGE_EXTENSIONS = {".png", ".jpg", ".jpeg", ".gif", ".webp"}

_CHUNK_SIZE = 1024 * 1024  # 1 MB — stream large files to disk without full RAM load


@router.post(
    "/upload",
    summary="Upload a file [content_creator, mentor, admin, super_admin]",
)
async def upload_file(
    file: UploadFile,
    _: User = Depends(content_creator_or_above),
):
    original = Path(file.filename or "upload")
    ext = original.suffix.lower()
    if ext not in _ALLOWED_EXTENSIONS:
        raise HTTPException(status_code=400, detail=f"File type '{ext}' not allowed.")

    filename = f"{uuid.uuid4()}{ext}"
    is_video = ext in _VIDEO_EXTENSIONS
    dest = (_VIDEOS_DIR if is_video else _UPLOADS_DIR) / filename

    # Async streaming write — never blocks the event loop, even for 100 MB+ files.
    async with aiofiles.open(dest, "wb") as out:
        while True:
            chunk = await file.read(_CHUNK_SIZE)
            if not chunk:
                break
            await out.write(chunk)

    url = f"/video/stream/{filename}" if is_video else f"/uploads/{filename}"
    return {"url": url, "original_name": original.name}


@router.post(
    "/users/me/photo",
    response_model=UserResponse,
    summary="Upload or replace the current user's profile photo",
)
async def upload_profile_photo(
    file: UploadFile,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    original = Path(file.filename or "photo")
    ext = original.suffix.lower()
    if ext not in _IMAGE_EXTENSIONS:
        raise HTTPException(status_code=400, detail=f"File type '{ext}' not allowed. Use png/jpg/jpeg/gif/webp.")

    # Delete the previous photo file if it was stored locally.
    if current_user.photo_url and current_user.photo_url.startswith("/uploads/profile_photos/"):
        old_path = _PHOTO_DIR / Path(current_user.photo_url).name
        if old_path.exists():
            old_path.unlink(missing_ok=True)

    filename = f"{uuid.uuid4()}{ext}"
    dest = _PHOTO_DIR / filename

    async with aiofiles.open(dest, "wb") as out:
        while True:
            chunk = await file.read(_CHUNK_SIZE)
            if not chunk:
                break
            await out.write(chunk)

    current_user.photo_url = f"/uploads/profile_photos/{filename}"
    db.commit()
    db.refresh(current_user)
    return current_user
