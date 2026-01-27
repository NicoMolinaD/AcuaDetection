from pydantic import BaseModel, EmailStr
from typing import List, Optional, Any
from datetime import datetime

class Token(BaseModel):
    access_token: str
    token_type: str
    is_admin: bool
    username: str

class TokenData(BaseModel):
    username: Optional[str] = None

class ScanResponse(BaseModel):
    summary: dict
    target: Optional[str] = None
    scans: List[Any]
    mode: str
    target_type: str

class UserResponse(BaseModel):
    id: int
    username: str
    is_active: bool
    is_admin: bool

    class Config:
        from_attributes = True

class UserCreate(BaseModel):
    username: str
    password: str
    is_admin: bool = False

class UserUpdate(BaseModel):
    password: Optional[str] = None
    is_admin: Optional[bool] = None
    is_active: Optional[bool] = None

class AuditLogResponse(BaseModel):
    id: int
    action: str
    process_name: Optional[str] = None
    details: Optional[str] = None
    timestamp: datetime
    user_id: Optional[int] = None

    class Config:
        from_attributes = True

class RansomwareResponse(BaseModel):
    id: int
    name: str
    description: Optional[str] = None
    hashes: List[str]
    timestamp: datetime

    class Config:
        from_attributes = True

class RansomwareCreate(BaseModel):
    name: str
    description: Optional[str] = None
    hashes: List[str] = []
