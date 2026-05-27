from sqlalchemy import or_, and_
from sqlalchemy.orm import Session

from ..models.chat import ChatMessage
from ..models.user import User


def _room(mentor_id: int, student_id: int):
    return and_(
        ChatMessage.mentor_id == mentor_id,
        ChatMessage.student_id == student_id,
    )


def get_history(
    db: Session, mentor_id: int, student_id: int, limit: int = 60
) -> list[ChatMessage]:
    return (
        db.query(ChatMessage)
        .filter(_room(mentor_id, student_id))
        .order_by(ChatMessage.created_at.asc())
        .limit(limit)
        .all()
    )


def save_message(
    db: Session, mentor_id: int, student_id: int, sender_id: int, content: str
) -> ChatMessage:
    msg = ChatMessage(
        mentor_id=mentor_id,
        student_id=student_id,
        sender_id=sender_id,
        content=content,
    )
    db.add(msg)
    db.commit()
    db.refresh(msg)
    return msg


def get_mentor_conversations(db: Session, mentor_user_id: int) -> list[ChatMessage]:
    """Return the latest message per student for a given mentor."""
    from sqlalchemy import func as sqlfunc

    subq = (
        db.query(
            ChatMessage.student_id,
            sqlfunc.max(ChatMessage.id).label("max_id"),
        )
        .filter(ChatMessage.mentor_id == mentor_user_id)
        .group_by(ChatMessage.student_id)
        .subquery()
    )
    return (
        db.query(ChatMessage)
        .join(subq, ChatMessage.id == subq.c.max_id)
        .order_by(ChatMessage.created_at.desc())
        .all()
    )


def get_student_conversations(db: Session, student_id: int) -> list[ChatMessage]:
    """Return the latest message per mentor for a given student."""
    from sqlalchemy import func as sqlfunc

    subq = (
        db.query(
            ChatMessage.mentor_id,
            sqlfunc.max(ChatMessage.id).label("max_id"),
        )
        .filter(ChatMessage.student_id == student_id)
        .group_by(ChatMessage.mentor_id)
        .subquery()
    )
    return (
        db.query(ChatMessage)
        .join(subq, ChatMessage.id == subq.c.max_id)
        .order_by(ChatMessage.created_at.desc())
        .all()
    )


def message_to_dict(msg: ChatMessage) -> dict:
    return {
        "id": msg.id,
        "mentor_id": msg.mentor_id,
        "student_id": msg.student_id,
        "sender_id": msg.sender_id,
        "sender_name": msg.sender.name if msg.sender else "Unknown",
        "sender_role": msg.sender.role.value if msg.sender else "student",
        "content": msg.content,
        "created_at": msg.created_at.isoformat(),
    }
