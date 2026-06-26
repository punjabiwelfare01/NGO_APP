"""Normalize pending access requests and repair provisional student accounts.

Revision ID: 009
Revises: 008
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "009"
down_revision: Union[str, None] = "008"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.execute(sa.text("""
        UPDATE users
        SET access_status = 'pending'
        WHERE access_status IN (
            'pending_verification', 'pending_review', 'under_review'
        )
    """))
    op.execute(sa.text("""
        UPDATE users
        SET access_status = 'pending'
        WHERE access_status = 'approved'
          AND role = 'student'
          AND requested_role IS NOT NULL
          AND requested_role NOT IN ('', 'student')
    """))


def downgrade() -> None:
    op.execute(sa.text("""
        UPDATE users
        SET access_status = 'pending_verification'
        WHERE access_status = 'pending'
    """))
