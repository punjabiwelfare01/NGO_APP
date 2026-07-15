from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from ..database import get_db
from ..dependencies import get_current_user
from ..models.certificate import Certificate
from ..models.donation import Donation
from ..models.event import Event, EventParticipant
from ..models.platform import NotificationPreference, UserSetting
from ..models.user import User
from ..models.volunteer import WorkSubmission
from ..schemas.platform import ProfileReportOut, UserSettingsOut, UserSettingsUpdate

router = APIRouter(tags=["Profile"])


def _settings(db: Session, user_id: int):
    setting = db.query(UserSetting).filter(UserSetting.user_id == user_id).first()
    if not setting:
        setting = UserSetting(user_id=user_id)
        db.add(setting)
    preference = db.query(NotificationPreference).filter(NotificationPreference.user_id == user_id).first()
    if not preference:
        preference = NotificationPreference(user_id=user_id)
        db.add(preference)
    db.commit()
    db.refresh(setting)
    db.refresh(preference)
    return setting, preference


@router.get("/settings/me", response_model=UserSettingsOut)
def get_settings(db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    setting, preference = _settings(db, user.id)
    return {**{key: getattr(setting, key) for key in ("language", "profile_visibility", "show_impact_name", "data_download_enabled")}, **{key: getattr(preference, key) for key in ("in_app_enabled", "email_enabled", "event_reminders", "counselling_reminders", "assignment_updates", "impact_updates")}}


@router.patch("/settings/me", response_model=UserSettingsOut)
def update_settings(data: UserSettingsUpdate, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    setting, preference = _settings(db, user.id)
    values = data.model_dump(exclude_none=True)
    for key, value in values.items():
        target = setting if hasattr(setting, key) else preference
        setattr(target, key, value)
    db.commit()
    return get_settings(db, user)


def _reports(db: Session, user_id: int) -> list[dict]:
    reports: list[dict] = []
    for item in db.query(WorkSubmission).filter(WorkSubmission.student_id == user_id).all():
        reports.append({"id": f"work-{item.id}", "type": "work", "title": item.title, "status": item.status.value if hasattr(item.status, "value") else item.status, "summary": f"{item.hours_worked:g} hours · {item.people_reached} people reached", "created_at": item.created_at, "details": {"activity_id": item.activity_id, "assignment_id": item.assignment_id, "donation_collected": item.donation_collected, "reviewer_notes": item.reviewer_notes}})
    for item in db.query(Donation).filter(Donation.student_id == user_id).all():
        reports.append({"id": f"donation-{item.id}", "type": "donation", "title": "Donation report", "status": item.status.value if hasattr(item.status, "value") else item.status, "summary": f"₹{item.amount:g}", "created_at": item.created_at, "details": {"transaction_id": item.transaction_id, "purpose": item.purpose}})
    for item in db.query(Certificate).filter(Certificate.student_id == user_id).all():
        reports.append({"id": f"certificate-{item.id}", "type": "certificate", "title": item.activity_name, "status": item.status.value if hasattr(item.status, "value") else item.status, "summary": item.certificate_id, "created_at": item.created_at, "details": {"certificate_id": item.certificate_id, "issue_date": str(item.issue_date) if item.issue_date else None}})
    participants = db.query(EventParticipant).filter(EventParticipant.user_id == user_id).all()
    event_ids = {item.event_id for item in participants}
    events_by_id = {e.id: e for e in (db.query(Event).filter(Event.id.in_(event_ids)).all() if event_ids else [])}
    for item in participants:
        event = events_by_id.get(item.event_id)
        reports.append({"id": f"event-{item.id}", "type": "event", "title": event.title if event else "Event", "status": item.status, "summary": "Event participation", "created_at": item.registered_at, "details": {"event_id": item.event_id, "score": item.score}})
    return sorted(reports, key=lambda item: item["created_at"] or "", reverse=True)


@router.get("/profile/reports", response_model=list[ProfileReportOut])
def profile_reports(db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    return _reports(db, user.id)


@router.get("/profile/reports/{report_id}", response_model=ProfileReportOut)
def profile_report(report_id: str, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    item = next((report for report in _reports(db, user.id) if report["id"] == report_id), None)
    if not item:
        raise HTTPException(404, "Report not found")
    return item
