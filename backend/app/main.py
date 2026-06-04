from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles

from .config import settings
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
)
from .database import Base
from .dev_migrations import ensure_sqlite_schema
from .middleware.rbac_logging import RBACLoggingMiddleware
from .routers import auth, badges, courses, leaderboard, users, wellness
from .routers import counselling
from .routers import events
from .routers import quiz
from .routers import safety
from .routers import emergency
from .routers import chat
from .routers import upload

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
app.include_router(upload.router)


@app.get("/health", tags=["Health"])
def health():
    return {"status": "ok", "app": settings.app_name, "version": settings.version}


# ── Uploaded files static serving ─────────────────────────────────────────────
_uploads_dir = Path(__file__).parent.parent.parent / "uploads"
_uploads_dir.mkdir(exist_ok=True)
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
