import json

from sqlalchemy.orm import Session

from ..models.platform import AdminAuditLog


def record(db: Session, actor_id: int, action: str, *, entity_type: str | None = None, entity_id: str | int | None = None, details: dict | None = None, ip_address: str | None = None, commit: bool = True):
    item = AdminAuditLog(
        actor_id=actor_id,
        action=action,
        entity_type=entity_type,
        entity_id=str(entity_id) if entity_id is not None else None,
        details_json=json.dumps(details or {}),
        ip_address=ip_address,
    )
    db.add(item)
    if commit:
        db.commit()
        db.refresh(item)
    return item
