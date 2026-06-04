from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from ..database import get_db
from ..dependencies import get_current_user
from ..models.calendar import StudentReminder
from ..models.event import Event, EventStatus, EventType
from ..models.user import User
from ..models.wellness import CounsellingSession
from ..schemas.calendar import (
    CalendarItemResponse,
    ReminderCreate,
    ReminderResponse,
    ReminderUpdate,
)

router = APIRouter(prefix="/calendar", tags=["Calendar"])


def _event_datetime(event: Event):
    return (
        event.event_start
        or event.start_date
        or event.counselling_date
        or event.result_date
        or event.registration_start
    )


def _event_end(event: Event):
    return event.event_end or event.end_date or event.registration_end


def _event_type_label(event: Event) -> str:
    if event.event_type == EventType.quiz:
        return "quiz"
    if event.event_type == EventType.workshop:
        return "workshop"
    if event.event_type == EventType.counselling_drive:
        return "counselling"
    return "event"


def _event_subtitle(event: Event) -> str | None:
    if event.subtitle:
        return event.subtitle
    return event.event_type.value.replace("_", " ").title()


@router.get("/me", response_model=list[CalendarItemResponse],
            summary="Get the current student's calendar feed")
def get_my_calendar(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    items: list[CalendarItemResponse] = []

    visible_statuses = (
        EventStatus.published,
        EventStatus.registration_open,
        EventStatus.live,
        EventStatus.evaluation,
        EventStatus.selection,
    )
    events = (
        db.query(Event)
        .filter(Event.status.in_(visible_statuses))
        .all()
    )
    for event in events:
        starts_at = _event_datetime(event)
        if starts_at is None:
            continue
        items.append(
            CalendarItemResponse(
                id=f"event-{event.id}",
                source_id=event.id,
                item_type=_event_type_label(event),
                title=event.title,
                subtitle=_event_subtitle(event),
                starts_at=starts_at,
                ends_at=_event_end(event),
                status=event.status.value,
                color_hex=event.theme_color,
            )
        )

    sessions = (
        db.query(CounsellingSession)
        .filter(CounsellingSession.user_id == current_user.id)
        .all()
    )
    for session in sessions:
        items.append(
            CalendarItemResponse(
                id=f"counselling-{session.id}",
                source_id=session.id,
                item_type="counselling",
                title="Counselling Session",
                subtitle=f"Mentor: {session.counsellor_name}",
                starts_at=session.scheduled_at,
                ends_at=session.ends_at,
                status=session.status,
                action_url=session.meeting_url,
                color_hex="#8B5CF6",
            )
        )

    reminders = (
        db.query(StudentReminder)
        .filter(
            StudentReminder.user_id == current_user.id,
            StudentReminder.is_active == True,
        )
        .all()
    )
    for reminder in reminders:
        items.append(
            CalendarItemResponse(
                id=f"reminder-{reminder.id}",
                source_id=reminder.id,
                item_type="reminder",
                title=reminder.title,
                starts_at=reminder.scheduled_at,
                status="done" if reminder.is_done else "upcoming",
                color_hex="#FF9800",
                is_done=reminder.is_done,
            )
        )

    return sorted(items, key=lambda item: item.starts_at)


@router.post("/reminders", response_model=ReminderResponse, status_code=201,
             summary="Create a student reminder")
def create_reminder(
    payload: ReminderCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    reminder = StudentReminder(
        user_id=current_user.id,
        title=payload.title,
        scheduled_at=payload.scheduled_at,
    )
    db.add(reminder)
    db.commit()
    db.refresh(reminder)
    return reminder


@router.patch("/reminders/{reminder_id}", response_model=ReminderResponse,
              summary="Update a student reminder")
def update_reminder(
    reminder_id: int,
    payload: ReminderUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    reminder = (
        db.query(StudentReminder)
        .filter(
            StudentReminder.id == reminder_id,
            StudentReminder.user_id == current_user.id,
        )
        .first()
    )
    if reminder is None:
        raise HTTPException(status_code=404, detail="Reminder not found")
    for key, value in payload.model_dump(exclude_unset=True).items():
        setattr(reminder, key, value)
    db.commit()
    db.refresh(reminder)
    return reminder
