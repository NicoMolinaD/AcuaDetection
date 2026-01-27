from sqlalchemy import Column, Integer, String, Text, ARRAY
from app.core.database import Base

class Ransomware(Base):
    __tablename__ = "ransomware"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True, nullable=False)
    description = Column(Text, nullable=True)
    
    from sqlalchemy.dialects.postgresql import JSONB
    
    hashes = Column(JSONB, default=list) 
    ips = Column(JSONB, default=list)
    domains = Column(JSONB, default=list)

    severity = Column(String, default="High")
    from sqlalchemy.sql import func
    from sqlalchemy import DateTime
    timestamp = Column(DateTime(timezone=True), server_default=func.now())
