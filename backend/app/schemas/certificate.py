from __future__ import annotations

from datetime import date, datetime
from typing import Optional

from pydantic import BaseModel

from ..models.certificate import CertificateType, CertificateStatus


class CertificateCreate(BaseModel):
    student_id: int
    event_id: Optional[int] = None
    activity_id: Optional[int] = None
    assignment_id: Optional[int] = None
    submission_id: Optional[int] = None
    certificate_type: CertificateType
    activity_name: str
    duration: Optional[str] = None
    signatory_name: Optional[str] = None
    signatory_title: Optional[str] = None
    issue_date: Optional[date] = None


class CertificateRequest(BaseModel):
    certificate_type: CertificateType
    activity_name: str
    event_id: Optional[int] = None
    duration: Optional[str] = None
    notes: Optional[str] = None


class CertificateApprove(BaseModel):
    signatory_name: Optional[str] = None
    signatory_title: Optional[str] = None


class CertificateApproveReject(BaseModel):
    reason: str


class CertificateUpload(BaseModel):
    certificate_file: str
    status: CertificateStatus = CertificateStatus.signed


class CertificateOut(BaseModel):
    id: int
    certificate_id: str
    student_id: int
    student_name: Optional[str] = None
    event_id: Optional[int]
    activity_id: Optional[int]
    assignment_id: Optional[int]
    submission_id: Optional[int]
    certificate_type: CertificateType
    activity_name: str
    duration: Optional[str]
    signatory_name: Optional[str]
    signatory_title: Optional[str]
    issue_date: Optional[date]
    certificate_file: Optional[str]
    status: CertificateStatus
    is_verified: bool
    qr_token: Optional[str]
    issued_by: Optional[int]
    revoked_by: Optional[int]
    revoked_at: Optional[datetime]
    revoke_reason: Optional[str]
    rejection_reason: Optional[str] = None
    created_at: Optional[datetime]

    model_config = {"from_attributes": True}

    @classmethod
    def from_db(cls, cert) -> "CertificateOut":
        obj = cls.model_validate(cert)
        if hasattr(cert, "student") and cert.student:
            obj.student_name = cert.student.name
        return obj


class CertificateGenerate(BaseModel):
    assignment_id: int
    signatory_name: Optional[str] = None
    signatory_title: Optional[str] = None


class CertificateRevoke(BaseModel):
    reason: str
