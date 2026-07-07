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

from ..config import settings
from . import storage_service

DEFAULT_MAX_SIZE = 20 * 1024 * 1024  # 20 MB

# Local fallback root — only used when Hostinger isn't configured (e.g. the
# test suite, which monkeypatches settings.hostinger_host to "" to avoid
# hitting real external storage). In any real deployment this branch never
# runs, so it doesn't reintroduce the ephemeral-disk bug for production.
# Deliberately relative to the CWD (not __file__) so tests can redirect it
# into a throwaway tmp_path via monkeypatch.chdir().
_LOCAL_FALLBACK_DIRNAME = "uploads"


async def upload_to_hostinger(
    file: UploadFile,
    *,
    subdir: str,
    allowed_extensions: set[str],
    max_size: int = DEFAULT_MAX_SIZE,
) -> str:
    """Streams `file` to Hostinger's <upload_root>/<subdir>/ and returns its
    public URL. Falls back to local disk only if Hostinger isn't configured
    at all (see _LOCAL_FALLBACK_ROOT)."""
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

        if not (settings.hostinger_host and settings.hostinger_username):
            dest_dir = pathlib.Path(_LOCAL_FALLBACK_DIRNAME) / subdir
            dest_dir.mkdir(parents=True, exist_ok=True)
            dest = dest_dir / filename
            async with aiofiles.open(local_path, "rb") as src:
                content = await src.read()
            async with aiofiles.open(dest, "wb") as out:
                await out.write(content)
            return f"/uploads/{subdir}/{filename}"

        try:
            await run_in_threadpool(storage_service.upload_local_file, local_path, subdir, filename)
        except storage_service.StorageError as exc:
            raise HTTPException(status_code=502, detail=f"Upload to remote storage failed: {exc}")
        return storage_service.get_public_url(subdir, filename)
    finally:
        if os.path.exists(local_path):
            os.remove(local_path)
