#!/usr/bin/env python3
"""
Script to update admin user password to a strong one.
Run this script once to secure the admin account.
"""

import sys
sys.path.insert(0, '/app')

from app.core.database import SessionLocal
from app.core import security
from app.models.user import User

def update_admin_password():
    """Update admin password to a secure one"""
    db = SessionLocal()
    try:
        admin = db.query(User).filter(User.username == "admin").first()
        if not admin:
            print("Error: Admin user not found")
            return False
        
        # Strong admin password
        new_password = "Ad.m¡n1sTer.#2O26!"
        
        print("Updating admin password...")
        admin.hashed_password = security.get_password_hash(new_password)
        db.add(admin)
        db.commit()
        
        print("Success: Admin password updated")
        print(f"New password: {new_password}")
        print("IMPORTANT: Change this password after first login!")
        return True
    except Exception as e:
        print(f"Error updating admin password: {e}")
        db.rollback()
        return False
    finally:
        db.close()

if __name__ == "__main__":
    if not update_admin_password():
        sys.exit(1)
