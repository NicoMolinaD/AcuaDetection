"""
Rate limiting service to prevent brute force attacks on login.
"""

from datetime import datetime, timedelta
from typing import Dict, Tuple
from sqlalchemy.orm import Session
from app.models.user import User
from app.core.logging import get_logger

logger = get_logger(__name__)

# In-memory store for failed login attempts (IP address -> [(timestamp, attempts)])
# In a production environment, this should be stored in Redis
failed_attempts: Dict[str, list] = {}

# Configuration
MAX_ATTEMPTS = 5  # Maximum failed attempts
LOCKOUT_DURATION = 15  # Minutes
ATTEMPT_WINDOW = 15  # Minutes (reset counter after this time)


class RateLimiter:
    """Manages rate limiting for login attempts."""

    @staticmethod
    def is_account_locked(username: str) -> bool:
        """
        Check if a user account is locked due to too many failed attempts.
        
        Args:
            username: Username to check
            
        Returns:
            True if account is locked, False otherwise
        """
        if username not in failed_attempts:
            return False
        
        attempts = failed_attempts[username]
        if not attempts:
            return False
        
        # Get the most recent attempt
        last_attempt_time = attempts[-1]
        
        # Check if account is still in lockout period
        if datetime.utcnow() - last_attempt_time < timedelta(minutes=LOCKOUT_DURATION):
            # Count attempts in the window
            recent_attempts = [
                t for t in attempts 
                if datetime.utcnow() - t < timedelta(minutes=ATTEMPT_WINDOW)
            ]
            if len(recent_attempts) >= MAX_ATTEMPTS:
                return True
        else:
            # Lockout period has expired, reset attempts
            failed_attempts[username] = []
        
        return False

    @staticmethod
    def record_failed_attempt(username: str) -> Tuple[bool, int]:
        """
        Record a failed login attempt.
        
        Args:
            username: Username that failed
            
        Returns:
            Tuple of (is_locked, remaining_attempts)
        """
        if username not in failed_attempts:
            failed_attempts[username] = []
        
        # Add the current timestamp
        failed_attempts[username].append(datetime.utcnow())
        
        # Clean up old attempts
        window_start = datetime.utcnow() - timedelta(minutes=ATTEMPT_WINDOW)
        failed_attempts[username] = [
            t for t in failed_attempts[username] if t > window_start
        ]
        
        recent_attempts = len(failed_attempts[username])
        is_locked = recent_attempts >= MAX_ATTEMPTS
        remaining = max(0, MAX_ATTEMPTS - recent_attempts)
        
        if is_locked:
            logger.warning(f"Account locked for user: {username} due to too many failed attempts")
        
        return is_locked, remaining

    @staticmethod
    def clear_failed_attempts(username: str) -> None:
        """
        Clear failed attempts for a user after successful login.
        
        Args:
            username: Username to clear attempts for
        """
        if username in failed_attempts:
            failed_attempts[username] = []


# Alternative: Redis-based rate limiter for production
class RedisRateLimiter:
    """Redis-based rate limiter for production environments."""
    
    @staticmethod
    def is_account_locked(redis_client, username: str) -> bool:
        """Check if account is locked using Redis."""
        key = f"login_attempts:{username}"
        attempts = redis_client.get(key)
        return int(attempts or 0) >= MAX_ATTEMPTS

    @staticmethod
    def record_failed_attempt(redis_client, username: str) -> Tuple[bool, int]:
        """Record failed attempt in Redis."""
        key = f"login_attempts:{username}"
        attempts = redis_client.incr(key)
        
        # Set expiration on first attempt
        if attempts == 1:
            redis_client.expire(key, ATTEMPT_WINDOW * 60)
        
        is_locked = attempts >= MAX_ATTEMPTS
        remaining = max(0, MAX_ATTEMPTS - attempts)
        
        return is_locked, remaining

    @staticmethod
    def clear_failed_attempts(redis_client, username: str) -> None:
        """Clear failed attempts from Redis."""
        key = f"login_attempts:{username}"
        redis_client.delete(key)
