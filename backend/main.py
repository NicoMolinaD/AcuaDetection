import logging
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings
from app.api.api import api_router
from app.core.logging import setup_logging
from app.core.exceptions import MalcomException

# Setup centralized logging
setup_logging()
logger = logging.getLogger(__name__)

app = FastAPI(title="Malcom API", version="1.0.0", openapi_url=f"{settings.API_V1_STR}/openapi.json")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

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

app.include_router(api_router, prefix=settings.API_V1_STR)
