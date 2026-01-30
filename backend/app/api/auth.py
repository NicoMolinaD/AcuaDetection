from datetime import timedelta, datetime
from typing import Any
from fastapi import APIRouter, Depends, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session

from app.api import deps
from app.core import security
from app.core.config import settings
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
    user = db.query(User).filter(User.username == form_data.username).first()
    if not user or not security.verify_password(form_data.password, user.hashed_password):
        raise UnauthorizedException("Credenciales incorrectas")
    
    user.last_login = datetime.utcnow()
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
