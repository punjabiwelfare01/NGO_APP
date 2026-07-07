import json

from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.orm import Session

from ..database import get_db
from ..dependencies import get_current_user, require_role
from ..models.platform import Announcement, AppSetting, BankSetting, NGOProfileSetting, RolePermissionSetting, AdminAuditLog
from ..models.user import User, UserRole
from ..permissions import ROLE_PERMISSIONS
from ..schemas.platform import AnnouncementCreate, AnnouncementOut, AnnouncementUpdate, AppSettingsData, AuditLogOut, BankData, NGOProfileData, PermissionData
from ..services import audit_service, notification_service

router = APIRouter(prefix="/admin", tags=["Admin Settings"])


def _admin(user: User = Depends(require_role(UserRole.admin))) -> User:
    return user


def _ip(request: Request) -> str | None:
    return request.client.host if request.client else None


@router.get("/settings/ngo-profile/public", response_model=NGOProfileData)
def get_ngo_profile_public(db: Session = Depends(get_db), _: User = Depends(get_current_user)):
    """Any authenticated user can fetch NGO branding for certificate display."""
    item = db.query(NGOProfileSetting).first()
    return item if item else NGOProfileData()


@router.get("/settings/ngo-profile", response_model=NGOProfileData)
def get_ngo_profile(db: Session = Depends(get_db), _: User = Depends(_admin)):
    item = db.query(NGOProfileSetting).first()
    return item if item else NGOProfileData()


@router.patch("/settings/ngo-profile", response_model=NGOProfileData)
def update_ngo_profile(data: NGOProfileData, request: Request, db: Session = Depends(get_db), user: User = Depends(_admin)):
    item = db.query(NGOProfileSetting).first() or NGOProfileSetting()
    for key, value in data.model_dump().items(): setattr(item, key, value)
    item.updated_by = user.id
    db.add(item)
    audit_service.record(db, user.id, "update_ngo_profile", entity_type="ngo_profile", details=data.model_dump(), ip_address=_ip(request), commit=False)
    db.commit(); db.refresh(item)
    return item


@router.get("/settings/bank/public", response_model=BankData)
def get_bank_public(db: Session = Depends(get_db), _: User = Depends(get_current_user)):
    """Any authenticated user can fetch the official donation account details."""
    item = db.query(BankSetting).first()
    return item if item else BankData()


@router.get("/settings/bank", response_model=BankData)
def get_bank(db: Session = Depends(get_db), _: User = Depends(_admin)):
    item = db.query(BankSetting).first()
    return item if item else BankData()


@router.patch("/settings/bank", response_model=BankData)
def update_bank(data: BankData, request: Request, db: Session = Depends(get_db), user: User = Depends(_admin)):
    if data.confirmation != "CONFIRM":
        raise HTTPException(400, "Set confirmation to CONFIRM for bank changes")
    item = db.query(BankSetting).first() or BankSetting()
    values = data.model_dump(exclude={"confirmation"})
    for key, value in values.items(): setattr(item, key, value)
    item.updated_by = user.id
    db.add(item)
    audit_service.record(db, user.id, "update_bank_settings", entity_type="bank_settings", details={"changed_fields": list(values)}, ip_address=_ip(request), commit=False)
    db.commit(); db.refresh(item)
    return item


@router.get("/roles")
def roles(_: User = Depends(_admin)):
    return [{"role": role.value, "permissions": sorted(permission.value for permission in ROLE_PERMISSIONS.get(role, []))} for role in UserRole]


@router.get("/roles/{role}/permissions", response_model=PermissionData)
def role_permissions(role: UserRole, db: Session = Depends(get_db), _: User = Depends(_admin)):
    item = db.query(RolePermissionSetting).filter(RolePermissionSetting.role == role.value).first()
    permissions = json.loads(item.permissions_json) if item else sorted(p.value for p in ROLE_PERMISSIONS.get(role, []))
    return {"permissions": permissions}


@router.patch("/roles/{role}/permissions", response_model=PermissionData)
def update_permissions(role: UserRole, data: PermissionData, request: Request, db: Session = Depends(get_db), user: User = Depends(_admin)):
    item = db.query(RolePermissionSetting).filter(RolePermissionSetting.role == role.value).first() or RolePermissionSetting(role=role.value)
    item.permissions_json = json.dumps(sorted(set(data.permissions))); item.updated_by = user.id; db.add(item)
    audit_service.record(db, user.id, "update_role_permissions", entity_type="role", entity_id=role.value, details=data.model_dump(), ip_address=_ip(request), commit=False)
    db.commit()
    return {"permissions": json.loads(item.permissions_json)}


@router.get("/audit-logs", response_model=list[AuditLogOut])
def audit_logs(limit: int = 100, db: Session = Depends(get_db), _: User = Depends(_admin)):
    return db.query(AdminAuditLog).order_by(AdminAuditLog.created_at.desc()).limit(min(limit, 500)).all()


@router.post("/announcements", response_model=AnnouncementOut, status_code=201)
def create_announcement(data: AnnouncementCreate, request: Request, db: Session = Depends(get_db), user: User = Depends(_admin)):
    item = Announcement(**data.model_dump(), created_by=user.id); db.add(item); db.flush()
    users = db.query(User).filter(User.is_active.is_(True))
    if data.audience_role: users = users.filter(User.role == UserRole(data.audience_role))
    for target in users.all(): notification_service.notify(db, target.id, "admin_announcement", data.title, data.message, entity_type="announcement", entity_id=item.id, commit=False)
    audit_service.record(db, user.id, "create_announcement", entity_type="announcement", entity_id=item.id, ip_address=_ip(request), commit=False)
    db.commit(); db.refresh(item)
    return item


@router.get("/announcements", response_model=list[AnnouncementOut])
def announcements(db: Session = Depends(get_db), _: User = Depends(_admin)):
    return db.query(Announcement).order_by(Announcement.created_at.desc()).all()


@router.patch("/announcements/{announcement_id}", response_model=AnnouncementOut)
def update_announcement(announcement_id: int, data: AnnouncementUpdate, request: Request, db: Session = Depends(get_db), user: User = Depends(_admin)):
    item = db.query(Announcement).filter(Announcement.id == announcement_id).first()
    if not item: raise HTTPException(404, "Announcement not found")
    for key, value in data.model_dump(exclude_none=True).items(): setattr(item, key, value)
    audit_service.record(db, user.id, "update_announcement", entity_type="announcement", entity_id=item.id, ip_address=_ip(request), commit=False)
    db.commit(); db.refresh(item); return item


@router.delete("/announcements/{announcement_id}", status_code=204)
def delete_announcement(announcement_id: int, request: Request, db: Session = Depends(get_db), user: User = Depends(_admin)):
    item = db.query(Announcement).filter(Announcement.id == announcement_id).first()
    if not item: raise HTTPException(404, "Announcement not found")
    db.delete(item); audit_service.record(db, user.id, "delete_announcement", entity_type="announcement", entity_id=announcement_id, ip_address=_ip(request), commit=False); db.commit()


@router.get("/app-settings", response_model=AppSettingsData)
def app_settings(db: Session = Depends(get_db), _: User = Depends(_admin)):
    return {"values": {item.key: json.loads(item.value) if item.value else None for item in db.query(AppSetting).all()}}


@router.patch("/app-settings", response_model=AppSettingsData)
def update_app_settings(data: AppSettingsData, request: Request, db: Session = Depends(get_db), user: User = Depends(_admin)):
    for key, value in data.values.items():
        item = db.query(AppSetting).filter(AppSetting.key == key).first() or AppSetting(key=key)
        item.value = json.dumps(value); item.updated_by = user.id; db.add(item)
    audit_service.record(db, user.id, "update_app_settings", entity_type="app_settings", details={"keys": list(data.values)}, ip_address=_ip(request), commit=False)
    db.commit(); return app_settings(db, user)
