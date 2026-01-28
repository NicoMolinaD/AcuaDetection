from sqlalchemy import Column, Integer, String, Text, DateTime, func
from sqlalchemy.dialects.postgresql import JSONB
from app.core.database import Base

class Ransomware(Base):
    __tablename__ = "ransomware"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True, nullable=False, unique=True)
    description = Column(Text, nullable=True)
    
    hashes = Column(JSONB, default=dict, nullable=False)
    ips = Column(JSONB, default=list, nullable=False)
    domains = Column(JSONB, default=list, nullable=False)

    severity = Column(String, default="High")
    timestamp = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
