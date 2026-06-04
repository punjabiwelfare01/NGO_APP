"""Add date of birth to users.

Revision ID: 004
Revises: 003
Create Date: 2026-06-04
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "004"
down_revision: Union[str, None] = "003"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    conn = op.get_bind()
    existing_cols = [
        row[1]
        for row in conn.execute(sa.text("PRAGMA table_info(users)")).fetchall()
    ]
    if "date_of_birth" not in existing_cols:
        with op.batch_alter_table("users") as batch_op:
            batch_op.add_column(sa.Column("date_of_birth", sa.Date(), nullable=True))


def downgrade() -> None:
    with op.batch_alter_table("users") as batch_op:
        batch_op.drop_column("date_of_birth")
