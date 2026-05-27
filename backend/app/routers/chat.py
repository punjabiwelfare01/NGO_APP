"""
WebSocket chat between a student and their mentor.

Room key  : (mentor_user_id, student_user_id)  – 1-to-1, private.
WS URL    : /ws/chat/{other_user_id}?token=<jwt>
            Caller supplies the other person's user-id.
            Server resolves mentor/student from their roles.

REST:
  GET /chat/{other_user_id}/history       – last 60 messages
  GET /chat/conversations                 – all conversations for current user
"""

import logging
from collections import defaultdict

from fastapi import APIRouter, Depends, HTTPException, Query, WebSocket, WebSocketDisconnect
from sqlalchemy.orm import Session

from ..crud.auth_crud import decode_token, is_token_revoked
from ..crud import chat_crud
from ..database import get_db
from ..dependencies import get_current_user
from ..models.user import User, UserRole
from ..schemas.chat import ChatMessageResponse, ConversationSummary

logger = logging.getLogger(__name__)

router = APIRouter(tags=["Chat"])

# ── Connection manager ─────────────────────────────────────────────────────────

class _ConnectionManager:
    def __init__(self):
        # room_key → list of WebSocket
        self._rooms: dict[tuple[int, int], list[WebSocket]] = defaultdict(list)

    @staticmethod
    def _key(mentor_id: int, student_id: int) -> tuple[int, int]:
        return (mentor_id, student_id)

    async def connect(self, ws: WebSocket, mentor_id: int, student_id: int) -> None:
        await ws.accept()
        self._rooms[self._key(mentor_id, student_id)].append(ws)

    def disconnect(self, ws: WebSocket, mentor_id: int, student_id: int) -> None:
        key = self._key(mentor_id, student_id)
        self._rooms[key] = [w for w in self._rooms[key] if w is not ws]

    async def broadcast(self, mentor_id: int, student_id: int, data: dict) -> None:
        key = self._key(mentor_id, student_id)
        dead: list[WebSocket] = []
        for ws in list(self._rooms[key]):
            try:
                await ws.send_json(data)
            except Exception:
                dead.append(ws)
        for ws in dead:
            self.disconnect(ws, mentor_id, student_id)


_manager = _ConnectionManager()


# ── Helpers ────────────────────────────────────────────────────────────────────

def _resolve_room(current: User, other: User) -> tuple[int, int]:
    """Return (mentor_user_id, student_user_id) regardless of who calls whom."""
    mentor_roles = {UserRole.mentor, UserRole.admin, UserRole.super_admin}
    if current.role in mentor_roles:
        return current.id, other.id
    if other.role in mentor_roles:
        return other.id, current.id
    raise HTTPException(400, "One participant must be a mentor.")


def _auth_ws(token: str, db: Session) -> User:
    """Authenticate a WebSocket request from a JWT query param."""
    try:
        payload = decode_token(token)
        user_id = int(payload["sub"])
        jti = payload.get("jti", "")
    except Exception:
        return None  # type: ignore[return-value]
    if is_token_revoked(db, jti):
        return None  # type: ignore[return-value]
    return db.query(User).filter(User.id == user_id, User.is_active.is_(True)).first()


# ── WebSocket endpoint ─────────────────────────────────────────────────────────

@router.websocket("/ws/chat/{other_user_id}")
async def chat_ws(
    ws: WebSocket,
    other_user_id: int,
    token: str = Query(...),
    db: Session = Depends(get_db),
):
    current = _auth_ws(token, db)
    if not current:
        await ws.close(code=4001, reason="Unauthorized")
        return

    other = db.query(User).filter(User.id == other_user_id, User.is_active.is_(True)).first()
    if not other:
        await ws.close(code=4004, reason="Other user not found")
        return

    try:
        mentor_id, student_id = _resolve_room(current, other)
    except HTTPException:
        await ws.close(code=4003, reason="Room requires one mentor")
        return

    await _manager.connect(ws, mentor_id, student_id)
    logger.info("WS connect  user=%s room=(%s,%s)", current.id, mentor_id, student_id)

    # Send history on connect
    history = chat_crud.get_history(db, mentor_id, student_id)
    await ws.send_json({
        "type": "history",
        "messages": [chat_crud.message_to_dict(m) for m in history],
    })

    try:
        while True:
            data = await ws.receive_json()
            content = (data.get("content") or "").strip()
            if not content:
                continue
            msg = chat_crud.save_message(
                db, mentor_id=mentor_id, student_id=student_id,
                sender_id=current.id, content=content,
            )
            await _manager.broadcast(mentor_id, student_id, {
                "type": "message",
                **chat_crud.message_to_dict(msg),
            })
    except WebSocketDisconnect:
        _manager.disconnect(ws, mentor_id, student_id)
        logger.info("WS disconnect user=%s room=(%s,%s)", current.id, mentor_id, student_id)
    except Exception as exc:
        logger.exception("WS error user=%s: %s", current.id, exc)
        _manager.disconnect(ws, mentor_id, student_id)


# ── REST: history ──────────────────────────────────────────────────────────────

@router.get("/chat/{other_user_id}/history", response_model=list[ChatMessageResponse])
def get_history(
    other_user_id: int,
    db: Session = Depends(get_db),
    current: User = Depends(get_current_user),
):
    other = db.query(User).filter(User.id == other_user_id).first()
    if not other:
        raise HTTPException(404, "User not found")
    mentor_id, student_id = _resolve_room(current, other)
    messages = chat_crud.get_history(db, mentor_id, student_id)
    return [
        ChatMessageResponse(
            id=m.id,
            mentor_id=m.mentor_id,
            student_id=m.student_id,
            sender_id=m.sender_id,
            sender_name=m.sender.name,
            sender_role=m.sender.role.value,
            content=m.content,
            created_at=m.created_at,
        )
        for m in messages
    ]


# ── REST: conversations list ───────────────────────────────────────────────────

@router.get("/chat/conversations", response_model=list[ConversationSummary])
def get_conversations(
    db: Session = Depends(get_db),
    current: User = Depends(get_current_user),
):
    mentor_roles = {UserRole.mentor, UserRole.admin, UserRole.super_admin}
    if current.role in mentor_roles:
        messages = chat_crud.get_mentor_conversations(db, current.id)
        return [
            ConversationSummary(
                other_user_id=m.student_id,
                other_user_name=m.student.name,
                other_user_role=m.student.role.value,
                last_message=m.content,
                last_message_at=m.created_at,
                mentor_id=m.mentor_id,
                student_id=m.student_id,
            )
            for m in messages
        ]
    else:
        messages = chat_crud.get_student_conversations(db, current.id)
        return [
            ConversationSummary(
                other_user_id=m.mentor_id,
                other_user_name=m.mentor.name,
                other_user_role=m.mentor.role.value,
                last_message=m.content,
                last_message_at=m.created_at,
                mentor_id=m.mentor_id,
                student_id=m.student_id,
            )
            for m in messages
        ]
