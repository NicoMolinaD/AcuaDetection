from cryptography.fernet import Fernet
from app.core.config import settings
from app.core.logging import get_logger

logger = get_logger(__name__)

class EncryptionManager:
    def __init__(self, key: str = settings.DB_ENCRYPTION_KEY):
        try:
            self.fernet = Fernet(key.encode())
        except Exception as e:
            logger.error(f"Failed to initialize EncryptionManager: {e}")
            self.fernet = None

    def encrypt(self, data: str) -> str:
        if not self.fernet or not data:
            return data
        try:
            return self.fernet.encrypt(data.encode()).decode()
        except Exception as e:
            logger.error(f"Encryption error: {e}")
            return data

    def decrypt(self, encrypted_data: str) -> str:
        if not self.fernet or not encrypted_data:
            return encrypted_data
        try:
            return self.fernet.decrypt(encrypted_data.encode()).decode()
        except Exception:
            return encrypted_data

from sqlalchemy.types import TypeDecorator, String

class EncryptedString(TypeDecorator):
    impl = String
    cache_ok = True

    def process_bind_param(self, value, dialect):
        if value is not None:
            return encryption_manager.encrypt(value)
        return value

    def process_result_value(self, value, dialect):
        if value is not None:
            return encryption_manager.decrypt(value)
        return value

encryption_manager = EncryptionManager()
