import logging
import secrets
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, File, Form, HTTPException, Request, UploadFile
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from google.auth.exceptions import GoogleAuthError
from google.auth.transport import requests as google_requests
from google.oauth2 import id_token as google_id_token
from pydantic import BaseModel
from sqlalchemy.orm import Session

logger = logging.getLogger(__name__)

from ..auth0_validator import verify_auth0_token
from ..config import settings
from ..crud.auth_crud import (
    create_access_token,
    decode_token,
    get_or_create_auth0_user,
    get_or_create_google_user,
    get_user_by_email,
    hash_password,
    register_user,
    revoke_token,
    verify_password,
)
from ..database import get_db
from ..dependencies import get_current_user, require_role
from ..google_calendar import exchange_code_for_tokens, get_authorization_url, is_calendar_authorized
from ..models.user import User, UserRole
from ..services.hostinger_upload import upload_to_hostinger
from ..schemas.auth import (
    ChangePasswordRequest,
    ForgotPasswordRequest,
    LoginRequest,
    RegisterRequest,
    ResetPasswordRequest,
    SwitchRoleRequest,
    VerifyResetCodeRequest,
    TokenResponse,
)
from ..schemas.user import UserResponse

router = APIRouter(prefix="/auth", tags=["Auth"])
_bearer = HTTPBearer()


@router.post("/register", status_code=201,
             summary="Register a new user account")
def register(payload: RegisterRequest, db: Session = Depends(get_db)):
    if get_user_by_email(db, payload.email):
        raise HTTPException(status_code=409, detail="Email already registered")
    user = register_user(db, payload, pending_access=True)
    token = create_access_token(user)
    return {
        "message": "Registration successful. Your access request is pending admin approval.",
        "access_token": token,
        "user": {
            "id": user.id,
            "name": user.name,
            "email": user.email,
            "role": user.role.value,
            "roles": sorted(r.value for r in user.granted_roles),
            "access_status": user.access_status,
            "requested_role": user.requested_role,
        },
    }


_GOV_ID_ALLOWED = {".pdf", ".jpg", ".jpeg", ".png"}
_GOV_ID_MAX_BYTES = 10 * 1024 * 1024  # 10 MB


@router.post("/upload-gov-id", status_code=200,
             summary="Upload a government ID document for admin verification")
async def upload_gov_id(
    file: UploadFile = File(...),
    id_type: str = Form(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    doc_url = await upload_to_hostinger(
        file, subdir="gov_ids", allowed_extensions=_GOV_ID_ALLOWED, max_size=_GOV_ID_MAX_BYTES,
    )
    current_user.gov_id_type = id_type.strip()
    current_user.gov_id_doc_url = doc_url
    db.commit()

    return {"message": "Government ID uploaded successfully.", "doc_url": doc_url}


@router.post("/login", response_model=TokenResponse,
             summary="Login and receive a JWT access token")
def login(payload: LoginRequest, db: Session = Depends(get_db)):
    user = get_user_by_email(db, payload.email)
    if not user or not user.hashed_password:
        raise HTTPException(status_code=401, detail="Invalid credentials")
    if not verify_password(payload.password, user.hashed_password):
        raise HTTPException(status_code=401, detail="Invalid credentials")
    if not user.is_active:
        raise HTTPException(status_code=403, detail="Account is inactive")
    access_status = getattr(user, "access_status", "approved") or "approved"
    user.last_login_at = datetime.now(timezone.utc)
    db.commit()
    token = create_access_token(user)
    return TokenResponse(
        access_token=token,
        role=user.role.value,
        roles=sorted(r.value for r in user.granted_roles),
        user_id=user.id,
        name=user.name,
        access_status=access_status,
    )


@router.post("/switch-role", response_model=TokenResponse,
             summary="Switch the active role for a multi-role account, without logging out")
def switch_role(
    payload: SwitchRoleRequest,
    current_user: User = Depends(get_current_user),
):
    try:
        requested_role = UserRole(payload.role)
    except ValueError:
        raise HTTPException(status_code=422, detail=f"Invalid role: {payload.role}")

    if requested_role not in current_user.granted_roles:
        raise HTTPException(
            status_code=403,
            detail=f"This account does not have the '{requested_role.value}' role.",
        )

    token = create_access_token(current_user, active_role=requested_role)
    return TokenResponse(
        access_token=token,
        role=requested_role.value,
        roles=sorted(r.value for r in current_user.granted_roles),
        user_id=current_user.id,
        name=current_user.name,
        access_status=getattr(current_user, "access_status", "approved") or "approved",
    )


@router.post("/logout", status_code=204,
             summary="Revoke the current JWT (adds jti to blacklist)")
def logout(
    credentials: HTTPAuthorizationCredentials = Depends(_bearer),
    current_user: User = Depends(get_current_user),   # validates token first
    db: Session = Depends(get_db),
):
    payload = decode_token(credentials.credentials)
    jti = payload.get("jti", "")
    if jti:
        revoke_token(db, jti)


@router.get("/me", response_model=UserResponse,
            summary="Return the profile of the currently authenticated user")
def get_me(current_user: User = Depends(get_current_user)):
    return current_user


@router.post("/change-password", status_code=200,
             summary="Change the current user's password (all roles)")
def change_password(
    payload: ChangePasswordRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if not current_user.hashed_password:
        raise HTTPException(
            status_code=400,
            detail="Password change is not available for social-login accounts.",
        )
    if not verify_password(payload.current_password, current_user.hashed_password):
        raise HTTPException(status_code=400, detail="Current password is incorrect.")
    if len(payload.new_password) < 8:
        raise HTTPException(
            status_code=422,
            detail="New password must be at least 8 characters.",
        )
    current_user.hashed_password = hash_password(payload.new_password)
    db.commit()
    return {"message": "Password changed successfully."}


@router.post("/forgot-password", status_code=200,
             summary="Request a 6-digit password reset OTP (all roles)")
def forgot_password(
    payload: ForgotPasswordRequest,
    request: Request,
    db: Session = Depends(get_db),
):
    from hashlib import sha256
    import secrets
    from ..config import settings
    from ..models.platform import PasswordResetToken
    from ..services.email_service import send_password_reset_code
    from ..services import audit_service

    user = get_user_by_email(db, payload.email.strip().lower())
    if user and user.hashed_password:
        cutoff = datetime.now(timezone.utc) - timedelta(minutes=15)
        recent = db.query(PasswordResetToken).filter(PasswordResetToken.user_id == user.id, PasswordResetToken.created_at >= cutoff.replace(tzinfo=None)).count()
        if recent >= 3:
            raise HTTPException(429, "Too many reset requests. Try again later.")
        otp = f"{secrets.randbelow(1_000_000):06d}"
        code_hash = sha256(f"{settings.secret_key}:{otp}".encode()).hexdigest()
        token = PasswordResetToken(user_id=user.id, code_hash=code_hash, expires_at=(datetime.now(timezone.utc) + timedelta(minutes=15)).replace(tzinfo=None), request_ip=request.client.host if request.client else None)
        db.add(token); db.commit()
        try:
            send_password_reset_code(user.email, otp)
        except Exception:
            # Never expose the code or account existence through the response.
            pass
        audit_service.record(db, user.id, "password_reset_requested", entity_type="user", entity_id=user.id, ip_address=request.client.host if request.client else None)
    # Don't reveal whether the email exists.
    return {
        "message": "If this email is registered with a password account, a reset code has been sent.",
        "expires_in_minutes": 15,
    }


@router.post("/verify-reset-code", status_code=200)
def verify_reset_code(payload: VerifyResetCodeRequest, request: Request, db: Session = Depends(get_db)):
    from hashlib import sha256
    from ..config import settings
    from ..models.platform import PasswordResetToken
    from ..services import audit_service

    user = get_user_by_email(db, payload.email.strip().lower())
    if not user:
        raise HTTPException(400, "Invalid or expired reset code.")
    token = db.query(PasswordResetToken).filter(PasswordResetToken.user_id == user.id, PasswordResetToken.consumed_at.is_(None)).order_by(PasswordResetToken.created_at.desc()).first()
    now = datetime.now(timezone.utc).replace(tzinfo=None)
    if not token or token.expires_at < now or token.attempts >= token.max_attempts:
        raise HTTPException(400, "Invalid or expired reset code.")
    token.attempts += 1
    expected = sha256(f"{settings.secret_key}:{payload.otp.strip()}".encode()).hexdigest()
    if not secrets.compare_digest(token.code_hash, expected):
        db.commit()
        raise HTTPException(400, "Invalid or expired reset code.")
    token.verified_at = now
    audit_service.record(db, user.id, "password_reset_code_verified", entity_type="user", entity_id=user.id, ip_address=request.client.host if request.client else None, commit=False)
    db.commit()
    return {"message": "Reset code verified."}


@router.post("/reset-password", status_code=200,
             summary="Reset password using the OTP (all roles)")
def reset_password(
    payload: ResetPasswordRequest,
    request: Request,
    db: Session = Depends(get_db),
):
    from hashlib import sha256
    from ..config import settings
    from ..models.platform import PasswordResetToken
    from ..services import audit_service

    user = get_user_by_email(db, payload.email.strip().lower())
    if not user:
        raise HTTPException(status_code=400, detail="Invalid or expired reset code.")
    token = db.query(PasswordResetToken).filter(PasswordResetToken.user_id == user.id, PasswordResetToken.consumed_at.is_(None)).order_by(PasswordResetToken.created_at.desc()).first()
    now = datetime.now(timezone.utc).replace(tzinfo=None)
    expected = sha256(f"{settings.secret_key}:{payload.otp.strip()}".encode()).hexdigest()
    if not token or not token.verified_at or token.expires_at < now or not secrets.compare_digest(token.code_hash, expected):
        raise HTTPException(status_code=400, detail="Verify a valid reset code before resetting the password.")
    if len(payload.new_password) < 8:
        raise HTTPException(status_code=422, detail="New password must be at least 8 characters.")
    user.hashed_password = hash_password(payload.new_password)
    token.consumed_at = now
    audit_service.record(db, user.id, "password_reset_completed", entity_type="user", entity_id=user.id, ip_address=request.client.host if request.client else None, commit=False)
    db.commit()
    return {"message": "Password reset successfully. You can now sign in with your new password."}


class GoogleLoginRequest(BaseModel):
    id_token: str


@router.post("/google", response_model=TokenResponse,
             summary="Sign in with — verifies the ID token and returns a CareSkill JWT")
def google_login(payload: GoogleLoginRequest, db: Session = Depends(get_db)):
    # Verify the Google ID token using google-auth (verifies JWT signature locally).
    # audience=None skips the aud check so both Android and Web client tokens are accepted;
    # set GOOGLE_CLIENT_ID in .env to restrict to your Web client ID only.
    try:
        id_info = google_id_token.verify_oauth2_token(
            payload.id_token,
            google_requests.Request(),
            audience=settings.google_client_id or None,
            clock_skew_in_seconds=10,
        )
    except (GoogleAuthError, ValueError) as exc:
        logger.warning("Google ID token verification failed: %s", exc)
        raise HTTPException(status_code=401, detail="Invalid Google token") from exc

    email: str = id_info.get("email", "")
    name: str = id_info.get("name") or email.split("@")[0]

    if not email:
        raise HTTPException(status_code=401, detail="Google token missing email")
    if not id_info.get("email_verified"):
        raise HTTPException(status_code=401, detail="Google email is not verified")

    user = get_or_create_google_user(db, email=email, name=name)

    if not user.is_active:
        raise HTTPException(status_code=403, detail="Account is inactive")

    user.last_login_at = datetime.now(timezone.utc)
    db.commit()
    token = create_access_token(user)
    return TokenResponse(
        access_token=token,
        role=user.role.value,
        roles=sorted(r.value for r in user.granted_roles),
        user_id=user.id,
        name=user.name,
    )


class Auth0LoginRequest(BaseModel):
    id_token: str


@router.post("/auth0", response_model=TokenResponse,
             summary="Sign in with Auth0 — verifies the ID token and returns a CareSkill JWT")
def auth0_login(payload: Auth0LoginRequest, db: Session = Depends(get_db)):
    if not settings.auth0_domain or not settings.auth0_client_id:
        raise HTTPException(
            status_code=503,
            detail="AUTH0_DOMAIN and AUTH0_CLIENT_ID must be set in .env first.",
        )
    try:
        id_info = verify_auth0_token(payload.id_token)
    except Exception as exc:
        logger.warning("Auth0 token verification failed: %s", exc)
        raise HTTPException(status_code=401, detail="Invalid Auth0 token") from exc

    email: str = id_info.get("email", "")
    name: str = (
        id_info.get("name")
        or id_info.get("nickname")
        or (email.split("@")[0] if email else "")
    )
    auth0_sub: str = id_info.get("sub", "")

    if not email:
        raise HTTPException(status_code=401, detail="Auth0 token missing email claim")
    if not id_info.get("email_verified", False):
        raise HTTPException(status_code=401, detail="Auth0 email is not verified")

    user = get_or_create_auth0_user(db, email=email, name=name, auth0_sub=auth0_sub)
    if not user.is_active:
        raise HTTPException(status_code=403, detail="Account is inactive")

    user.last_login_at = datetime.now(timezone.utc)
    db.commit()
    token = create_access_token(user)
    return TokenResponse(
        access_token=token,
        role=user.role.value,
        roles=sorted(r.value for r in user.granted_roles),
        user_id=user.id,
        name=user.name,
    )


# ── Google Calendar OAuth2 setup (one-time, admin only) ───────────────────────

@router.get("/google/calendar/status",
            summary="Check if Google Calendar is authorized [admin]")
def calendar_status(
    current_user: User = Depends(require_role(UserRole.admin, UserRole.super_admin)),
):
    authorized = is_calendar_authorized()
    return {
        "authorized": authorized,
        "message": (
            "Google Calendar is connected. Meet links are auto-generated."
            if authorized
            else "Not authorized. Visit /auth/google/calendar/authorize to connect."
        ),
    }


@router.get("/google/calendar/authorize",
            summary="Start Google Calendar OAuth2 consent flow [admin]")
def calendar_authorize(
    current_user: User = Depends(require_role(UserRole.admin, UserRole.super_admin)),
):
    if not settings.google_client_id or not settings.google_client_secret:
        raise HTTPException(
            status_code=503,
            detail="GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET must be set in .env first.",
        )
    url, state = get_authorization_url()
    return {
        "authorization_url": url,
        "instructions": "Open authorization_url in a browser. Sign in with the Google account "
                        "that will host all Meet calls. You will be redirected back automatically.",
    }


@router.get("/google/callback",
            summary="OAuth2 redirect — exchanges code for Calendar tokens (no auth required)",
            include_in_schema=False)
def google_oauth_callback(code: str, state: str):
    try:
        exchange_code_for_tokens(code, state)
    except Exception as exc:
        logger.error("Calendar token exchange failed: %s", exc)
        raise HTTPException(status_code=400, detail=f"Token exchange failed: {exc}") from exc
    return {"message": "Google Calendar authorized successfully. You can close this tab."}
