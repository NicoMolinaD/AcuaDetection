#!/usr/bin/env python3
"""
Script to initialize the database with tables and a default admin user.
Run this after starting the containers for the first time.
"""

import sys
sys.path.insert(0, '/app')

from app.core.database import engine, SessionLocal
from app.models import user, ransomware, audit_log
from app.core import security

# Create all tables
print("Creating database tables...")
user.User.metadata.create_all(bind=engine)
ransomware.Ransomware.metadata.create_all(bind=engine)
audit_log.AuditLog.metadata.create_all(bind=engine)
print("Tables created successfully")

# Create default admin user
db = SessionLocal()
try:
    # Check if admin already exists
    existing_admin = db.query(user.User).filter(user.User.username == "admin").first()
    if existing_admin:
        print("Admin user already exists")
    else:
        admin_user = user.User(
            username="admin",
            hashed_password=security.get_password_hash("admin123"),
            is_admin=True
        )
        db.add(admin_user)
        db.commit()
        print("Admin user created successfully")
        print("   Username: admin")
        print("   Password: admin123")
        print("   IMPORTANT: Change this password after first login!")
    
    # Create a regular user for testing
    existing_user = db.query(user.User).filter(user.User.username == "user").first()
    if not existing_user:
        regular_user = user.User(
            username="user",
            hashed_password=security.get_password_hash("user123"),
            is_admin=False
        )
        db.add(regular_user)
        db.commit()
        print("   Regular user created successfully")
        print("   Username: user")
        print("   Password: user123")
    
finally:
    db.close()

print("\n  Database initialization complete!")
