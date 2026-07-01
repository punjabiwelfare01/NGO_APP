from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel

from ..models.file_asset import FileAssetType


class FileAssetResponse(BaseModel):
    id: int
    filename: str
    original_filename: str
    file_type: FileAssetType
    mime_type: str
    size: int
    public_url: str
    uploaded_at: datetime
    uploaded_by: int

    model_config = {"from_attributes": True}


class UploadResponse(BaseModel):
    id: int
    url: str
    filename: str
    size: int
