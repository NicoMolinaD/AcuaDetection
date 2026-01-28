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
from app.models.responses import RansomwareResponse, RansomwareCreate, RansomwareUpdate

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
    # Check if ransomware with same name already exists
    existing = db.query(Ransomware).filter(Ransomware.name == ransom_in.name).first()
    if existing:
        raise MalcomException(
            f"A ransomware entry with the name '{ransom_in.name}' already exists",
            status_code=status.HTTP_409_CONFLICT
        )
    
    # Validate that at least hashes or domains are present
    if not (ransom_in.hashes or ransom_in.ips or ransom_in.domains):
        raise MalcomException(
            "At least one hash, IP, or domain must be provided",
            status_code=status.HTTP_400_BAD_REQUEST
        )
    
    new_ransom = Ransomware(
        name=ransom_in.name,
        description=ransom_in.description,
        hashes=ransom_in.hashes,
        ips=ransom_in.ips,
        domains=ransom_in.domains,
        severity=ransom_in.severity
    )
    db.add(new_ransom)
    db.commit()
    db.refresh(new_ransom)
    
    log_action(db, current_user.id, "CREATE_RANSOMWARE", process_name="RANSOMWARE", details=f"Added ransomware: {new_ransom.name}")
    logger.info(f"Ransomware entry created: {new_ransom.name} by {current_user.username}")
    
    return new_ransom

@router.put("/{ransomware_id}", response_model=RansomwareResponse)
def update_ransomware(
    *,
    db: Session = Depends(get_db),
    ransomware_id: int,
    ransom_in: RansomwareUpdate,
    current_user: User = Depends(deps.get_current_active_admin),
):
    """Update a ransomware entry (Admin only)"""
    ransom = db.query(Ransomware).filter(Ransomware.id == ransomware_id).first()
    if not ransom:
        raise NotFoundException(f"Ransomware entry with id {ransomware_id} not found")
    
    # Update fields if provided
    if ransom_in.description is not None:
        ransom.description = ransom_in.description
    if ransom_in.hashes is not None:
        ransom.hashes = ransom_in.hashes
    if ransom_in.ips is not None:
        ransom.ips = ransom_in.ips
    if ransom_in.domains is not None:
        ransom.domains = ransom_in.domains
    if ransom_in.severity is not None:
        ransom.severity = ransom_in.severity
    
    db.commit()
    db.refresh(ransom)
    
    log_action(db, current_user.id, "UPDATE_RANSOMWARE", process_name="RANSOMWARE", details=f"Updated ransomware: {ransom.name}")
    logger.info(f"Ransomware entry updated: {ransom.name} by {current_user.username}")
    
    return ransom

@router.delete("/{ransomware_id}")
def delete_ransomware(
    *,
    db: Session = Depends(get_db),
    ransomware_id: int,
    current_user: User = Depends(deps.get_current_active_admin),
):
    """Delete a ransomware entry (Admin only)"""
    ransom = db.query(Ransomware).filter(Ransomware.id == ransomware_id).first()
    if not ransom:
        raise NotFoundException(f"Ransomware entry with id {ransomware_id} not found")
    
    ransom_name = ransom.name
    db.delete(ransom)
    db.commit()
    
    log_action(db, current_user.id, "DELETE_RANSOMWARE", process_name="RANSOMWARE", details=f"Deleted ransomware: {ransom_name}")
    logger.info(f"Ransomware entry deleted: {ransom_name} by {current_user.username}")
    
    return {"message": "Ransomware entry deleted successfully"}
