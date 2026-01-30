from fastapi import APIRouter
from app.api import auth, scan, ransomware, logs, malcom, users, session

api_router = APIRouter()

api_router.include_router(auth.router, prefix="/auth", tags=["auth"])
api_router.include_router(session.router, prefix="/session", tags=["session"])
api_router.include_router(scan.router, prefix="/scan", tags=["scan"])
api_router.include_router(ransomware.router, prefix="/ransomware", tags=["ransomware"])
api_router.include_router(logs.router, prefix="/logs", tags=["logs"])
api_router.include_router(malcom.router, prefix="/malcom", tags=["malcom"])
api_router.include_router(users.router, prefix="/users", tags=["users"])
