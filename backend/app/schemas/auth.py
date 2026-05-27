from typing import Optional

from pydantic import BaseModel

from ..models.user import UserRole


class RegisterRequest(BaseModel):
    name: str
    email: str
    password: str
    age: int
    role: UserRole = UserRole.student
    parent_email: Optional[str] = None


class LoginRequest(BaseModel):
    email: str
    password: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    role: str
    user_id: int
    name: str


class TokenData(BaseModel):
    sub: str    # user_id as string
    role: str
    jti: str
