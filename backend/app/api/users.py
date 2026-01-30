from typing import List, Any
from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from app.api import deps
from app.core import security
from app.core.database import get_db
from app.core.exceptions import MalcomException, NotFoundException, ForbiddenException, BadRequestException
from app.core.logging import get_logger
from app.models.user import User
from app.services.audit import log_action
from app.models.responses import UserResponse, UserCreate, UserUpdate

logger = get_logger(__name__)
router = APIRouter()

@router.get("/me", response_model=UserResponse)
def read_user_me(
    current_user: User = Depends(deps.get_current_user),
):
    """Get current user information"""
    return current_user

@router.get("/", response_model=List[UserResponse])
def read_users(
    db: Session = Depends(get_db),
    skip: int = 0,
    limit: int = 100,
    current_user: User = Depends(deps.get_current_active_admin),
):
    """Retrieve all users (Admin only)"""
    users = db.query(User).offset(skip).limit(limit).all()
    return users

@router.post("/", response_model=UserResponse)
def create_user(
    *,
    db: Session = Depends(get_db),
    user_in: UserCreate,
    current_user: User = Depends(deps.get_root_admin),
):
    """Create a new user (Root Admin only)"""
    user = db.query(User).filter(User.username == user_in.username).first()
    if user:
        raise BadRequestException("El usuario ya existe")
    
    new_user = User(
        username=user_in.username,
        hashed_password=security.get_password_hash(user_in.password),
        is_admin=user_in.is_admin,
        is_active=True
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    
    log_action(db, current_user.id, "CREATE_USER", process_name="USER_MGMT", details=f"Created user: {new_user.username}")
    logger.info(f"User created: {new_user.username} by {current_user.username}")
    
    return new_user

@router.delete("/{user_id}", response_model=UserResponse)
def delete_user(
    *,
    db: Session = Depends(get_db),
    user_id: int,
    current_user: User = Depends(deps.get_root_admin),
):
    """Delete a user (Root Admin only)"""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise NotFoundException("Usuario no encontrado")
    if user.id == current_user.id:
        raise BadRequestException("No puedes eliminarte a ti mismo")
    
    # Protect the root admin user
    if user.username == "admin":
        raise ForbiddenException("No puedes eliminar al usuario administrador del sistema")
    
    username = user.username
    db.delete(user)
    db.commit()
    
    log_action(db, current_user.id, "DELETE_USER", process_name="USER_MGMT", details=f"Deleted user: {username}")
    logger.info(f"User deleted: {username} by {current_user.username}")
    
    return user

@router.patch("/{user_id}", response_model=UserResponse)
def update_user(
    *,
    db: Session = Depends(get_db),
    user_id: int,
    user_in: UserUpdate,
    current_user: User = Depends(deps.get_root_admin),
):
    """Update a user (Root Admin only)"""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise NotFoundException("Usuario no encontrado")
    
    # Protect the root admin user - cannot revoke admin rights or deactivate
    if user.username == "admin":
        if user_in.is_admin is False:
            raise ForbiddenException("No se puede revocar el rol de administrador al usuario admin")
        if user_in.is_active is False:
            raise ForbiddenException("No se puede desactivar al usuario admin")
    
    if user_in.password:
        user.hashed_password = security.get_password_hash(user_in.password)
    if user_in.is_admin is not None:
        user.is_admin = user_in.is_admin
    if user_in.is_active is not None:
        user.is_active = user_in.is_active
        
    db.add(user)
    db.commit()
    db.refresh(user)
    
    log_action(db, current_user.id, "UPDATE_USER", process_name="USER_MGMT", details=f"Updated user: {user.username}")
    logger.info(f"User updated: {user.username} by {current_user.username}")
    
    return user
