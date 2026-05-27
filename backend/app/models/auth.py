from sqlalchemy import Column, DateTime, Integer, String, func

from ..database import Base


class BlacklistedToken(Base):
    """Stores revoked JWT IDs so logged-out tokens cannot be reused."""
    __tablename__ = "blacklisted_tokens"

    id         = Column(Integer, primary_key=True, index=True)
    jti        = Column(String, unique=True, nullable=False, index=True)
    revoked_at = Column(DateTime, server_default=func.now())
