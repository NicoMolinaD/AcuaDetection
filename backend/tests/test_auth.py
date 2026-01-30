"""
Unit tests for authentication endpoints.
"""

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, Session
from app.main import app
from app.core.database import Base, get_db
from app.models.user import User
from app.core import security
from datetime import datetime

# Use in-memory SQLite for testing
SQLALCHEMY_DATABASE_URL = "sqlite:///./test.db"

engine = create_engine(
    SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False}
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


def override_get_db():
    try:
        db = TestingSessionLocal()
        yield db
    finally:
        db.close()


Base.metadata.create_all(bind=engine)
app.dependency_overrides[get_db] = override_get_db

client = TestClient(app)


@pytest.fixture(autouse=True)
def setup_db():
    """Setup database for each test"""
    Base.metadata.create_all(bind=engine)
    yield
    Base.metadata.drop_all(bind=engine)


@pytest.fixture
def admin_user():
    """Create admin test user"""
    db = TestingSessionLocal()
    admin = User(
        username="admin",
        hashed_password=security.get_password_hash("AdminPass123!"),
        is_admin=True,
        is_active=True,
        is_online=True,
        last_login=datetime.utcnow()
    )
    db.add(admin)
    db.commit()
    db.refresh(admin)
    db.close()
    return admin


@pytest.fixture
def regular_user():
    """Create regular test user"""
    db = TestingSessionLocal()
    user = User(
        username="user",
        hashed_password=security.get_password_hash("UserPass123!"),
        is_admin=False,
        is_active=True,
        is_online=False
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    db.close()
    return user


class TestLoginEndpoint:
    """Test login endpoint"""

    def test_login_with_valid_credentials(self, admin_user):
        response = client.post(
            "/api/v1/auth/login/access-token",
            data={"username": "admin", "password": "AdminPass123!"}
        )
        assert response.status_code == 200
        assert "access_token" in response.json()
        assert response.json()["token_type"] == "bearer"
        assert response.json()["is_admin"] is True

    def test_login_with_invalid_username(self, admin_user):
        response = client.post(
            "/api/v1/auth/login/access-token",
            data={"username": "nonexistent", "password": "AdminPass123!"}
        )
        assert response.status_code == 401

    def test_login_with_invalid_password(self, admin_user):
        response = client.post(
            "/api/v1/auth/login/access-token",
            data={"username": "admin", "password": "WrongPassword123!"}
        )
        assert response.status_code == 401

    def test_login_with_sql_injection_attempt(self, admin_user):
        response = client.post(
            "/api/v1/auth/login/access-token",
            data={"username": "admin' OR '1'='1", "password": "AdminPass123!"}
        )
        assert response.status_code == 401

    def test_login_with_weak_password_format(self, admin_user):
        # Password without special character format should be rejected
        response = client.post(
            "/api/v1/auth/login/access-token",
            data={"username": "admin", "password": "weakpass"}
        )
        assert response.status_code == 401


class TestLogoutEndpoint:
    """Test logout endpoint"""

    def test_logout_with_valid_token(self, admin_user):
        # First login
        login_response = client.post(
            "/api/v1/auth/login/access-token",
            data={"username": "admin", "password": "AdminPass123!"}
        )
        token = login_response.json()["access_token"]

        # Then logout
        response = client.post(
            "/api/v1/auth/logout",
            headers={"Authorization": f"Bearer {token}"}
        )
        assert response.status_code == 200

    def test_logout_without_token(self):
        response = client.post("/api/v1/auth/logout")
        assert response.status_code == 403


class TestHeartbeatEndpoint:
    """Test heartbeat endpoint"""

    def test_heartbeat_with_valid_token(self, admin_user):
        # First login
        login_response = client.post(
            "/api/v1/auth/login/access-token",
            data={"username": "admin", "password": "AdminPass123!"}
        )
        token = login_response.json()["access_token"]

        # Send heartbeat
        response = client.post(
            "/api/v1/session/heartbeat",
            headers={"Authorization": f"Bearer {token}"}
        )
        assert response.status_code == 200
        assert response.json()["status"] == "ok"

    def test_heartbeat_without_token(self):
        response = client.post("/api/v1/session/heartbeat")
        assert response.status_code == 403


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
