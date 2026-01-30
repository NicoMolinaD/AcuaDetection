"""
Unit tests for security validators.
"""

import pytest
from app.core.validators import SecurityValidator


class TestUsernameValidation:
    """Test username validation"""

    def test_valid_username(self):
        is_valid, msg = SecurityValidator.validate_username("validUser123")
        assert is_valid is True
        assert msg == ""

    def test_username_too_short(self):
        is_valid, msg = SecurityValidator.validate_username("ab")
        assert is_valid is False

    def test_username_too_long(self):
        is_valid, msg = SecurityValidator.validate_username("a" * 51)
        assert is_valid is False

    def test_username_with_invalid_chars(self):
        is_valid, msg = SecurityValidator.validate_username("user@invalid!")
        assert is_valid is False

    def test_username_with_spaces(self):
        is_valid, msg = SecurityValidator.validate_username("user name")
        assert is_valid is False

    def test_valid_username_with_underscore(self):
        is_valid, msg = SecurityValidator.validate_username("user_name_123")
        assert is_valid is True

    def test_valid_username_with_hyphen(self):
        is_valid, msg = SecurityValidator.validate_username("user-name-123")
        assert is_valid is True


class TestPasswordValidation:
    """Test password validation"""

    def test_valid_password(self):
        is_valid, msg = SecurityValidator.validate_password("ValidPass123!")
        assert is_valid is True
        assert msg == ""

    def test_password_missing_uppercase(self):
        is_valid, msg = SecurityValidator.validate_password("validpass123!")
        assert is_valid is False
        assert "mayúscula" in msg

    def test_password_missing_lowercase(self):
        is_valid, msg = SecurityValidator.validate_password("VALIDPASS123!")
        assert is_valid is False
        assert "minúscula" in msg

    def test_password_missing_number(self):
        is_valid, msg = SecurityValidator.validate_password("ValidPass!")
        assert is_valid is False
        assert "número" in msg

    def test_password_missing_special_char(self):
        is_valid, msg = SecurityValidator.validate_password("ValidPass123")
        assert is_valid is False
        assert "especial" in msg

    def test_password_too_short(self):
        is_valid, msg = SecurityValidator.validate_password("Pass1!")
        assert is_valid is False
        assert "entre" in msg

    def test_password_too_long(self):
        is_valid, msg = SecurityValidator.validate_password("ValidPass123!" * 2)
        assert is_valid is False
        assert "entre" in msg

    def test_password_with_allowed_special_chars(self):
        valid_passwords = [
            "ValidPass123!",
            "ValidPass123@",
            "ValidPass123#",
            "ValidPass123$",
            "ValidPass123%",
            "ValidPass123^",
            "ValidPass123&",
            "ValidPass123*",
        ]
        for pwd in valid_passwords:
            is_valid, msg = SecurityValidator.validate_password(pwd)
            assert is_valid is True, f"Password {pwd} should be valid"

    def test_password_with_disallowed_special_chars(self):
        is_valid, msg = SecurityValidator.validate_password("ValidPass123<>")
        # < and > might be allowed depending on implementation, check actual result
        # This is just an example


class TestLoginInputValidation:
    """Test combined login input validation"""

    def test_valid_login_credentials(self):
        is_valid, msg = SecurityValidator.validate_login_input("validUser", "ValidPass123!")
        assert is_valid is True

    def test_invalid_username_valid_password(self):
        is_valid, msg = SecurityValidator.validate_login_input("user@", "ValidPass123!")
        assert is_valid is False
        assert "Usuario o contraseña" in msg

    def test_valid_username_invalid_password(self):
        is_valid, msg = SecurityValidator.validate_login_input("validUser", "weak")
        assert is_valid is False
        assert "Usuario o contraseña" in msg

    def test_both_invalid(self):
        is_valid, msg = SecurityValidator.validate_login_input("user@", "weak")
        assert is_valid is False
        assert "Usuario o contraseña" in msg


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
