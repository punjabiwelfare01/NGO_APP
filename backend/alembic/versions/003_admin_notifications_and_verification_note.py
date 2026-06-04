"""Add admin_notifications table and verification_note to users.

Revision ID: 003
Revises: 002
Create Date: 2026-06-04
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "003"
down_revision: Union[str, None] = "002"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Add verification_note to users (skip if already present from create_all)
    conn = op.get_bind()
    existing_cols = [row[1] for row in conn.execute(sa.text("PRAGMA table_info(users)")).fetchall()]
    if "verification_note" not in existing_cols:
        with op.batch_alter_table("users") as batch_op:
            batch_op.add_column(sa.Column("verification_note", sa.String(), nullable=True))

    # Create admin_notifications table only if it doesn't already exist
    tables = [row[0] for row in conn.execute(sa.text("SELECT name FROM sqlite_master WHERE type='table'")).fetchall()]
    if "admin_notifications" not in tables:
        op.create_table(
            "admin_notifications",
            sa.Column("id", sa.Integer(), primary_key=True, index=True),
            sa.Column("title", sa.String(), nullable=False),
            sa.Column("message", sa.String(), nullable=False),
            sa.Column("type", sa.String(), nullable=False, server_default="general"),
            sa.Column("is_read", sa.Boolean(), nullable=False, server_default="0"),
            sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id", ondelete="SET NULL"), nullable=True),
            sa.Column("action_url", sa.String(), nullable=True),
            sa.Column("created_at", sa.DateTime(), server_default=sa.func.now()),
        )

    # Seed notifications for pending users that don't already have one
    op.execute(
        """
        INSERT INTO admin_notifications (title, message, type, is_read, user_id)
        SELECT
            'New User Registration',
            name || ' registered and awaits approval. Requested role: student.',
            'registration',
            0,
            id
        FROM users
        WHERE access_status = 'pending_verification'
          AND id NOT IN (SELECT DISTINCT user_id FROM admin_notifications WHERE user_id IS NOT NULL)
        """
    )


def downgrade() -> None:
    op.drop_table("admin_notifications")
    with op.batch_alter_table("users") as batch_op:
        batch_op.drop_column("verification_note")
