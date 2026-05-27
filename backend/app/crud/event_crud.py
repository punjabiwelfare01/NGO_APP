import random
from datetime import datetime, timezone

from sqlalchemy import and_, or_
from sqlalchemy.orm import Session

from ..models.event import (
    Event, EventParticipant, EventQuiz, EventSelection, EventSlot,
    EventStatus, EventType, SelectionMethod,
)
from ..models.quiz import Quiz
from ..models.wellness import CounsellingSession
from ..schemas.event import AttachQuizRequest, EventCreate, EventSlotCreate, EventUpdate, RunSelectionRequest
from ..schemas.quiz import QuizCreate


def _utc_now_naive() -> datetime:
    return datetime.now(timezone.utc).replace(tzinfo=None)


def _as_utc_naive(value: datetime | None) -> datetime | None:
    if value is None:
        return None
    if value.tzinfo is None:
        return value
    return value.astimezone(timezone.utc).replace(tzinfo=None)


def _is_daily_challenge_event(event: Event) -> bool:
    return event.event_type == EventType.daily_challenge or event.is_daily_challenge


def _is_public_status(status: EventStatus) -> bool:
    return status in (
        EventStatus.published,
        EventStatus.registration_open,
        EventStatus.live,
    )


def activate_daily_challenge(db: Session, event: Event) -> None:
    if not _is_daily_challenge_event(event):
        return
    now = _utc_now_naive()
    event.is_daily_challenge = True
    event.status = EventStatus.live
    event.start_date = now
    event.updated_at = now
    db.commit()
    db.refresh(event)


def sync_quiz_mapping(db: Session, event: Event):
    if not event.quiz_id:
        return
    from ..models.event import QuizMapping
    existing = db.query(QuizMapping).filter(QuizMapping.event_id == event.id, QuizMapping.quiz_id == event.quiz_id).first()
    if not existing:
        mapping = QuizMapping(
            event_id=event.id,
            quiz_id=event.quiz_id,
            challenge_type="daily_challenge" if event.event_type == EventType.daily_challenge else "quiz_event",
            sync_status="synced"
        )
        db.add(mapping)
        db.commit()

def sync_daily_challenge(db: Session, event: Event):
    if _is_daily_challenge_event(event) and event.quiz_id:
        ch_date = None
        if event.start_date:
            ch_date = event.start_date.date().isoformat()
        elif event.event_start:
            ch_date = event.event_start.date().isoformat()
        else:
            from datetime import date
            ch_date = date.today().isoformat()
        
        from ..models.quiz import DailyChallenge
        existing = db.query(DailyChallenge).filter(DailyChallenge.challenge_date == ch_date).first()
        if existing:
            existing.quiz_id = event.quiz_id
        else:
            dc = DailyChallenge(quiz_id=event.quiz_id, challenge_date=ch_date)
            db.add(dc)
        db.commit()

def ensure_quiz_pipeline(db: Session, event: Event, quiz_title: str | None, creator_id: int):
    if event.event_type not in (EventType.quiz, EventType.daily_challenge) and not event.is_daily_challenge:
        return
    if not event.quiz_id:
        from ..crud import quiz_crud
        quiz = quiz_crud.create_quiz(
            db,
            QuizCreate(
                title=quiz_title or event.title,
                description=event.description,
                category="Daily Challenge" if event.event_type == EventType.daily_challenge else "Event Quiz",
                difficulty="medium",
                xp_reward=100,
                time_limit_seconds=300,
            ),
            creator_id,
        )
        event.quiz_id = quiz.id
        db.commit()
        db.refresh(event)
    existing_link = (
        db.query(EventQuiz)
        .filter(EventQuiz.event_id == event.id, EventQuiz.quiz_id == event.quiz_id)
        .first()
    )
    if not existing_link:
        db.add(EventQuiz(
            event_id=event.id,
            quiz_title=quiz_title or event.title,
            quiz_id=event.quiz_id,
            is_primary=True,
        ))
        db.commit()

def create_event(db: Session, data: EventCreate, creator_id: int) -> Event:
    payload = data.model_dump(exclude={"quiz_title"})
    if payload.get("event_type") == EventType.daily_challenge or payload.get("is_daily_challenge"):
        payload["is_daily_challenge"] = True
    event = Event(**payload, created_by=creator_id)
    db.add(event)
    db.commit()
    db.refresh(event)
    ensure_quiz_pipeline(db, event, data.quiz_title, creator_id)
    activate_daily_challenge(db, event)
    sync_quiz_mapping(db, event)
    if _is_public_status(event.status):
        sync_daily_challenge(db, event)
    return event


def get_event(db: Session, event_id: int) -> Event | None:
    return db.query(Event).filter(Event.id == event_id).first()


def get_events(
    db: Session,
    status: str | None = None,
    event_type: str | None = None,
    skip: int = 0,
    limit: int = 50,
    public_only: bool = False,
) -> list[Event]:
    q = db.query(Event)
    if public_only:
        q = q.outerjoin(Quiz, Event.quiz_id == Quiz.id).filter(
            Event.status.in_([
                EventStatus.published,
                EventStatus.registration_open,
                EventStatus.live,
            ]),
            or_(
                and_(
                    Event.event_type.notin_([EventType.quiz, EventType.daily_challenge]),
                    Event.is_daily_challenge.is_(False),
                ),
                and_(Event.quiz_id.is_not(None), Quiz.is_active.is_(True)),
            ),
        )
    if status:
        q = q.filter(Event.status == status)
    if event_type:
        q = q.filter(Event.event_type == event_type)
    return q.offset(skip).limit(limit).all()


def update_event(db: Session, event_id: int, data: EventUpdate) -> Event | None:
    event = get_event(db, event_id)
    if not event:
        return None
    payload = data.model_dump(exclude_unset=True, exclude={"quiz_title"})
    for key, value in payload.items():
        setattr(event, key, value)
    event.updated_at = _utc_now_naive()
    db.commit()
    db.refresh(event)
    ensure_quiz_pipeline(db, event, data.quiz_title, event.created_by)
    sync_quiz_mapping(db, event)
    if _is_public_status(event.status):
        sync_daily_challenge(db, event)
    return event


def delete_event(db: Session, event_id: int) -> bool:
    event = get_event(db, event_id)
    if not event:
        return False
    db.delete(event)
    db.commit()
    return True


def publish_event(db: Session, event_id: int) -> Event | None:
    event = get_event(db, event_id)
    if not event:
        return None
    now = _utc_now_naive()
    registration_start = _as_utc_naive(event.registration_start)
    if registration_start and registration_start <= now:
        event.status = EventStatus.registration_open
    else:
        event.status = EventStatus.published
    event.updated_at = now
    db.commit()
    db.refresh(event)
    sync_quiz_mapping(db, event)
    if _is_public_status(event.status):
        sync_daily_challenge(db, event)
    return event


def advance_status(db: Session, event_id: int, new_status: EventStatus) -> Event | None:
    event = get_event(db, event_id)
    if not event:
        return None
    event.status = new_status
    event.updated_at = _utc_now_naive()
    db.commit()
    db.refresh(event)
    if _is_public_status(event.status):
        sync_daily_challenge(db, event)
    return event


def register_participant(db: Session, event_id: int, user_id: int) -> EventParticipant:
    existing = (
        db.query(EventParticipant)
        .filter(EventParticipant.event_id == event_id, EventParticipant.user_id == user_id)
        .first()
    )
    if existing:
        return existing
    participant = EventParticipant(event_id=event_id, user_id=user_id)
    db.add(participant)
    db.commit()
    db.refresh(participant)
    return participant


def create_slot(db: Session, event_id: int, data: EventSlotCreate) -> EventSlot:
    slot = EventSlot(event_id=event_id, **data.model_dump())
    db.add(slot)
    db.commit()
    db.refresh(slot)
    return slot


def get_slots(db: Session, event_id: int) -> list[EventSlot]:
    return (
        db.query(EventSlot)
        .filter(EventSlot.event_id == event_id)
        .order_by(EventSlot.starts_at.asc())
        .all()
    )


def _first_available_slot(db: Session, event_id: int) -> EventSlot | None:
    for slot in get_slots(db, event_id):
        if slot.available_count > 0:
            return slot
    return None


def _sync_counselling_slot_session(
    db: Session,
    event: Event,
    slot: EventSlot,
    user_id: int,
) -> None:
    if event.event_type != EventType.counselling_drive:
        return

    topic = f"{event.title} - {slot.title}"
    existing = (
        db.query(CounsellingSession)
        .filter(
            CounsellingSession.user_id == user_id,
            CounsellingSession.status == "upcoming",
            CounsellingSession.topic == topic,
        )
        .first()
    )
    if existing:
        existing.scheduled_at = slot.starts_at
        existing.counsellor_name = "Event Counsellor"
        existing.notes = f"Booked from counselling drive #{event.id}"
        return

    db.add(
        CounsellingSession(
            user_id=user_id,
            counsellor_name="Event Counsellor",
            topic=topic,
            scheduled_at=slot.starts_at,
            status="upcoming",
            notes=f"Booked from counselling drive #{event.id}",
        )
    )


def book_event_slot(db: Session, event_id: int, user_id: int, slot_id: int | None = None) -> EventParticipant | None:
    event = get_event(db, event_id)
    if not event:
        return None

    slot = None
    if slot_id is not None:
        slot = (
            db.query(EventSlot)
            .filter(EventSlot.id == slot_id, EventSlot.event_id == event_id)
            .first()
        )
    else:
        slot = _first_available_slot(db, event_id)

    if not slot or slot.available_count <= 0:
        return None

    participant = register_participant(db, event_id, user_id)
    if participant.slot_id and participant.slot_id != slot.id:
        return None
    participant.slot_id = slot.id
    participant.status = "slot_booked"
    _sync_counselling_slot_session(db, event, slot, user_id)
    db.commit()
    db.refresh(participant)
    return participant


def get_participants(db: Session, event_id: int) -> list[EventParticipant]:
    return (
        db.query(EventParticipant)
        .filter(EventParticipant.event_id == event_id)
        .all()
    )


def attach_quiz(db: Session, event_id: int, data: AttachQuizRequest) -> EventQuiz:
    quiz = EventQuiz(
        event_id=event_id,
        quiz_title=data.quiz_title,
        quiz_id=data.quiz_id,
        is_primary=data.is_primary,
    )
    db.add(quiz)
    db.commit()
    db.refresh(quiz)
    return quiz


def run_selection(
    db: Session,
    event_id: int,
    admin_id: int,
    request: RunSelectionRequest,
) -> list[EventSelection]:
    event = get_event(db, event_id)
    if not event:
        return []

    eligible_participants = (
        db.query(EventParticipant)
        .filter(
            EventParticipant.event_id == event_id,
            EventParticipant.status.in_(["registered", "shortlisted"]),
        )
        .all()
    )

    method = event.selection_method
    max_count = request.max_count or event.max_selections or len(eligible_participants)

    selected_user_ids: list[int] = []

    if method == SelectionMethod.lucky_draw:
        pool = [p.user_id for p in eligible_participants]
        n = min(max_count, len(pool))
        selected_user_ids = random.sample(pool, n) if n > 0 else []

    elif method == SelectionMethod.manual:
        selected_user_ids = list(request.user_ids or [])

    elif method == SelectionMethod.score_based:
        sorted_participants = sorted(eligible_participants, key=lambda p: p.score, reverse=True)
        selected_user_ids = [p.user_id for p in sorted_participants[:max_count]]

    elif method == SelectionMethod.hybrid:
        pool = [p.user_id for p in eligible_participants]
        n = min(max_count, len(pool))
        drawn = random.sample(pool, n) if n > 0 else []
        override = list(request.user_ids or [])
        # merge: start with override then fill from lucky_draw
        combined = list(dict.fromkeys(override + drawn))
        selected_user_ids = combined[:max_count]

    selected_set = set(selected_user_ids)

    # Update participant statuses
    for participant in eligible_participants:
        participant.status = "selected" if participant.user_id in selected_set else "not_selected"

    # Create EventSelection records
    existing_selection_user_ids = {
        s.user_id
        for s in db.query(EventSelection).filter(EventSelection.event_id == event_id).all()
    }

    new_selections: list[EventSelection] = []
    for uid in selected_user_ids:
        if uid not in existing_selection_user_ids:
            sel = EventSelection(
                event_id=event_id,
                user_id=uid,
                selected_by=admin_id,
                selection_method=method.value,
            )
            db.add(sel)
            new_selections.append(sel)

    # Advance event status to selection
    event.status = EventStatus.selection
    event.updated_at = _utc_now_naive()

    db.commit()
    for sel in new_selections:
        db.refresh(sel)
    return new_selections


def assign_counselling(db: Session, event_id: int) -> int:
    event = get_event(db, event_id)
    if not event:
        return 0

    unassigned_selections = (
        db.query(EventSelection)
        .filter(
            EventSelection.event_id == event_id,
            EventSelection.counselling_assigned.is_(False),
        )
        .all()
    )

    count = 0
    for sel in unassigned_selections:
        session = CounsellingSession(
            user_id=sel.user_id,
            counsellor_name="Event Counsellor",
            topic=f"Post-event counselling for event #{event_id}",
            scheduled_at=event.counselling_date or _utc_now_naive(),
            status="upcoming",
        )
        db.add(session)
        sel.counselling_assigned = True
        count += 1

    if count > 0:
        event.status = EventStatus.completed
        event.updated_at = _utc_now_naive()

    db.commit()
    return count
