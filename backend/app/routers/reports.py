from datetime import datetime
import json
import secrets

from fastapi import APIRouter, Depends, HTTPException, Request
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session

from ..database import get_db
from ..dependencies import get_download_user, require_role
from ..models.certificate import Certificate, CertificateStatus
from ..models.event import Event
from ..models.platform import EventReportFile
from ..models.user import User, UserRole
from ..models.volunteer import VolunteerActivity, ActivityAssignment, WorkSubmission, SubmissionStatus
from ..schemas.report import EventReportGenerate, EventReportOut, EventReportShareOut
from ..services.file_storage import resolve_stored_file
from ..services.pdf_service import create_text_pdf
from ..services import audit_service, notification_service

router = APIRouter(tags=["Event Reports"])


def _manager(user: User = Depends(require_role(UserRole.event_manager))) -> User:
    return user


def _event(db: Session, event_id: int) -> Event:
    item = db.query(Event).filter(Event.id == event_id).first()
    if not item: raise HTTPException(404, "Event not found")
    return item


def _report(db: Session, event_id: int, report_id: int) -> EventReportFile:
    item = db.query(EventReportFile).filter(EventReportFile.id == report_id, EventReportFile.event_id == event_id).first()
    if not item: raise HTTPException(404, "Event report not found")
    return item


def _report_data(db: Session, event: Event) -> dict:
    activities = db.query(VolunteerActivity).filter(VolunteerActivity.event_id == event.id).all()
    activity_ids = [item.id for item in activities]
    assignments = db.query(ActivityAssignment).filter(ActivityAssignment.activity_id.in_(activity_ids)).all() if activity_ids else []
    assignment_ids = [item.id for item in assignments]
    submissions = db.query(WorkSubmission).filter(WorkSubmission.assignment_id.in_(assignment_ids), WorkSubmission.status == SubmissionStatus.approved).all() if assignment_ids else []
    certificates = db.query(Certificate).filter(Certificate.assignment_id.in_(assignment_ids), Certificate.status == CertificateStatus.issued).all() if assignment_ids else []
    return {
        "event": {"id": event.id, "title": event.title, "type": event.event_type.value, "start": str(event.event_start or event.start_date), "end": str(event.event_end or event.end_date), "created_by": event.created_by},
        "activities": [{"id": item.id, "title": item.title, "location": item.location} for item in activities],
        "assigned_volunteers": len(assignments),
        "approved_submissions": len(submissions),
        "people_reached": sum(item.people_reached for item in submissions),
        "donations_collected": sum(item.donation_collected for item in submissions),
        "hours_served": sum(item.hours_worked for item in submissions),
        "volunteers": [{"student_id": item.student_id, "status": item.status} for item in assignments],
        "submissions": [{"id": item.id, "title": item.title, "people_reached": item.people_reached, "hours": item.hours_worked, "donation": item.donation_collected, "proof_files": item.proof_files} for item in submissions],
        "certificates_issued": len(certificates),
    }


@router.post("/events/{event_id}/reports/generate", response_model=EventReportOut, status_code=201)
def generate(event_id: int, data: EventReportGenerate, request: Request, db: Session = Depends(get_db), user: User = Depends(_manager)):
    event = _event(db, event_id)
    report_data = _report_data(db, event)
    summary = data.summary or f"{event.title} completed with {report_data['approved_submissions']} approved volunteer submissions."
    outcomes = data.outcomes or f"{report_data['people_reached']} people reached; {report_data['hours_served']:g} service hours; ₹{report_data['donations_collected']:g} collected."
    pdf_path = create_text_pdf(f"Event Report: {event.title}", [summary, outcomes, f"Assigned volunteers: {report_data['assigned_volunteers']}", f"Certificates issued: {report_data['certificates_issued']}", f"Generated: {datetime.utcnow().isoformat()} UTC"], "event_reports")
    item = EventReportFile(event_id=event.id, summary=summary, outcomes=outcomes, school_feedback=data.school_feedback, data_json=json.dumps(report_data), pdf_path=pdf_path, public_token=secrets.token_urlsafe(20), impact_post_id=data.impact_post_id, created_by=user.id)
    db.add(item); db.flush()
    audit_service.record(db, user.id, "generate_event_report", entity_type="event_report", entity_id=item.id, commit=False)
    db.commit(); db.refresh(item); return item


@router.get("/events/{event_id}/reports", response_model=list[EventReportOut])
def list_reports(event_id: int, db: Session = Depends(get_db), _: User = Depends(_manager)):
    _event(db, event_id)
    return db.query(EventReportFile).filter(EventReportFile.event_id == event_id).order_by(EventReportFile.created_at.desc()).all()


@router.get("/events/{event_id}/reports/{report_id}", response_model=EventReportOut)
def get_report(event_id: int, report_id: int, db: Session = Depends(get_db), _: User = Depends(_manager)):
    return _report(db, event_id, report_id)


@router.get("/events/{event_id}/reports/{report_id}/download")
def download(event_id: int, report_id: int, db: Session = Depends(get_db), _: User = Depends(get_download_user)):
    item = _report(db, event_id, report_id); path = resolve_stored_file(item.pdf_path, "event_reports")
    if not path: raise HTTPException(404, "Report PDF not found")
    return FileResponse(path, media_type="application/pdf", filename=f"event-{event_id}-report-{report_id}.pdf")


@router.post("/events/{event_id}/reports/{report_id}/share", response_model=EventReportShareOut)
def share(event_id: int, report_id: int, request: Request, db: Session = Depends(get_db), _: User = Depends(_manager)):
    item = _report(db, event_id, report_id)
    return {"report_id": item.id, "public_url": f"{str(request.base_url).rstrip('/')}/public/event-reports/{item.public_token}"}


@router.patch("/events/{event_id}/reports/{report_id}/finalize", response_model=EventReportOut)
def finalize(event_id: int, report_id: int, db: Session = Depends(get_db), user: User = Depends(_manager)):
    item = _report(db, event_id, report_id)
    if item.status == "archived": raise HTTPException(409, "Report is archived")
    item.status = "finalized"; item.finalized_by = user.id; item.finalized_at = datetime.utcnow()
    audit_service.record(db, user.id, "finalize_event_report", entity_type="event_report", entity_id=item.id, commit=False)
    db.commit(); db.refresh(item); return item


@router.get("/public/event-reports/{token}")
def public_report(token: str, db: Session = Depends(get_db)):
    item = db.query(EventReportFile).filter(EventReportFile.public_token == token, EventReportFile.status == "finalized").first()
    if not item: raise HTTPException(404, "Finalized report not found")
    path = resolve_stored_file(item.pdf_path, "event_reports")
    if not path: raise HTTPException(404, "Report PDF not found")
    return FileResponse(path, media_type="application/pdf", filename=f"event-report-{item.id}.pdf")
