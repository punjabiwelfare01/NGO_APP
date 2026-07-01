from __future__ import annotations

import secrets
from datetime import date
from typing import List, Optional

from sqlalchemy.orm import Session

from ..models.certificate import Certificate, CertificateStatus, CertificateType
from ..schemas.certificate import CertificateCreate, CertificateRequest, CertificateUpdate, CertificateUpload


def _generate_cert_id(db: Session) -> str:
    year = date.today().year
    count = db.query(Certificate).count() + 1
    return f"NGO-CERT-{year}-{count:04d}"


def create_certificate(db: Session, data: CertificateCreate, issuer_id: int) -> Certificate:
    obj = Certificate(
        **data.model_dump(),
        certificate_id=_generate_cert_id(db),
        qr_token=secrets.token_urlsafe(16),
        issued_by=issuer_id,
    )
    db.add(obj)
    db.commit()
    db.refresh(obj)
    return obj


def request_certificate(db: Session, data: CertificateRequest, student_id: int) -> Certificate:
    obj = Certificate(
        student_id=student_id,
        event_id=data.event_id,
        certificate_type=data.certificate_type,
        activity_name=data.activity_name,
        duration=data.duration,
        certificate_id=_generate_cert_id(db),
        qr_token=secrets.token_urlsafe(16),
        status=CertificateStatus.pending,
    )
    db.add(obj)
    db.commit()
    db.refresh(obj)
    return obj


def approve_certificate(
    db: Session,
    cert: Certificate,
    approver_id: int,
    signatory_name: Optional[str] = None,
    signatory_title: Optional[str] = None,
) -> Certificate:
    cert.status = CertificateStatus.approved
    cert.issued_by = approver_id
    cert.issue_date = cert.issue_date or date.today()
    cert.is_verified = True
    if signatory_name:
        cert.signatory_name = signatory_name
    if signatory_title:
        cert.signatory_title = signatory_title
    db.commit()
    db.refresh(cert)
    return cert


def reject_certificate(db: Session, cert: Certificate, approver_id: int, reason: str) -> Certificate:
    cert.status = CertificateStatus.rejected
    cert.rejection_reason = reason
    cert.issued_by = approver_id
    db.commit()
    db.refresh(cert)
    return cert


def mark_generated(db: Session, cert: Certificate) -> Certificate:
    if cert.status == CertificateStatus.approved:
        cert.status = CertificateStatus.generated
        db.commit()
        db.refresh(cert)
    return cert


def get_certificates_for_student(db: Session, student_id: int) -> List[Certificate]:
    return (
        db.query(Certificate)
        .filter(Certificate.student_id == student_id)
        .order_by(Certificate.created_at.desc())
        .all()
    )


def get_pending_certificates(db: Session) -> List[Certificate]:
    return (
        db.query(Certificate)
        .filter(Certificate.status == CertificateStatus.pending)
        .order_by(Certificate.created_at.desc())
        .all()
    )


def get_all_certificates(db: Session) -> List[Certificate]:
    return db.query(Certificate).order_by(Certificate.created_at.desc()).all()


def get_certificate(db: Session, cert_id: int) -> Optional[Certificate]:
    return db.query(Certificate).filter(Certificate.id == cert_id).first()


def get_certificate_by_public_id(db: Session, certificate_id: str) -> Optional[Certificate]:
    return db.query(Certificate).filter(Certificate.certificate_id == certificate_id).first()


def get_certificate_by_token(db: Session, token: str) -> Optional[Certificate]:
    return db.query(Certificate).filter(Certificate.qr_token == token).first()


def update_certificate(db: Session, cert: Certificate, data: CertificateUpdate) -> Certificate:
    for field, value in data.model_dump(exclude_none=True).items():
        setattr(cert, field, value)
    db.commit()
    db.refresh(cert)
    return cert


def upload_signed_certificate(db: Session, cert_id: int, data: CertificateUpload) -> Optional[Certificate]:
    obj = get_certificate(db, cert_id)
    if not obj:
        return None
    obj.certificate_file = data.certificate_file
    obj.status = data.status
    if data.status in (CertificateStatus.signed, CertificateStatus.issued):
        obj.status = CertificateStatus.issued
        obj.is_verified = True
        obj.issue_date = obj.issue_date or date.today()
    db.commit()
    db.refresh(obj)
    return obj
