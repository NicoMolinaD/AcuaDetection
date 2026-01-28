from typing import Generator, Optional
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import jwt, JWTError
from pydantic import ValidationError
from sqlalchemy.orm import Session

from app.core import security
from app.core.config import settings
from app.core.database import get_db
from app.models.user import User

from app.core.exceptions import UnauthorizedException, ForbiddenException, NotFoundException

oauth2_scheme = OAuth2PasswordBearer(tokenUrl=f"{settings.API_V1_STR}/login/access-token")

def get_current_user(
    db: Session = Depends(get_db), token: str = Depends(oauth2_scheme)
) -> User:
    try:
        payload = jwt.decode(
            token, settings.SECRET_KEY, algorithms=[security.ALGORITHM]
        )
        token_data = payload.get("sub")
        if token_data is None:
             raise UnauthorizedException("Could not validate credentials")
    except (JWTError, ValidationError):
        raise UnauthorizedException("Could not validate credentials")
    
    user = db.query(User).filter(User.username == token_data).first()
    if not user:
        raise NotFoundException("User not found")
    return user

def get_current_active_admin(
    current_user: User = Depends(get_current_user),
) -> User:
    if not current_user.is_admin:
        raise ForbiddenException("The user doesn't have enough privileges")
    if not current_user.is_active:
        raise ForbiddenException("The user is inactive")
    return current_user

def get_current_active_user(
    current_user: User = Depends(get_current_user),
) -> User:
    if not current_user.is_active:
        raise ForbiddenException("The user is inactive")
    return current_user
