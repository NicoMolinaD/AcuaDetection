import logging
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from starlette.middleware.base import BaseHTTPMiddleware
from app.core.config import settings
from app.api.api import api_router
from app.core.logging import setup_logging
from app.core.exceptions import MalcomException

# Setup centralized logging
setup_logging()
logger = logging.getLogger(__name__)

app = FastAPI(title="Malcom API", version="1.0.0", openapi_url=f"{settings.API_V1_STR}/openapi.json")

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Security headers middleware
class SecurityHeadersMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        response = await call_next(request)
        # HSTS - Force HTTPS for 1 year
        response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
        # X-Content-Type-Options - Prevent MIME sniffing
        response.headers["X-Content-Type-Options"] = "nosniff"
        # X-Frame-Options - Prevent clickjacking
        response.headers["X-Frame-Options"] = "DENY"
        # X-XSS-Protection - Enable XSS filter
        response.headers["X-XSS-Protection"] = "1; mode=block"
        # Content-Security-Policy - Restrict resource loading
        response.headers["Content-Security-Policy"] = "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self' data:; connect-src 'self' http://localhost:* https://*; frame-ancestors 'none';"
        # Permissions-Policy - Control browser features
        response.headers["Permissions-Policy"] = "geolocation=(), microphone=(), camera=(), payment=()"
        # Referrer-Policy - Control referrer information
        response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
        return response

app.add_middleware(SecurityHeadersMiddleware)

@app.exception_handler(MalcomException)
async def malcom_exception_handler(request: Request, exc: MalcomException):
    logger.error(f"Malcom error: {exc.message}")
    return JSONResponse(
        status_code=exc.status_code,
        content={"message": exc.message},
    )

@app.get("/")
def root():
    return {"message": "Malcom API is running", "env": settings.PROJECT_NAME}

@app.get("/health")
def health_check():
    """Health check endpoint for load balancers and orchestration platforms"""
    return {"status": "healthy"}

app.include_router(api_router, prefix=settings.API_V1_STR)
