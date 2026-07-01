from __future__ import annotations

from sqlalchemy.orm import Session

from ..models.file_asset import FileAsset
from ..services.storage_service import StoredFile


def create_file_asset(db: Session, stored: StoredFile, uploaded_by: int) -> FileAsset:
    obj = FileAsset(
        filename=stored.filename,
        original_filename=stored.original_filename,
        file_type=stored.file_type,
        mime_type=stored.mime_type,
        size=stored.size,
        remote_path=stored.remote_path,
        public_url=stored.public_url,
        uploaded_by=uploaded_by,
    )
    db.add(obj)
    db.commit()
    db.refresh(obj)
    return obj


def get_file_asset(db: Session, file_id: int) -> FileAsset | None:
    return db.query(FileAsset).filter(FileAsset.id == file_id).first()


def delete_file_asset(db: Session, obj: FileAsset) -> None:
    db.delete(obj)
    db.commit()
