"""
Security validators for user input to prevent injection attacks and enforce security policies.
"""

import re
from typing import Tuple
from app.core.exceptions import MalcomException

# Define allowed characters for username and password
# Username: alphanumeric, underscore, hyphen (3-50 chars)
USERNAME_PATTERN = r'^[a-zA-Z0-9_-]{3,50}$'
USERNAME_MIN_LENGTH = 3
USERNAME_MAX_LENGTH = 50

# Password: at least 8 characters, at most 16
# Must contain: uppercase, lowercase, number, special char
PASSWORD_MIN_LENGTH = 8
PASSWORD_MAX_LENGTH = 16

# Allowed special characters in passwords
ALLOWED_PASSWORD_SPECIAL_CHARS = r'!@#$%^&*()_+=\[\]{};:\'",.<>?/\\|`~-¡'


class SecurityValidator:
    """Validates user input to prevent injection attacks and enforce security policies."""

    @staticmethod
    def validate_username(username: str) -> Tuple[bool, str]:
        """
        Validate username format.
        
        Args:
            username: Username to validate
            
        Returns:
            Tuple of (is_valid, error_message)
        """
        # Check if username is a string
        if not isinstance(username, str):
            return False, "Invalid input format"
        
        # Check length
        if len(username) < USERNAME_MIN_LENGTH or len(username) > USERNAME_MAX_LENGTH:
            return False, "Invalid input format"
        
        # Check pattern (only alphanumeric, underscore, hyphen)
        if not re.match(USERNAME_PATTERN, username):
            return False, "Invalid input format"
        
        return True, ""

    @staticmethod
    def validate_password(password: str) -> Tuple[bool, str]:
        """
        Validate password strength and format.
        
        Requires:
        - 8-16 characters
        - At least one uppercase letter
        - At least one lowercase letter
        - At least one number
        - At least one special character
        
        Args:
            password: Password to validate
            
        Returns:
            Tuple of (is_valid, error_message)
        """
        # Check if password is a string
        if not isinstance(password, str):
            return False, "Formato de entrada inválido"
        
        # Check length
        if len(password) < PASSWORD_MIN_LENGTH or len(password) > PASSWORD_MAX_LENGTH:
            return False, f"La contraseña debe tener entre {PASSWORD_MIN_LENGTH} y {PASSWORD_MAX_LENGTH} caracteres"
        
        # Check if contains at least one uppercase letter
        if not re.search(r'[A-Z]', password):
            return False, "La contraseña debe contener al menos una letra mayúscula"
        
        # Check if contains at least one lowercase letter
        if not re.search(r'[a-z]', password):
            return False, "La contraseña debe contener al menos una letra minúscula"
        
        # Check if contains at least one number
        if not re.search(r'[0-9]', password):
            return False, "La contraseña debe contener al menos un número"
        
        # Check if contains at least one special character
        if not re.search(r'[!@#$%^&*()_+=\[\]{};:\'",.<>?/\\|`~\-¡]', password):
            return False, "La contraseña debe contener al menos un carácter especial (!@#$%^&* etc)"
        
        # Check if contains only allowed characters
        allowed_pattern = f'^[a-zA-Z0-9{re.escape(ALLOWED_PASSWORD_SPECIAL_CHARS)}]+$'
        if not re.match(allowed_pattern, password):
            return False, "La contraseña contiene caracteres no permitidos"
        
        return True, ""

    @staticmethod
    def validate_login_input(username: str, password: str) -> Tuple[bool, str]:
        """
        Validate both username and password for login.
        
        Args:
            username: Username to validate
            password: Password to validate
            
        Returns:
            Tuple of (is_valid, error_message)
        """
        # Validate username
        is_valid_username, error_msg = SecurityValidator.validate_username(username)
        if not is_valid_username:
            return False, "Usuario o contraseña incorrectos"
        
        # Validate password
        is_valid_password, error_msg = SecurityValidator.validate_password(password)
        if not is_valid_password:
            return False, "Usuario o contraseña incorrectos"
        
        return True, ""

    @staticmethod
    def sanitize_input(user_input: str) -> str:
        """
        Basic input sanitization (remove leading/trailing whitespace).
        
        Args:
            user_input: Input to sanitize
            
        Returns:
            Sanitized input
        """
        if not isinstance(user_input, str):
            return ""
        return user_input.strip()
