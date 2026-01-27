from typing import List, Optional, Any
from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from datetime import datetime
from app.api import deps
from app.core.database import get_db
from app.models.ransomware import Ransomware
from app.models.user import User
from app.services.audit import log_action
from app.core.logging import get_logger
from app.core.exceptions import MalcomException, ForbiddenException, NotFoundException
from app.models.responses import RansomwareResponse, RansomwareCreate

logger = get_logger(__name__)
router = APIRouter()

@router.get("/", response_model=List[RansomwareResponse])
def read_ransomware(
    db: Session = Depends(get_db),
    skip: int = 0,
    limit: int = 100,
    current_user: User = Depends(deps.get_current_active_admin),
):
    """Retrieve all ransomware entries"""
    return db.query(Ransomware).offset(skip).limit(limit).all()

@router.post("/", response_model=RansomwareResponse)
def create_ransomware(
    *,
    db: Session = Depends(get_db),
    ransom_in: RansomwareCreate,
    current_user: User = Depends(deps.get_current_active_admin),
):
    """Create a new ransomware entry (Admin only)"""
    # Validate that at least hashes or domains are present
    if not ransom_in.is_valid():
        raise MalcomException(
            "At least one hash or domain must be provided",
            status_code=status.HTTP_400_BAD_REQUEST
        )
    
    new_ransom = Ransomware(
        name=ransom_in.name,
        description=ransom_in.description,
        hashes=ransom_in.hashes,
        ips=ransom_in.ips,
        domains=ransom_in.domains
    )
    db.add(new_ransom)
    db.commit()
    db.refresh(new_ransom)
    
    log_action(db, current_user.id, "CREATE_RANSOMWARE", process_name="RANSOMWARE", details=f"Added ransomware: {new_ransom.name}")
    logger.info(f"Ransomware entry created: {new_ransom.name} by {current_user.username}")
    
    return new_ransom
