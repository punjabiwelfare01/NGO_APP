from sqlalchemy.orm import Session

from ..models.platform import Notification, NotificationPreference


def notify(
    db: Session,
    user_id: int,
    notification_type: str,
    title: str,
    message: str,
    *,
    action_url: str | None = None,
    entity_type: str | None = None,
    entity_id: int | None = None,
    commit: bool = True,
) -> Notification:
    preference = db.query(NotificationPreference).filter(NotificationPreference.user_id == user_id).first()
    if preference and not preference.in_app_enabled:
        return None
    item = Notification(
        user_id=user_id,
        type=notification_type,
        title=title,
        message=message,
        action_url=action_url,
        entity_type=entity_type,
        entity_id=entity_id,
    )
    db.add(item)
    if commit:
        db.commit()
        db.refresh(item)
    return item
