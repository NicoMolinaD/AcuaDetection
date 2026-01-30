"""
Session timeout service for automatic logout on inactivity.
"""

from datetime import timedelta
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.api import deps
from app.core.database import get_db
from app.models.user import User
from datetime import datetime

router = APIRouter()


@router.post("/heartbeat")
def heartbeat(
    current_user: User = Depends(deps.get_current_user),
    db: Session = Depends(get_db),
):
    """
    Heartbeat endpoint to keep session alive and update last activity time.
    Called periodically by frontend to prevent session timeout.
    """
    current_user.last_login = datetime.utcnow()
    db.add(current_user)
    db.commit()
    return {"status": "ok", "user": current_user.username}
