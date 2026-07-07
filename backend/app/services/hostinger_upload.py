"""Shared helper: stream a FastAPI UploadFile to persistent Hostinger
storage instead of writing to local disk.

Local disk on Railway (and most container PaaS) is ephemeral — it's wiped on
every restart/redeploy. Any endpoint that saves uploads there will silently
lose those files the next time the container restarts.

Deliberately validates by file EXTENSION only, not content-type: real
clients (mobile file pickers, some browsers) frequently send a generic
"application/octet-stream" — or no content-type at all — even for a
perfectly valid PNG/PDF/etc. `storage_service.upload_image/upload_video/
upload_document` enforce a strict content-type-must-match-extension check
that would reject those uploads, so this helper calls the lower-level
`upload_local_file`/`get_public_url` directly instead, mirroring the
already-working /auth/upload-gov-id endpoint's approach.
"""
from __future__ import annotations

import os
import pathlib
import tempfile
import uuid

import aiofiles
from fastapi import HTTPException, UploadFile
from starlette.concurrency import run_in_threadpool

from . import storage_service

DEFAULT_MAX_SIZE = 20 * 1024 * 1024  # 20 MB


async def upload_to_hostinger(
    file: UploadFile,
    *,
    subdir: str,
    allowed_extensions: set[str],
    max_size: int = DEFAULT_MAX_SIZE,
) -> str:
    """Streams `file` to Hostinger's <upload_root>/<subdir>/ and returns its
    public URL."""
    ext = pathlib.Path(file.filename or "").suffix.lower()
    if ext not in allowed_extensions:
        raise HTTPException(
            status_code=400,
            detail=f"File type '{ext or '(none)'}' not allowed. Allowed: {', '.join(sorted(allowed_extensions))}",
        )

    filename = f"{uuid.uuid4().hex}{ext}"
    fd, local_path = tempfile.mkstemp(prefix="upload_")
    os.close(fd)
    size = 0
    try:
        async with aiofiles.open(local_path, "wb") as out:
            while True:
                chunk = await file.read(1024 * 1024)
                if not chunk:
                    break
                size += len(chunk)
                if size > max_size:
                    raise HTTPException(
                        status_code=400,
                        detail=f"File too large. Maximum {max_size // (1024 * 1024)} MB allowed.",
                    )
                await out.write(chunk)

        try:
            await run_in_threadpool(storage_service.upload_local_file, local_path, subdir, filename)
        except storage_service.StorageError as exc:
            raise HTTPException(status_code=502, detail=f"Upload to remote storage failed: {exc}")
        return storage_service.get_public_url(subdir, filename)
    finally:
        if os.path.exists(local_path):
            os.remove(local_path)
