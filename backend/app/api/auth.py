from datetime import timedelta, datetime
from typing import Any
from fastapi import APIRouter, Depends, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session

from app.api import deps
from app.core import security
from app.core.config import settings
from app.core.validators import SecurityValidator
from app.core.rate_limiter import RateLimiter
from app.models.user import User
from app.core.database import get_db
from app.models.responses import Token
from app.services.audit import log_action
from app.core.logging import get_logger
from app.core.exceptions import MalcomException, UnauthorizedException

logger = get_logger(__name__)

router = APIRouter()

@router.post("/login/access-token", response_model=Token)
def login_access_token(
    db: Session = Depends(get_db), form_data: OAuth2PasswordRequestForm = Depends()
) -> Any:
    """
    OAuth2 compatible token login, get an access token for future requests
    """
    # Check if account is locked due to too many failed attempts
    if RateLimiter.is_account_locked(form_data.username):
        log_action(db, None, "LOGIN_FAILED", process_name="AUTH", details=f"Account locked: {form_data.username}")
        raise UnauthorizedException("Usuario o contraseña incorrectos")
    
    # Validate input format to prevent injection attacks
    is_valid, error_msg = SecurityValidator.validate_login_input(
        form_data.username, 
        form_data.password
    )
    
    if not is_valid:
        # Log suspicious activity
        RateLimiter.record_failed_attempt(form_data.username)
        log_action(db, None, "LOGIN_FAILED", process_name="AUTH", details=f"Invalid input format from user: {form_data.username}")
        raise UnauthorizedException("Usuario o contraseña incorrectos")
    
    # Query user with parameterized query (SQLAlchemy handles this)
    user = db.query(User).filter(User.username == form_data.username).first()
    
    # Use generic error message to prevent username enumeration
    if not user or not security.verify_password(form_data.password, user.hashed_password):
        # Record failed attempt
        RateLimiter.record_failed_attempt(form_data.username)
        # Log failed login attempt
        log_action(db, None, "LOGIN_FAILED", process_name="AUTH", details=f"Invalid credentials")
        raise UnauthorizedException("Usuario o contraseña incorrectos")
    
    # Clear failed attempts on successful login
    RateLimiter.clear_failed_attempts(form_data.username)

    # Update last login timestamp and mark as online
    user.last_login = datetime.utcnow()
    user.is_online = True
    db.add(user)
    db.commit()
    
    log_action(db, user.id, "LOGIN_SUCCESS", process_name="AUTH", details="User logged in")

    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    return {
        "access_token": security.create_access_token(
            user.username, expires_delta=access_token_expires
        ),
        "token_type": "bearer",
        "is_admin": user.is_admin,
        "username": user.username
    }


@router.post("/logout")
def logout_user(
    current_user: User = Depends(deps.get_current_user),
    db: Session = Depends(get_db),
):
    """Logout current user and mark as offline"""
    current_user.is_online = False
    db.add(current_user)
    db.commit()
    log_action(db, current_user.id, "LOGOUT", process_name="AUTH", details="User logged out")
    return {"detail": "Logged out"}
