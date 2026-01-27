from typing import List
from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from datetime import datetime
from app.api import deps
from app.core.database import get_db
from app.models.audit_log import AuditLog
from app.models.user import User
from app.core.logging import get_logger
from app.core.exceptions import MalcomException, ForbiddenException
from app.models.responses import AuditLogResponse

logger = get_logger(__name__)
router = APIRouter()

@router.get("/", response_model=List[AuditLogResponse])
def read_logs(
    db: Session = Depends(get_db),
    skip: int = 0,
    limit: int = 100,
    current_user: User = Depends(deps.get_current_active_admin),
):
    """Retrieve all system audit logs (Admin only)"""
    logger.info(f"Admin {current_user.username} is viewing system logs")
    logs = db.query(AuditLog, User.username).outerjoin(User, AuditLog.user_id == User.id).order_by(AuditLog.timestamp.desc()).offset(skip).limit(limit).all()
    return [
        {
            **log[0].__dict__,
            'username': log[1]
        }
        for log in logs
    ]

@router.get("/me", response_model=List[AuditLogResponse])
def read_user_logs(
    db: Session = Depends(get_db),
    skip: int = 0,
    limit: int = 100,
    current_user: User = Depends(deps.get_current_user),
):
    """Retrieve audit logs for the current user"""
    logger.info(f"User {current_user.username} is viewing their own logs")
    logs = db.query(AuditLog, User.username).outerjoin(User, AuditLog.user_id == User.id).filter(AuditLog.user_id == current_user.id).order_by(AuditLog.timestamp.desc()).offset(skip).limit(limit).all()
    return [
        {
            **log[0].__dict__,
            'username': log[1]
        }
        for log in logs
    ]

@router.delete("/me")
def delete_user_logs(
    db: Session = Depends(get_db),
    current_user: User = Depends(deps.get_current_user),
):
    """Delete all audit logs for the current user"""
    logger.info(f"User {current_user.username} is deleting their own logs")
    db.query(AuditLog).filter(AuditLog.user_id == current_user.id).delete()
    db.commit()
    return {"message": "User logs deleted successfully"}

@router.delete("/")
def delete_all_logs(
    db: Session = Depends(get_db),
    current_user: User = Depends(deps.get_current_active_admin),
):
    """Delete all system audit logs (Admin only)"""
    logger.info(f"Admin {current_user.username} is deleting all system logs")
    db.query(AuditLog).delete()
    db.commit()
    return {"message": "All system logs deleted successfully"}
