"""Add user_roles table (multi-role grants) and backfill from the existing
role + secondary_role columns.

Revision ID: 015
Revises: 014
Create Date: 2026-07-07
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "015"
down_revision: Union[str, None] = "014"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)

    if "user_roles" not in inspector.get_table_names():
        op.create_table(
            "user_roles",
            sa.Column("id", sa.Integer(), primary_key=True, index=True),
            sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False, index=True),
            sa.Column("role", sa.String(), nullable=False),
            sa.Column("granted_by", sa.Integer(), sa.ForeignKey("users.id"), nullable=True),
            sa.Column("granted_at", sa.DateTime(), server_default=sa.func.now()),
            sa.Column("status", sa.String(), nullable=False, server_default="active"),
            sa.UniqueConstraint("user_id", "role", name="uq_user_role"),
        )

    # Backfill: every existing user gets a grant row for their primary role,
    # plus one for secondary_role if they had one set. Uses lightweight
    # table() reflection rather than the live ORM models, per Alembic
    # convention (models can change shape after this migration is written).
    users = sa.table(
        "users",
        sa.column("id", sa.Integer),
        sa.column("role", sa.String),
        sa.column("secondary_role", sa.String),
        sa.column("created_at", sa.DateTime),
    )
    user_roles = sa.table(
        "user_roles",
        sa.column("user_id", sa.Integer),
        sa.column("role", sa.String),
        sa.column("granted_at", sa.DateTime),
        sa.column("status", sa.String),
    )

    existing_grants = {
        (row.user_id, row.role)
        for row in bind.execute(sa.select(user_roles.c.user_id, user_roles.c.role))
    }
    rows_to_insert = []
    for row in bind.execute(sa.select(
        users.c.id, users.c.role, users.c.secondary_role, users.c.created_at,
    )):
        if row.role and (row.id, row.role) not in existing_grants:
            rows_to_insert.append({
                "user_id": row.id, "role": row.role,
                "granted_at": row.created_at, "status": "active",
            })
        if row.secondary_role and (row.id, row.secondary_role) not in existing_grants:
            rows_to_insert.append({
                "user_id": row.id, "role": row.secondary_role,
                "granted_at": row.created_at, "status": "active",
            })

    if rows_to_insert:
        op.bulk_insert(user_roles, rows_to_insert)


def downgrade() -> None:
    op.drop_table("user_roles")
