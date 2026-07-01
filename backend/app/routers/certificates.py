from typing import List

from datetime import date, datetime

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session

from ..crud import certificate_crud
from ..database import get_db
from ..dependencies import get_current_user, get_download_user, require_role
from ..models.certificate import Certificate, CertificateStatus, CertificateType
from ..models.user import User, UserRole
from ..models.volunteer import ActivityAssignment, WorkSubmission, SubmissionStatus
from ..schemas.certificate import (
    CertificateApprove,
    CertificateApproveReject,
    CertificateCreate,
    CertificateGenerate,
    CertificateOut,
    CertificateRequest,
    CertificateRevoke,
    CertificateUpdate,
    CertificateUpload,
    ImpactStoryFromCertificate,
)
from ..services.file_storage import resolve_stored_file, save_upload
from ..services.pdf_service import create_text_pdf
from ..services import audit_service, notification_service

router = APIRouter(prefix="/certificates", tags=["Certificates"])
admin_router = APIRouter(prefix="/admin/certificates", tags=["Admin Certificates"])
student_router = APIRouter(prefix="/student/certificates", tags=["Student Certificates"])
public_router = APIRouter(prefix="/public/certificates", tags=["Public Certificate Verification"])


def _lookup(db: Session, identifier: str) -> Certificate | None:
    if identifier.isdigit():
        item = certificate_crud.get_certificate(db, int(identifier))
        if item:
            return item
    return certificate_crud.get_certificate_by_public_id(db, identifier)


# ── Generic certificate routes ────────────────────────────────────────────────

@router.post("", response_model=CertificateOut)
def create_certificate(
    data: CertificateCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role(UserRole.admin, UserRole.super_admin)),
):
    item = certificate_crud.create_certificate(db, data, current_user.id)
    return CertificateOut.from_db(item)


@router.get("/me", response_model=List[CertificateOut])
def my_certificates(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    certs = certificate_crud.get_certificates_for_student(db, current_user.id)
    return [CertificateOut.from_db(c) for c in certs]


@router.get("", response_model=List[CertificateOut])
def all_certificates(
    db: Session = Depends(get_db),
    _: User = Depends(require_role(UserRole.admin, UserRole.super_admin)),
):
    certs = certificate_crud.get_all_certificates(db)
    return [CertificateOut.from_db(c) for c in certs]


@router.get("/verify/{token}", response_model=CertificateOut)
def verify_certificate(token: str, db: Session = Depends(get_db)):
    obj = certificate_crud.get_certificate_by_token(db, token)
    if not obj:
        raise HTTPException(404, "Certificate not found or invalid QR token")
    return CertificateOut.from_db(obj)


@router.put("/{cert_id}", response_model=CertificateOut)
def update_certificate(
    cert_id: int,
    data: CertificateUpdate,
    db: Session = Depends(get_db),
    user: User = Depends(require_role(UserRole.admin, UserRole.super_admin, UserRole.event_manager)),
):
    obj = certificate_crud.get_certificate(db, cert_id)
    if not obj:
        raise HTTPException(404, "Certificate not found")
    obj = certificate_crud.update_certificate(db, obj, data)
    audit_service.record(db, user.id, "update_certificate", entity_type="certificate", entity_id=obj.certificate_id)
    return CertificateOut.from_db(obj)


@router.get("/{cert_id}/download")
def admin_download_certificate(
    cert_id: int,
    db: Session = Depends(get_db),
    _: User = Depends(require_role(UserRole.admin, UserRole.super_admin, UserRole.event_manager)),
):
    obj = certificate_crud.get_certificate(db, cert_id)
    if not obj:
        raise HTTPException(404, "Certificate not found")
    path = resolve_stored_file(obj.certificate_file, "certificates")
    if not path:
        raise HTTPException(404, "Certificate PDF not found — generate or upload it first")
    # Mark as downloaded if it was only generated
    if obj.status == CertificateStatus.generated:
        obj.status = CertificateStatus.downloaded
        db.commit()
    return FileResponse(path, media_type="application/pdf", filename=f"{obj.certificate_id}.pdf")


@router.post("/{cert_id}/impact-story", status_code=201)
def create_impact_story_from_certificate(
    cert_id: int,
    data: ImpactStoryFromCertificate,
    db: Session = Depends(get_db),
    user: User = Depends(require_role(UserRole.admin, UserRole.super_admin, UserRole.event_manager)),
):
    from ..repositories import impact_repository
    from ..schemas.impact import ImpactPostCreate, ImpactMediaCreate

    obj = certificate_crud.get_certificate(db, cert_id)
    if not obj:
        raise HTTPException(404, "Certificate not found")
    if obj.impact_story_id:
        raise HTTPException(409, "Impact story already created for this certificate")

    student_name = obj.student.name if obj.student else "Unknown Student"
    title = data.override_title or f"{student_name} — {obj.activity_name}"
    summary = data.override_summary or obj.impact_story_summary or (
        f"{student_name} completed {obj.activity_name}"
        + (f" ({obj.duration})" if obj.duration else "")
        + (f" as part of {obj.program_name}" if obj.program_name else "")
        + "."
    )

    media = []
    # If a pdf_url has been set (e.g., from an upload) include it as media.
    if obj.pdf_url:
        media.append(ImpactMediaCreate(media_type="document", url=obj.pdf_url, caption="Certificate"))

    post_data = ImpactPostCreate(
        category="achievement",
        title=title,
        description=summary,
        event_id=obj.event_id,
        activity_id=obj.activity_id,
        certificate_id=obj.id,
        student_names=student_name,
        hours_served=obj.service_hours or 0,
        media=media,
    )
    post = impact_repository.create_post(db, post_data, user.id)
    obj.impact_story_id = post.id
    db.commit()
    audit_service.record(db, user.id, "create_impact_story_from_cert", entity_type="certificate", entity_id=obj.certificate_id)
    return {"impact_story_id": post.id, "certificate_id": obj.certificate_id}


@router.patch("/{cert_id}/upload", response_model=CertificateOut)
def upload_signed_certificate(
    cert_id: int,
    data: CertificateUpload,
    db: Session = Depends(get_db),
    _: User = Depends(require_role(UserRole.admin, UserRole.super_admin)),
):
    obj = certificate_crud.upload_signed_certificate(db, cert_id, data)
    if not obj:
        raise HTTPException(404, "Certificate not found")
    return CertificateOut.from_db(obj)


@router.get("/{cert_id}", response_model=CertificateOut)
def get_certificate(
    cert_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    obj = certificate_crud.get_certificate(db, cert_id)
    if not obj:
        raise HTTPException(404, "Certificate not found")
    if obj.student_id != current_user.id and current_user.role not in (
        UserRole.admin, UserRole.super_admin
    ):
        raise HTTPException(403, "Access denied")
    return CertificateOut.from_db(obj)


# ── Admin certificate routes ──────────────────────────────────────────────────

@admin_router.get("/ready", response_model=List[dict])
def get_ready_to_generate(
    db: Session = Depends(get_db),
    _: User = Depends(require_role(UserRole.admin, UserRole.super_admin)),
):
    """
    Returns assignments that have an approved submission but no certificate yet.
    Includes both event_manager_verified and admin_approved statuses.
    """
    from sqlalchemy import and_, or_
    from ..models.volunteer import VolunteerActivity
    from ..models.user import User as UserModel
    assignments = (
        db.query(ActivityAssignment)
        .filter(ActivityAssignment.status.in_(["event_manager_verified", "admin_approved"]))
        .all()
    )
    result = []
    for a in assignments:
        existing = db.query(Certificate).filter(Certificate.assignment_id == a.id).first()
        if existing:
            continue
        # Include orphaned submissions (assignment_id=None linked by student+activity)
        sub = (
            db.query(WorkSubmission)
            .filter(
                or_(
                    and_(
                        WorkSubmission.assignment_id == a.id,
                        WorkSubmission.status == SubmissionStatus.approved,
                    ),
                    and_(
                        WorkSubmission.assignment_id.is_(None),
                        WorkSubmission.student_id == a.student_id,
                        WorkSubmission.activity_id == a.activity_id,
                        WorkSubmission.status == SubmissionStatus.approved,
                    ),
                )
            )
            .order_by(WorkSubmission.created_at.desc())
            .first()
        )
        if not sub:
            continue
        student = db.query(UserModel).filter(UserModel.id == a.student_id).first()
        activity = db.query(VolunteerActivity).filter(VolunteerActivity.id == a.activity_id).first()
        result.append({
            "assignment_id": a.id,
            "student_id": a.student_id,
            "student_name": student.name if student else "Unknown",
            "activity_id": a.activity_id,
            "activity_name": activity.title if activity else "Unknown Activity",
            "hours_worked": float(sub.hours_worked) if sub.hours_worked else 0,
            "submission_id": sub.id,
            "submission_title": sub.title,
            "approved_at": sub.created_at.isoformat() if sub.created_at else None,
        })
    return result


@admin_router.get("/pending", response_model=List[CertificateOut])
def get_pending(
    db: Session = Depends(get_db),
    _: User = Depends(require_role(UserRole.admin, UserRole.super_admin, UserRole.event_manager)),
):
    certs = certificate_crud.get_pending_certificates(db)
    return [CertificateOut.from_db(c) for c in certs]


@admin_router.post("/{identifier}/approve", response_model=CertificateOut)
def approve_certificate(
    identifier: str,
    data: CertificateApprove,
    db: Session = Depends(get_db),
    user: User = Depends(require_role(UserRole.admin, UserRole.super_admin)),
):
    item = _lookup(db, identifier)
    if not item:
        raise HTTPException(404, "Certificate not found")
    if item.status not in (CertificateStatus.pending, CertificateStatus.draft):
        raise HTTPException(409, f"Certificate is already {item.status.value}")
    item = certificate_crud.approve_certificate(
        db, item, user.id,
        signatory_name=data.signatory_name,
        signatory_title=data.signatory_title,
    )
    notification_service.notify(
        db, item.student_id, "certificate_approved",
        "Certificate Approved",
        f"Your certificate for {item.activity_name} has been approved. You can now generate and download it.",
        entity_type="certificate", entity_id=item.id, commit=False,
    )
    audit_service.record(db, user.id, "approve_certificate", entity_type="certificate", entity_id=item.certificate_id, commit=False)
    db.commit()
    db.refresh(item)
    return CertificateOut.from_db(item)


@admin_router.post("/{identifier}/reject", response_model=CertificateOut)
def reject_certificate(
    identifier: str,
    data: CertificateApproveReject,
    db: Session = Depends(get_db),
    user: User = Depends(require_role(UserRole.admin, UserRole.super_admin)),
):
    item = _lookup(db, identifier)
    if not item:
        raise HTTPException(404, "Certificate not found")
    item = certificate_crud.reject_certificate(db, item, user.id, data.reason)
    notification_service.notify(
        db, item.student_id, "certificate_rejected",
        "Certificate Request Rejected",
        f"Your certificate request for {item.activity_name} was not approved: {data.reason}",
        entity_type="certificate", entity_id=item.id, commit=False,
    )
    audit_service.record(db, user.id, "reject_certificate", entity_type="certificate", entity_id=item.certificate_id, details={"reason": data.reason}, commit=False)
    db.commit()
    db.refresh(item)
    return CertificateOut.from_db(item)


@admin_router.post("/generate", response_model=CertificateOut, status_code=201)
def generate_certificate(
    data: CertificateGenerate,
    db: Session = Depends(get_db),
    user: User = Depends(require_role(UserRole.admin, UserRole.super_admin)),
):
    from sqlalchemy import and_, or_
    assignment = db.query(ActivityAssignment).filter(ActivityAssignment.id == data.assignment_id).first()
    if not assignment:
        raise HTTPException(404, "Assignment not found")
    # Include orphaned submissions (assignment_id=None) linked by student+activity
    submission = (
        db.query(WorkSubmission)
        .filter(
            or_(
                and_(
                    WorkSubmission.assignment_id == assignment.id,
                    WorkSubmission.status == SubmissionStatus.approved,
                ),
                and_(
                    WorkSubmission.assignment_id.is_(None),
                    WorkSubmission.student_id == assignment.student_id,
                    WorkSubmission.activity_id == assignment.activity_id,
                    WorkSubmission.status == SubmissionStatus.approved,
                ),
            )
        )
        .order_by(WorkSubmission.created_at.desc())
        .first()
    )
    if not submission:
        raise HTTPException(409, "Approved work submission required")
    existing = db.query(Certificate).filter(Certificate.assignment_id == assignment.id).first()
    if existing:
        return CertificateOut.from_db(existing)
    item = certificate_crud.create_certificate(db, CertificateCreate(
        student_id=assignment.student_id,
        activity_id=assignment.activity_id,
        assignment_id=assignment.id,
        submission_id=submission.id,
        certificate_type=CertificateType.volunteer,
        activity_name=assignment.activity.title,
        duration=f"{submission.hours_worked:g} service hours",
        signatory_name=data.signatory_name,
        signatory_title=data.signatory_title,
    ), user.id)
    item.certificate_file = create_text_pdf("Certificate Draft", [item.certificate_id, assignment.student.name, assignment.activity.title, f"Verified service hours: {submission.hours_worked:g}", "Pending authorized signature and stamp"], "certificates")
    item.status = CertificateStatus.approved
    assignment.status = "certificate_generated"
    notification_service.notify(db, assignment.student_id, "certificate_approved", "Certificate Ready", f"Your certificate for {assignment.activity.title} is ready to generate.", entity_type="certificate", entity_id=item.id, commit=False)
    audit_service.record(db, user.id, "generate_certificate", entity_type="certificate", entity_id=item.certificate_id, commit=False)
    db.commit()
    db.refresh(item)
    return CertificateOut.from_db(item)


@admin_router.post("/{identifier}/upload-signed", response_model=CertificateOut)
async def upload_signed(
    identifier: str,
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    user: User = Depends(require_role(UserRole.admin, UserRole.super_admin)),
):
    item = _lookup(db, identifier)
    if not item:
        raise HTTPException(404, "Certificate not found")
    if file.content_type != "application/pdf" and not file.filename.lower().endswith(".pdf"):
        raise HTTPException(400, "Signed certificate must be a PDF")
    content = await file.read()
    if not content.startswith(b"%PDF"):
        raise HTTPException(400, "Invalid PDF file")
    item.certificate_file = save_upload("certificates", file.filename, content)
    item.status = CertificateStatus.issued
    item.issue_date = date.today()
    item.is_verified = True
    item.issued_by = user.id
    assignment = db.query(ActivityAssignment).filter(ActivityAssignment.id == item.assignment_id).first() if item.assignment_id else None
    if assignment:
        assignment.status = "completed"
    notification_service.notify(db, item.student_id, "certificate_issued", "Certificate issued", f"Your certificate {item.certificate_id} is ready to view and download.", action_url=f"/student/certificates/{item.id}", entity_type="certificate", entity_id=item.id, commit=False)
    audit_service.record(db, user.id, "upload_signed_certificate", entity_type="certificate", entity_id=item.certificate_id, commit=False)
    db.commit()
    db.refresh(item)
    return CertificateOut.from_db(item)


@admin_router.patch("/{identifier}/revoke", response_model=CertificateOut)
def revoke(
    identifier: str,
    data: CertificateRevoke,
    db: Session = Depends(get_db),
    user: User = Depends(require_role(UserRole.admin, UserRole.super_admin)),
):
    item = _lookup(db, identifier)
    if not item:
        raise HTTPException(404, "Certificate not found")
    item.status = CertificateStatus.revoked
    item.is_verified = False
    item.revoked_by = user.id
    item.revoked_at = datetime.utcnow()
    item.revoke_reason = data.reason
    notification_service.notify(db, item.student_id, "certificate_revoked", "Certificate revoked", data.reason, entity_type="certificate", entity_id=item.id, commit=False)
    audit_service.record(db, user.id, "revoke_certificate", entity_type="certificate", entity_id=item.certificate_id, details={"reason": data.reason}, commit=False)
    db.commit()
    db.refresh(item)
    return CertificateOut.from_db(item)


# ── Student certificate routes ────────────────────────────────────────────────

@student_router.post("/request", response_model=CertificateOut, status_code=201)
def request_certificate(
    data: CertificateRequest,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    item = certificate_crud.request_certificate(db, data, user.id)
    notification_service.notify(
        db, user.id, "certificate_requested",
        "Certificate Request Submitted",
        f"Your certificate request for {data.activity_name} has been submitted and is pending admin approval.",
        entity_type="certificate", entity_id=item.id, commit=True,
    )
    return CertificateOut.from_db(item)


@student_router.get("", response_model=List[CertificateOut])
def student_certificates(db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    certs = certificate_crud.get_certificates_for_student(db, user.id)
    return [CertificateOut.from_db(c) for c in certs]


@student_router.get("/{identifier}", response_model=CertificateOut)
def student_certificate(identifier: str, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    item = _lookup(db, identifier)
    if not item or item.student_id != user.id:
        raise HTTPException(404, "Certificate not found")
    return CertificateOut.from_db(item)


@student_router.patch("/{identifier}/mark-generated", response_model=CertificateOut)
def mark_generated(
    identifier: str,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    item = _lookup(db, identifier)
    if not item or item.student_id != user.id:
        raise HTTPException(404, "Certificate not found")
    if item.status != CertificateStatus.approved:
        raise HTTPException(409, "Certificate must be approved before generating PDF")
    item = certificate_crud.mark_generated(db, item)
    return CertificateOut.from_db(item)


@student_router.get("/{identifier}/download")
def download_certificate(identifier: str, db: Session = Depends(get_db), user: User = Depends(get_download_user)):
    item = _lookup(db, identifier)
    if not item or item.student_id != user.id:
        raise HTTPException(404, "Certificate not found")
    if item.status not in (CertificateStatus.issued, CertificateStatus.generated):
        raise HTTPException(409, "Certificate PDF is not available yet")
    path = resolve_stored_file(item.certificate_file, "certificates")
    if not path:
        raise HTTPException(404, "Certificate PDF not found on server")
    return FileResponse(path, media_type="application/pdf", filename=f"{item.certificate_id}.pdf")


# ── Public verification route ─────────────────────────────────────────────────

@public_router.get("/verify/{token}", response_model=CertificateOut)
def public_verify(token: str, db: Session = Depends(get_db)):
    item = certificate_crud.get_certificate_by_token(db, token)
    if not item or item.status == CertificateStatus.revoked or not item.is_verified:
        raise HTTPException(404, "Certificate is invalid, unavailable, or revoked")
    return CertificateOut.from_db(item)
