import os
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    PROJECT_NAME: str = "Malcom Threat Intelligence"
    API_V1_STR: str = "/api/v1"
    SECRET_KEY: str = os.getenv("SECRET_KEY", "change_this_to_a_secure_random_key")
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 8 # 8 days
    
    # Database
    DATABASE_URL: str = os.getenv("DATABASE_URL", "postgresql://malcom:malcom_secure_pass@db:5432/malcom_db")
    DB_ENCRYPTION_KEY: str = os.getenv("DB_ENCRYPTION_KEY", "YWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWE=")

    # External APIs
    VT_API_KEY: str | None = os.getenv("VT_API_KEY")
    HA_API_KEY: str | None = os.getenv("HA_API_KEY")
    ABUSEIPDB_API_KEY: str | None = os.getenv("ABUSEIPDB_API_KEY")
    MALSHARE_API_KEY: str | None = os.getenv("MALSHARE_API_KEY")
    MALWAREBAZAAR_API_KEY: str | None = os.getenv("MALWAREBAZAAR_API_KEY")
    PT_API_KEY: str | None = os.getenv("PT_API_KEY")

    # Sandbox Configuration (Optional)
    CUCKOO_API_URL: str = ""
    CUCKOO_API_KEY: str = ""
    CAPE_API_URL: str = ""
    CAPE_API_KEY: str = ""

    class Config:
        env_file = ".env"

settings = Settings()
