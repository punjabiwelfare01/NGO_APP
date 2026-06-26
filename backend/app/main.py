from pathlib import Path
import mimetypes

from fastapi import Depends, FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse, Response, StreamingResponse
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from fastapi.staticfiles import StaticFiles
from sqlalchemy.orm import Session

from .config import settings
from .database import get_db
from .logging_config import setup_logging

setup_logging(level="INFO")
from .database import engine
from .models import (  # noqa: F401 — registers all ORM models before create_all
    Badge, BlacklistedToken, Course, CounsellingAvailability, CounsellingSession,
    CounsellingNotification, MentorProfile,
    Event, EventParticipant, EventQuiz, EventSelection, EventSlot,
    Lesson, SkillCategory, User, UserBadge, UserCourseProgress, UserLessonProgress,
    Quiz, Question, QuizAttempt, DailyChallenge,
    SafetyAwarenessQuestion, UserSafetyAnswer,
    EmergencyContact,
    ChatMessage,
    AdminNotification,
    StudentReminder,
    CreatorPost,
    VolunteerActivity, ActivityApplication, ActivityAssignment, WorkSubmission, DailyLog, ImpactStory,
    Donation, StipendConfig, StipendRecord, NGOPaymentDetails,
    Certificate,
    ImpactPost, ImpactPostMedia, ImpactPostReaction,
    Notification, NotificationPreference, UserSetting, NGOProfileSetting,
    BankSetting, RolePermissionSetting, AppSetting, AdminAuditLog,
    Announcement, PasswordResetToken, ReminderJob, EventReportFile,
    SchoolCounsellorRequest, CounsellorSessionReport,
)
from .database import Base
from .dev_migrations import ensure_sqlite_schema
from .middleware.rbac_logging import RBACLoggingMiddleware
from .routers import admin, auth, badges, courses, leaderboard, users, wellness
from .routers import counselling
from .routers import events
from .routers import quiz
from .routers import safety
from .routers import emergency
from .routers import chat
from .routers import creator
from .routers import upload
from .routers import calendar
from .routers import volunteer
from .routers import donations
from .routers import certificates
from .routers import student
from .routers import impact
from .routers import notifications, profile, admin_settings
from .routers import reports
from .routers import event_manager
from .routers import counsellor_workspace
from .routers import school_partner

Base.metadata.create_all(bind=engine)
ensure_sqlite_schema(engine)

app = FastAPI(
    title=settings.app_name,
    version=settings.version,
    debug=settings.debug,
)

# ── middleware (order matters: outermost first) ────────────────────────────────
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
app.add_middleware(RBACLoggingMiddleware)


# Tells ngrok to set a browser cookie that permanently skips the free-tier
# interstitial warning page for this domain.
@app.middleware("http")
async def ngrok_skip_warning(request, call_next):
    response = await call_next(request)
    response.headers["ngrok-skip-browser-warning"] = "true"
    return response

# ── routers ────────────────────────────────────────────────────────────────────
app.include_router(auth.router)
app.include_router(admin.router)
app.include_router(users.router)
app.include_router(courses.router)
app.include_router(wellness.router)
app.include_router(counselling.router)
app.include_router(badges.router)
app.include_router(leaderboard.router)
app.include_router(events.router)
app.include_router(events.root_router)
app.include_router(quiz.router)
app.include_router(safety.router)
app.include_router(emergency.router)
app.include_router(chat.router)
app.include_router(creator.router)
app.include_router(upload.router)
app.include_router(calendar.router)
app.include_router(volunteer.router)
app.include_router(donations.router)
app.include_router(certificates.router)
app.include_router(certificates.admin_router)
app.include_router(certificates.student_router)
app.include_router(certificates.public_router)
app.include_router(student.router)
app.include_router(impact.router)
app.include_router(notifications.router)
app.include_router(profile.router)
app.include_router(admin_settings.router)
app.include_router(reports.router)
app.include_router(event_manager.router)
app.include_router(counsellor_workspace.router)
app.include_router(school_partner.router)


@app.get("/health", tags=["Health"])
def health():
    return {"status": "ok", "app": settings.app_name, "version": settings.version}


# ── File serving directories ───────────────────────────────────────────────────
_uploads_dir = Path(__file__).parent.parent / "uploads"
_uploads_dir.mkdir(exist_ok=True)

_videos_dir = Path(__file__).parent.parent / "videos_uploaded"
_videos_dir.mkdir(exist_ok=True)

# Bearer-or-query-param auth for the video streaming endpoint.
# HTML <video> elements cannot set custom headers, so the web player
# passes the JWT as ?token=<jwt>. Native players use the Authorization header.
_bearer_optional = HTTPBearer(auto_error=False)


def _get_video_user(
    request: Request,
    credentials: HTTPAuthorizationCredentials | None = Depends(_bearer_optional),
    db: Session = Depends(get_db),
):
    from .crud.auth_crud import decode_token, is_token_revoked
    from .models.user import User

    token = credentials.credentials if credentials else request.query_params.get("token")
    if not token:
        raise HTTPException(status_code=401, detail="Not authenticated")
    try:
        payload = decode_token(token)
        user_id = int(payload["sub"])
        jti = payload.get("jti", "")
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid or expired token")
    if is_token_revoked(db, jti):
        raise HTTPException(status_code=401, detail="Token has been revoked")
    user = db.query(User).filter(User.id == user_id, User.is_active.is_(True)).first()
    if not user:
        raise HTTPException(status_code=401, detail="User not found or inactive")
    return user


def _stream_file(video_path: Path, content_type: str, request: Request):
    """Serve a file with range-request support and anti-download headers."""
    file_size = video_path.stat().st_size
    headers = {
        "Accept-Ranges": "bytes",
        "Content-Disposition": "inline",
        "Cache-Control": "no-store, no-cache, must-revalidate, max-age=0",
        "Pragma": "no-cache",
        "X-Content-Type-Options": "nosniff",
    }

    range_header = request.headers.get("range")
    if not range_header:
        if request.method == "HEAD":
            return Response(
                headers={**headers, "Content-Length": str(file_size)},
                media_type=content_type,
            )
        return FileResponse(str(video_path), media_type=content_type, headers=headers)

    unit, _, byte_range = range_header.partition("=")
    if unit.strip().lower() != "bytes" or "-" not in byte_range:
        return Response(status_code=416, headers={"Content-Range": f"bytes */{file_size}"})

    start_text, end_text = byte_range.split("-", 1)
    try:
        if start_text:
            start = int(start_text)
            end = int(end_text) if end_text else file_size - 1
        else:
            suffix_length = int(end_text)
            start = max(file_size - suffix_length, 0)
            end = file_size - 1
    except ValueError:
        return Response(status_code=416, headers={"Content-Range": f"bytes */{file_size}"})

    if start >= file_size or end < start:
        return Response(status_code=416, headers={"Content-Range": f"bytes */{file_size}"})

    end = min(end, file_size - 1)
    chunk_size = end - start + 1
    response_headers = {
        **headers,
        "Content-Range": f"bytes {start}-{end}/{file_size}",
        "Content-Length": str(chunk_size),
    }

    if request.method == "HEAD":
        return Response(status_code=206, headers=response_headers, media_type=content_type)

    def _iter_range():
        with video_path.open("rb") as f:
            f.seek(start)
            remaining = chunk_size
            while remaining > 0:
                chunk = f.read(min(1024 * 1024, remaining))
                if not chunk:
                    break
                remaining -= len(chunk)
                yield chunk

    return StreamingResponse(
        _iter_range(),
        status_code=206,
        media_type=content_type,
        headers=response_headers,
    )


@app.api_route(
    "/video/stream/{filename}",
    methods=["GET", "HEAD"],
    include_in_schema=False,
)
async def stream_video(
    filename: str,
    request: Request,
    _: object = Depends(_get_video_user),
):
    """Authenticated video streaming endpoint with anti-download headers.

    Accepts the JWT via Authorization: Bearer header (native apps) or
    via ?token= query param (web HTML video elements which cannot set headers).
    Videos are never served from the public /uploads/ endpoint.
    """
    safe_name = Path(filename).name
    video_path = _videos_dir / safe_name
    if not video_path.is_file():
        raise HTTPException(status_code=404, detail="Not Found")

    content_type = mimetypes.guess_type(video_path.name)[0] or "video/mp4"
    return _stream_file(video_path, content_type, request)


@app.api_route(
    "/uploads/{filename}",
    methods=["GET", "HEAD"],
    include_in_schema=False,
)
async def serve_upload(filename: str, request: Request):
    upload_path = _uploads_dir / filename
    if not upload_path.is_file() or upload_path.parent != _uploads_dir:
        raise HTTPException(status_code=404, detail="Not Found")

    content_type = mimetypes.guess_type(upload_path.name)[0] or "application/octet-stream"
    return _stream_file(upload_path, content_type, request)


app.mount("/uploads", StaticFiles(directory=str(_uploads_dir)), name="uploads")

# ── Flutter Web static file serving ───────────────────────────────────────────
# Serves the Flutter Web build from build/web/ at the root.
# API routes registered above always take priority — only unmatched paths reach here.
# Build the Flutter app first:
#   flutter build web --dart-define=API_BASE_URL=https://streak-pogo-bonded.ngrok-free.dev
_flutter_build = Path(__file__).parent.parent.parent / "build" / "web"


@app.get("/", include_in_schema=False)
@app.get("/{full_path:path}", include_in_schema=False)
async def serve_flutter(full_path: str = ""):
    if not _flutter_build.exists():
        return {"status": "ok", "app": settings.app_name, "note": "No Flutter build found. Run: flutter build web"}
    candidate = _flutter_build / full_path
    if candidate.is_file():
        return FileResponse(str(candidate))
    # For all Flutter client-side routes return index.html (SPA behaviour)
    return FileResponse(str(_flutter_build / "index.html"))
