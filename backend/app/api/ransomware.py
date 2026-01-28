from typing import List, Optional, Any
from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError
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
    current_user: User = Depends(deps.get_current_active_user),
):
    """Retrieve all ransomware entries - Available for all authenticated users"""
    try:
        entries = db.query(Ransomware).offset(skip).limit(limit).all()
        logger.info(f"Ransomware list retrieved by user {current_user.username}")
        return entries
    except Exception as e:
        logger.error(f"Error retrieving ransomware list: {e}")
        raise MalcomException(
            "Error retrieving ransomware list",
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

@router.post("/", response_model=RansomwareResponse)
def create_ransomware(
    *,
    db: Session = Depends(get_db),
    ransom_in: RansomwareCreate,
    current_user: User = Depends(deps.get_current_active_admin),
):
    """Create a new ransomware entry (Admin only)"""
    try:
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
    
    except IntegrityError as e:
        db.rollback()
        logger.error(f"Integrity error creating ransomware: {e}")
        raise MalcomException(
            f"A ransomware entry with the name '{ransom_in.name}' already exists",
            status_code=status.HTTP_409_CONFLICT
        )
    except MalcomException:
        raise
    except Exception as e:
        db.rollback()
        logger.error(f"Error creating ransomware: {e}")
        raise MalcomException(
            f"Error creating ransomware entry: {str(e)}",
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

@router.put("/{ransomware_id}", response_model=RansomwareResponse)
def update_ransomware(
    *,
    db: Session = Depends(get_db),
    ransomware_id: int,
    ransom_in: RansomwareUpdate,
    current_user: User = Depends(deps.get_current_active_admin),
):
    """Update a ransomware entry (Admin only)"""
    try:
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
    except NotFoundException:
        raise
    except Exception as e:
        db.rollback()
        logger.error(f"Error updating ransomware: {e}")
        raise MalcomException(
            f"Error updating ransomware entry: {str(e)}",
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

@router.delete("/{ransomware_id}")
def delete_ransomware(
    *,
    db: Session = Depends(get_db),
    ransomware_id: int,
    current_user: User = Depends(deps.get_current_active_admin),
):
    """Delete a ransomware entry (Admin only)"""
    try:
        ransom = db.query(Ransomware).filter(Ransomware.id == ransomware_id).first()
        if not ransom:
            raise NotFoundException(f"Ransomware entry with id {ransomware_id} not found")
        
        ransom_name = ransom.name
        db.delete(ransom)
        db.commit()
        
        log_action(db, current_user.id, "DELETE_RANSOMWARE", process_name="RANSOMWARE", details=f"Deleted ransomware: {ransom_name}")
        logger.info(f"Ransomware entry deleted: {ransom_name} by {current_user.username}")
        
        return {"message": "Ransomware entry deleted successfully"}
    except NotFoundException:
        raise
    except Exception as e:
        db.rollback()
        logger.error(f"Error deleting ransomware: {e}")
        raise MalcomException(
            f"Error deleting ransomware entry: {str(e)}",
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

@router.post("/detect/check")
def check_ransomware_iocs(
    *,
    db: Session = Depends(get_db),
    hashes: Optional[List[str]] = None,
    ips: Optional[List[str]] = None,
    domains: Optional[List[str]] = None,
    current_user: User = Depends(deps.get_current_active_user),
):
    """Check if given IOCs match any known ransomware in the database - Available for all users"""
    try:
        matches = []
        
        # Query all ransomware entries
        all_ransomware = db.query(Ransomware).all()
        
        for ransom in all_ransomware:
            detected_indicators = {"type": [], "values": []}
            
            # Check hashes
            if hashes and ransom.hashes:
                for hash_type, hash_values in ransom.hashes.items():
                    for user_hash in hashes:
                        if user_hash.lower() in [h.lower() for h in hash_values]:
                            detected_indicators["type"].append(f"hash_{hash_type}")
                            detected_indicators["values"].append(user_hash)
            
            # Check IPs
            if ips and ransom.ips:
                for ip in ips:
                    if ip in ransom.ips:
                        detected_indicators["type"].append("ip")
                        detected_indicators["values"].append(ip)
            
            # Check domains
            if domains and ransom.domains:
                for domain in domains:
                    if domain.lower() in [d.lower() for d in ransom.domains]:
                        detected_indicators["type"].append("domain")
                        detected_indicators["values"].append(domain)
            
            # If any indicators matched, add to matches
            if detected_indicators["type"]:
                matches.append({
                    "id": ransom.id,
                    "name": ransom.name,
                    "description": ransom.description,
                    "severity": ransom.severity,
                    "detected_indicators": detected_indicators
                })
        
        logger.info(f"Ransomware IOC check performed by {current_user.username}: {len(matches)} matches found")
        return {"matches": matches, "total_matches": len(matches)}
    
    except Exception as e:
        logger.error(f"Error checking ransomware IOCs: {e}")
        raise MalcomException(
            f"Error checking ransomware IOCs: {str(e)}",
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR
        )
