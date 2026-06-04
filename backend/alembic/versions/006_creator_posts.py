"""Add creator posts.

Revision ID: 006
Revises: 005
Create Date: 2026-06-04
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "006"
down_revision: Union[str, None] = "005"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    conn = op.get_bind()
    tables = [
        row[0]
        for row in conn.execute(
            sa.text("SELECT name FROM sqlite_master WHERE type='table'")
        ).fetchall()
    ]
    if "creator_posts" in tables:
        return

    op.create_table(
        "creator_posts",
        sa.Column("id", sa.Integer(), primary_key=True, index=True),
        sa.Column("post_type", sa.String(), nullable=False),
        sa.Column("title", sa.String(), nullable=False),
        sa.Column("description", sa.Text(), nullable=False),
        sa.Column("category", sa.String(), nullable=False),
        sa.Column("image_url", sa.String(), nullable=True),
        sa.Column(
            "attached_course_id",
            sa.Integer(),
            sa.ForeignKey("courses.id"),
            nullable=True,
        ),
        sa.Column(
            "attached_event_id",
            sa.Integer(),
            sa.ForeignKey("events.id"),
            nullable=True,
        ),
        sa.Column(
            "attached_quiz_id",
            sa.Integer(),
            sa.ForeignKey("quizzes.id"),
            nullable=True,
        ),
        sa.Column(
            "visibility",
            sa.String(),
            nullable=False,
            server_default="all_students",
        ),
        sa.Column("status", sa.String(), nullable=False, server_default="draft"),
        sa.Column("created_by", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("created_at", sa.DateTime(), server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(), server_default=sa.func.now()),
    )
    op.create_index("ix_creator_posts_id", "creator_posts", ["id"])


def downgrade() -> None:
    op.drop_index("ix_creator_posts_id", table_name="creator_posts")
    op.drop_table("creator_posts")
