import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Boolean, DateTime, Enum as SAEnum
from sqlalchemy.dialects.postgresql import UUID
from app.base import Base
import enum


class DietType(str, enum.Enum):
    VEGETARIAN = "vegetarian"
    VEGETARIAN_EGG = "vegetarian_egg"
    NON_VEGETARIAN = "non_vegetarian"
    VEGAN = "vegan"


class User(Base):
    __tablename__ = "users"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    email = Column(String(255), unique=True, nullable=True)
    phone = Column(String(20), unique=True, nullable=True)
    firebase_uid = Column(String(255), unique=True, nullable=True)
    display_name = Column(String(255), nullable=True)
    password_hash = Column(String(255), nullable=True)
    diet_type = Column(SAEnum(DietType), nullable=True)
    language_preference = Column(String(10), default="en")
    onboarding_completed = Column(Boolean, default=False)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))
