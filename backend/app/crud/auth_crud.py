import json
import uuid
from datetime import datetime, timedelta, timezone

from jose import jwt
from passlib.context import CryptContext
from sqlalchemy.orm import Session

from ..config import settings
from ..models.auth import BlacklistedToken
from ..models.notification import AdminNotification
from ..models.user import User, UserRole
from ..schemas.auth import RegisterRequest

_pwd = CryptContext(schemes=["bcrypt"], deprecated="auto")


# ── password helpers ──────────────────────────────────────────────────────────

def hash_password(plain: str) -> str:
    return _pwd.hash(plain)


def verify_password(plain: str, hashed: str) -> bool:
    return _pwd.verify(plain, hashed)


# ── JWT helpers ───────────────────────────────────────────────────────────────

def create_access_token(user: User) -> str:
    expire = datetime.now(timezone.utc) + timedelta(
        minutes=settings.access_token_expire_minutes
    )
    payload = {
        "sub": str(user.id),
        "role": user.role.value,
        "name": user.name,
        "jti": str(uuid.uuid4()),   # unique token ID — used for revocation
        "exp": expire,
    }
    return jwt.encode(payload, settings.secret_key, algorithm=settings.jwt_algorithm)


def decode_token(token: str) -> dict:
    return jwt.decode(
        token,
        settings.secret_key,
        algorithms=[settings.jwt_algorithm],
    )


# ── token blacklist ───────────────────────────────────────────────────────────

def revoke_token(db: Session, jti: str) -> None:
    if not db.query(BlacklistedToken).filter(BlacklistedToken.jti == jti).first():
        db.add(BlacklistedToken(jti=jti))
        db.commit()


def is_token_revoked(db: Session, jti: str) -> bool:
    return (
        db.query(BlacklistedToken).filter(BlacklistedToken.jti == jti).first()
        is not None
    )


# ── user lookup / creation ────────────────────────────────────────────────────

def get_user_by_email(db: Session, email: str) -> User | None:
    return db.query(User).filter(User.email == email).first()


def get_or_create_google_user(db: Session, email: str, name: str) -> User:
    """Find an existing user by email or create a new student account for Google sign-in."""
    user = get_user_by_email(db, email)
    if user:
        return user
    user = User(
        name=name,
        email=email,
        hashed_password=None,
        age=13,
        role=UserRole.student,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


def get_or_create_auth0_user(db: Session, email: str, name: str, auth0_sub: str) -> User:
    """Find an existing user by email or create a new student account for Auth0 sign-in."""
    user = get_user_by_email(db, email)
    if user:
        return user
    user = User(
        name=name,
        email=email,
        hashed_password=None,   # no password — Auth0-only account
        age=13,                  # default; user can update in profile
        role=UserRole.student,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


def _requested_role(value: str | None) -> str:
    normalized = (value or "student").strip().lower().replace(" ", "_")
    return "mentor" if normalized == "counsellor" else normalized


def register_user(
    db: Session,
    data: RegisterRequest,
    *,
    pending_access: bool = False,
) -> User:
    requested_role = _requested_role(data.requested_role)
    user = User(
        name=data.name,
        email=data.email,
        hashed_password=hash_password(data.password),
        age=data.age,
        date_of_birth=data.date_of_birth,
        # Public requests receive no dashboard access until an admin assigns
        # the final role. Internal seeds/tests may still create approved roles.
        role=UserRole.student if pending_access else data.role,
        access_status="pending" if pending_access else "approved",
        parent_email=data.parent_email,
        class_name=data.class_name,
        school_name=data.school_name,
        location=data.location,
        phone=data.phone,
        requested_role=requested_role if pending_access else data.requested_role,
        interests=json.dumps(data.interests) if data.interests else None,
    )
    db.add(user)
    db.flush()
    if pending_access:
        db.add(AdminNotification(
            title="New access request",
            message=f"{user.name} requested {requested_role} access.",
            type="new_access_request",
            user_id=user.id,
            action_url=f"/admin/users/{user.id}",
        ))
    db.commit()
    db.refresh(user)
    return user
