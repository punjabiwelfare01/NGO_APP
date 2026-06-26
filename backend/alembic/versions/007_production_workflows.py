"""Add production student work and impact persistence.

Revision ID: 007
Revises: 006
Create Date: 2026-06-21
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "007"
down_revision: Union[str, None] = "006"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    with op.batch_alter_table("volunteer_activities") as batch:
        batch.add_column(sa.Column("event_id", sa.Integer(), nullable=True))
        batch.add_column(sa.Column("location", sa.String(), nullable=True))
        batch.add_column(sa.Column("duration", sa.String(), nullable=True))
        batch.add_column(sa.Column("application_deadline", sa.DateTime(), nullable=True))
        batch.add_column(sa.Column("max_students", sa.Integer(), nullable=True))
        batch.add_column(sa.Column("certificate_eligible", sa.Boolean(), nullable=False, server_default=sa.true()))
        batch.add_column(sa.Column("stipend_amount", sa.Float(), nullable=True))
        batch.create_foreign_key("fk_volunteer_activity_event", "events", ["event_id"], ["id"])

    op.create_table(
        "activity_applications",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("student_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("activity_id", sa.Integer(), sa.ForeignKey("volunteer_activities.id"), nullable=False),
        sa.Column("status", sa.String(), nullable=False, server_default="applied"),
        sa.Column("note", sa.String(), nullable=True),
        sa.Column("applied_at", sa.DateTime(), server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(), server_default=sa.func.now()),
        sa.UniqueConstraint("student_id", "activity_id"),
    )
    op.create_index("ix_activity_applications_id", "activity_applications", ["id"])

    op.create_table(
        "impact_posts",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("category", sa.String(), nullable=False, server_default="achievement"),
        sa.Column("title", sa.String(), nullable=False),
        sa.Column("description", sa.Text(), nullable=False),
        sa.Column("status", sa.String(), nullable=False, server_default="draft"),
        sa.Column("event_id", sa.Integer(), sa.ForeignKey("events.id"), nullable=True),
        sa.Column("activity_id", sa.Integer(), sa.ForeignKey("volunteer_activities.id"), nullable=True),
        sa.Column("certificate_id", sa.Integer(), sa.ForeignKey("certificates.id"), nullable=True),
        sa.Column("student_names", sa.Text(), nullable=True),
        sa.Column("team_name", sa.String(), nullable=True),
        sa.Column("location", sa.String(), nullable=True),
        sa.Column("partner_name", sa.String(), nullable=True),
        sa.Column("people_reached", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("donation_collected", sa.Float(), nullable=False, server_default="0"),
        sa.Column("hours_served", sa.Float(), nullable=False, server_default="0"),
        sa.Column("appreciation_count", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("share_count", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("created_by", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("approved_by", sa.Integer(), sa.ForeignKey("users.id"), nullable=True),
        sa.Column("published_at", sa.DateTime(), nullable=True),
        sa.Column("created_at", sa.DateTime(), server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(), server_default=sa.func.now()),
    )
    op.create_index("ix_impact_posts_id", "impact_posts", ["id"])
    op.create_table(
        "impact_post_media",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("post_id", sa.Integer(), sa.ForeignKey("impact_posts.id"), nullable=False),
        sa.Column("media_type", sa.String(), nullable=False, server_default="image"),
        sa.Column("url", sa.String(), nullable=False),
        sa.Column("caption", sa.String(), nullable=True),
        sa.Column("position", sa.Integer(), nullable=False, server_default="0"),
    )
    op.create_table(
        "impact_post_reactions",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("post_id", sa.Integer(), sa.ForeignKey("impact_posts.id"), nullable=False),
        sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("reaction", sa.String(), nullable=False, server_default="appreciate"),
        sa.Column("created_at", sa.DateTime(), server_default=sa.func.now()),
        sa.UniqueConstraint("post_id", "user_id"),
    )


def downgrade() -> None:
    op.drop_table("impact_post_reactions")
    op.drop_table("impact_post_media")
    op.drop_index("ix_impact_posts_id", table_name="impact_posts")
    op.drop_table("impact_posts")
    op.drop_index("ix_activity_applications_id", table_name="activity_applications")
    op.drop_table("activity_applications")
    with op.batch_alter_table("volunteer_activities") as batch:
        for column in ("stipend_amount", "certificate_eligible", "max_students", "application_deadline", "duration", "location", "event_id"):
            batch.drop_column(column)
