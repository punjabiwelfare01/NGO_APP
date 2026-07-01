import logging
import os
import tempfile
from typing import Callable

import aiofiles
from fastapi import APIRouter, Depends, HTTPException, UploadFile
from sqlalchemy.orm import Session
from starlette.concurrency import run_in_threadpool

from ..crud import file_asset_crud
from ..database import get_db
from ..dependencies import get_current_user
from ..models.user import User, UserRole
from ..schemas.file_asset import FileAssetResponse, UploadResponse
from ..services import storage_service
from ..services.storage_service import StoredFile

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/upload", tags=["File Storage"])

_CHUNK_SIZE = 1024 * 1024  # 1 MB — stream to disk without holding the whole file in RAM


async def _stream_to_temp_file(file: UploadFile) -> tuple[str, int]:
    fd, path = tempfile.mkstemp(prefix="upload_")
    os.close(fd)
    size = 0
    async with aiofiles.open(path, "wb") as out:
        while True:
            chunk = await file.read(_CHUNK_SIZE)
            if not chunk:
                break
            size += len(chunk)
            await out.write(chunk)
    return path, size


async def _handle_upload(
    file: UploadFile,
    uploader: User,
    db: Session,
    upload_fn: Callable[[str, int, str, str | None], StoredFile],
) -> UploadResponse:
    local_path, size = await _stream_to_temp_file(file)
    try:
        try:
            stored = await run_in_threadpool(
                upload_fn, local_path, size, file.filename or "upload", file.content_type
            )
        except storage_service.StorageValidationError as exc:
            raise HTTPException(status_code=400, detail=str(exc))
        except storage_service.StorageError as exc:
            raise HTTPException(status_code=502, detail=f"Upload to remote storage failed: {exc}")

        try:
            asset = file_asset_crud.create_file_asset(db, stored, uploader.id)
        except Exception:
            try:
                await run_in_threadpool(storage_service.delete_file, stored.remote_path)
            except storage_service.StorageError:
                logger.exception("Failed to roll back orphaned remote file %s", stored.remote_path)
            raise HTTPException(status_code=500, detail="Failed to save file metadata; upload rolled back.")

        return UploadResponse(id=asset.id, url=asset.public_url, filename=asset.filename, size=asset.size)
    finally:
        if os.path.exists(local_path):
            os.remove(local_path)


@router.post("/image", response_model=UploadResponse, summary="Upload an image to Hostinger storage")
async def upload_image(
    file: UploadFile,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return await _handle_upload(file, current_user, db, storage_service.upload_image)


@router.post("/video", response_model=UploadResponse, summary="Upload a video to Hostinger storage")
async def upload_video(
    file: UploadFile,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return await _handle_upload(file, current_user, db, storage_service.upload_video)


@router.post("/document", response_model=UploadResponse, summary="Upload a document to Hostinger storage")
async def upload_document(
    file: UploadFile,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return await _handle_upload(file, current_user, db, storage_service.upload_document)


@router.get("/{file_id}", response_model=FileAssetResponse, summary="Get file asset metadata")
async def get_file(
    file_id: int,
    _: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    asset = file_asset_crud.get_file_asset(db, file_id)
    if not asset:
        raise HTTPException(status_code=404, detail="File not found")
    return asset


@router.delete("/{file_id}", summary="Delete a file asset and its remote file")
async def delete_file(
    file_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    asset = file_asset_crud.get_file_asset(db, file_id)
    if not asset:
        raise HTTPException(status_code=404, detail="File not found")
    if asset.uploaded_by != current_user.id and current_user.role not in (UserRole.admin, UserRole.super_admin):
        raise HTTPException(status_code=403, detail="You do not have permission to delete this file")

    try:
        await run_in_threadpool(storage_service.delete_file, asset.remote_path)
    except storage_service.StorageError as exc:
        raise HTTPException(status_code=502, detail=f"Failed to delete remote file: {exc}")

    file_asset_crud.delete_file_asset(db, asset)
    return {"detail": "File deleted"}
