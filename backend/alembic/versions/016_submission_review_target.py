"""Add review_target to work_submissions — routes each submission to
either the event manager who owns the activity, or the admin queue, so the
two review queues no longer show every submission to both.

Backfills existing rows from the activity's creator role: if the creator is
an event_manager, existing submissions route there; everything else
(including activities with no creator, or a non-event-manager creator)
keeps the "admin" default set on the new column.

Revision ID: 016
Revises: 015
Create Date: 2026-07-07
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "016"
down_revision: Union[str, None] = "015"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    columns = {c["name"] for c in inspector.get_columns("work_submissions")}

    if "review_target" not in columns:
        op.add_column(
            "work_submissions",
            sa.Column("review_target", sa.String(), nullable=False, server_default="admin"),
        )

    submissions = sa.table(
        "work_submissions",
        sa.column("id", sa.Integer),
        sa.column("activity_id", sa.Integer),
        sa.column("review_target", sa.String),
    )
    activities = sa.table(
        "volunteer_activities",
        sa.column("id", sa.Integer),
        sa.column("created_by", sa.Integer),
    )
    users = sa.table(
        "users",
        sa.column("id", sa.Integer),
        sa.column("role", sa.String),
    )

    creator_roles = dict(
        bind.execute(
            sa.select(activities.c.id, users.c.role)
            .select_from(activities.join(users, users.c.id == activities.c.created_by))
        ).all()
    )
    em_activity_ids = {
        activity_id for activity_id, role in creator_roles.items() if role == "event_manager"
    }
    if em_activity_ids:
        op.execute(
            submissions.update()
            .where(submissions.c.activity_id.in_(em_activity_ids))
            .values(review_target="event_manager")
        )


def downgrade() -> None:
    op.drop_column("work_submissions", "review_target")
