from app.core.database import SessionLocal
from app.models.user import User

db = SessionLocal()
try:
    print(f"Connecting to DB: {db.get_bind().url}")
    users = db.query(User).all()
    print(f"Found {len(users)} users:")
    for user in users:
        print(f" - ID: {user.id}, User: {user.username}, Admin: {user.is_admin}, Hash: {user.hashed_password[:10]}...")
except Exception as e:
    print(f"Error: {e}")
finally:
    db.close()
