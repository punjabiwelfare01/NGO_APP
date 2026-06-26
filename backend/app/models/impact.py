from sqlalchemy import Boolean, Column, DateTime, Float, ForeignKey, Integer, String, Text, UniqueConstraint, func
from sqlalchemy.orm import relationship

from ..database import Base


class ImpactPost(Base):
    __tablename__ = "impact_posts"

    id = Column(Integer, primary_key=True, index=True)
    category = Column(String, nullable=False, default="achievement")
    title = Column(String, nullable=False)
    description = Column(Text, nullable=False)
    status = Column(String, nullable=False, default="draft")
    event_id = Column(Integer, ForeignKey("events.id"), nullable=True)
    activity_id = Column(Integer, ForeignKey("volunteer_activities.id"), nullable=True)
    certificate_id = Column(Integer, ForeignKey("certificates.id"), nullable=True)
    student_names = Column(Text, nullable=True)
    team_name = Column(String, nullable=True)
    location = Column(String, nullable=True)
    partner_name = Column(String, nullable=True)
    people_reached = Column(Integer, nullable=False, default=0)
    donation_collected = Column(Float, nullable=False, default=0.0)
    hours_served = Column(Float, nullable=False, default=0.0)
    appreciation_count = Column(Integer, nullable=False, default=0)
    share_count = Column(Integer, nullable=False, default=0)
    created_by = Column(Integer, ForeignKey("users.id"), nullable=False)
    approved_by = Column(Integer, ForeignKey("users.id"), nullable=True)
    published_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now())

    media = relationship("ImpactPostMedia", back_populates="post", cascade="all, delete-orphan")
    reactions = relationship("ImpactPostReaction", back_populates="post", cascade="all, delete-orphan")


class ImpactPostMedia(Base):
    __tablename__ = "impact_post_media"

    id = Column(Integer, primary_key=True, index=True)
    post_id = Column(Integer, ForeignKey("impact_posts.id"), nullable=False)
    media_type = Column(String, nullable=False, default="image")
    url = Column(String, nullable=False)
    caption = Column(String, nullable=True)
    position = Column(Integer, nullable=False, default=0)

    post = relationship("ImpactPost", back_populates="media")


class ImpactPostReaction(Base):
    __tablename__ = "impact_post_reactions"
    __table_args__ = (UniqueConstraint("post_id", "user_id"),)

    id = Column(Integer, primary_key=True, index=True)
    post_id = Column(Integer, ForeignKey("impact_posts.id"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    reaction = Column(String, nullable=False, default="appreciate")
    created_at = Column(DateTime, server_default=func.now())

    post = relationship("ImpactPost", back_populates="reactions")
