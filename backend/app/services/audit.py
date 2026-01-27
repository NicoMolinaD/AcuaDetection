from sqlalchemy.orm import Session
from app.models.audit_log import AuditLog
from app.models.user import User

def log_action(db: Session, user: User | int | None, action: str, process_name: str = None, details: str = None):
    """
    Log an action to the audit_logs table.
    user: User object, user_id (int), or None (System)
    """
    user_id = None
    if isinstance(user, User):
        user_id = user.id
    elif isinstance(user, int):
        user_id = user
        
    log = AuditLog(
        user_id=user_id,
        action=action,
        process_name=process_name,
        details=details
    )
    db.add(log)
    db.commit()
