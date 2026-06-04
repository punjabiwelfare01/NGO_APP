"""Add profile fields and make age nullable on users table.

Revision ID: 002
Revises: 001
Create Date: 2026-06-04
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "002"
down_revision: Union[str, None] = "001"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    with op.batch_alter_table("users") as batch_op:
        batch_op.alter_column("age", existing_type=sa.Integer(), nullable=True)
        batch_op.add_column(sa.Column("access_status", sa.String(), nullable=False, server_default="pending_verification"))
        batch_op.add_column(sa.Column("class_name", sa.String(), nullable=True))
        batch_op.add_column(sa.Column("school_name", sa.String(), nullable=True))
        batch_op.add_column(sa.Column("location", sa.String(), nullable=True))
        batch_op.add_column(sa.Column("phone", sa.String(), nullable=True))
        batch_op.add_column(sa.Column("requested_role", sa.String(), nullable=True))


def downgrade() -> None:
    with op.batch_alter_table("users") as batch_op:
        batch_op.drop_column("requested_role")
        batch_op.drop_column("phone")
        batch_op.drop_column("location")
        batch_op.drop_column("school_name")
        batch_op.drop_column("class_name")
        batch_op.drop_column("access_status")
        batch_op.alter_column("age", existing_type=sa.Integer(), nullable=False)
