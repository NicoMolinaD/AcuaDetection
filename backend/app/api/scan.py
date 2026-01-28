from fastapi import APIRouter, Depends, Query
from typing import Optional
from app.models.responses import ScanResponse
from app.services.scan_service import scan_service
from app.core.logging import get_logger
from app.core.exceptions import MalcomException, BadRequestException
from app.api import deps
from app.models.user import User
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.services.audit import log_action

logger = get_logger(__name__)
router = APIRouter()

@router.get("/", response_model=ScanResponse)
async def scan(
    target: str, 
    filename: Optional[str] = None,
    current_user: User = Depends(deps.get_current_user),
    db: Session = Depends(get_db)
):
    """Scan a target (IP, Hash, Domain, URL)"""
    if not target:
        raise BadRequestException("El objetivo es requerido")
        
    result = await scan_service.scan_target(target, filename=filename)
    
    import json
    log_action(db, current_user.id, "SCAN_TARGET", process_name="SCANNER", details=json.dumps(result))

    return result
