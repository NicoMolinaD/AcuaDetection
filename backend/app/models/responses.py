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
    hashes: dict = {}
    ips: List[str] = []
    domains: List[str] = []
    severity: str = "High"
    timestamp: datetime

    class Config:
        from_attributes = True

class RansomwareCreate(BaseModel):
    name: str
    description: Optional[str] = None
    hashes: dict = {}
    ips: List[str] = []
    domains: List[str] = []
    severity: str = "High"

class RansomwareUpdate(BaseModel):
    description: Optional[str] = None
    hashes: Optional[dict] = None
    ips: Optional[List[str]] = None
    domains: Optional[List[str]] = None
    severity: Optional[str] = None
    
    def is_valid(self):
        """Check if at least one field is being updated"""
        return any([
            self.description is not None,
            self.hashes is not None,
            self.ips is not None,
            self.domains is not None,
            self.severity is not None
        ])
