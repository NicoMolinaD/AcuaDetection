#!/usr/bin/env python3
"""
Script to initialize the database with tables and a default admin user.
Run this after starting the containers for the first time.
"""

import sys
import time
sys.path.insert(0, '/app')

from app.core.database import engine, Base, SessionLocal
from app.core import security
from sqlalchemy import text

# Import all models to register them
from app.models import user, ransomware, audit_log

def wait_for_db(max_attempts=30):
    """Wait for database to be ready"""
    for attempt in range(max_attempts):
        try:
            with engine.connect() as conn:
                conn.execute(text("SELECT 1"))
                print("✓ Database connection successful")
                return True
        except Exception as e:
            if attempt == max_attempts - 1:
                print(f"✗ Could not connect to database after {max_attempts} attempts: {e}")
                return False
            print(f"  Attempting to connect ({attempt + 1}/{max_attempts})...")
            time.sleep(1)
    return False

def create_tables():
    """Create all database tables"""
    try:
        print("\n📋 Creating database tables...")
        Base.metadata.create_all(bind=engine)
        print("✓ Tables created successfully")
        return True
    except Exception as e:
        print(f"✗ Error creating tables: {e}")
        return False

def create_default_users():
    """Create default admin and regular users"""
    db = SessionLocal()
    try:
        # Check if admin already exists
        existing_admin = db.query(user.User).filter(user.User.username == "admin").first()
        if existing_admin:
            print("✓ Admin user already exists")
        else:
            admin_user = user.User(
                username="admin",
                hashed_password=security.get_password_hash("admin123"),
                is_admin=True,
                is_active=True
            )
            db.add(admin_user)
            db.commit()
            print("✓ Admin user created")
            print("  Username: admin")
            print("  Password: admin123")
            print("  ⚠️  IMPORTANT: Change this password after first login!")
        
        # Create a regular user for testing
        existing_user = db.query(user.User).filter(user.User.username == "user").first()
        if not existing_user:
            regular_user = user.User(
                username="user",
                hashed_password=security.get_password_hash("user123"),
                is_admin=False,
                is_active=True
            )
            db.add(regular_user)
            db.commit()
            print("✓ Regular user created")
            print("  Username: user")
            print("  Password: user123")
        else:
            print("✓ Regular user already exists")
        
        return True
    except Exception as e:
        print(f"✗ Error creating users: {e}")
        db.rollback()
        return False
    finally:
        db.close()

def main():
    print("\n" + "="*50)
    print("  🚀 AquaDetection Database Initialization")
    print("="*50)
    
    # Wait for database
    if not wait_for_db():
        sys.exit(1)
    
    # Create tables
    if not create_tables():
        sys.exit(1)
    
    # Create default users
    if not create_default_users():
        sys.exit(1)
    
    print("\n✓ Database initialization complete!")
    print("="*50 + "\n")

if __name__ == "__main__":
    main()


