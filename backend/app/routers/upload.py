import uuid
from pathlib import Path

from fastapi import APIRouter, Depends, UploadFile

from ..dependencies import non_student
from ..models.user import User

router = APIRouter(tags=["Upload"])

_UPLOADS_DIR = Path(__file__).parent.parent.parent / "uploads"
_UPLOADS_DIR.mkdir(exist_ok=True)

_ALLOWED_EXTENSIONS = {
    ".pdf", ".png", ".jpg", ".jpeg", ".gif", ".webp",
    ".mp4", ".mov", ".avi", ".mkv", ".webm",
    ".txt", ".docx",
}


@router.post("/upload", summary="Upload a file [all roles except student]")
async def upload_file(
    file: UploadFile,
    _: User = Depends(non_student),
):
    original = Path(file.filename or "upload")
    ext = original.suffix.lower()
    if ext not in _ALLOWED_EXTENSIONS:
        from fastapi import HTTPException
        raise HTTPException(status_code=400, detail=f"File type '{ext}' not allowed.")
    filename = f"{uuid.uuid4()}{ext}"
    dest = _UPLOADS_DIR / filename
    dest.write_bytes(await file.read())
    return {"url": f"/uploads/{filename}", "original_name": original.name}
