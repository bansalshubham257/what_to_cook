import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Integer, Boolean, DateTime, ForeignKey, Enum as SAEnum
from sqlalchemy.dialects.postgresql import UUID
from app.base import Base
import enum


class KitchenProfileType(str, enum.Enum):
    BASIC_NORTH_INDIAN_VEG = "basic_north_indian_veg"
    NORTH_INDIAN_NON_VEG = "north_indian_non_veg"
    SOUTH_INDIAN = "south_indian"
    MIXED_INDIAN = "mixed_indian"
    CUSTOM = "custom"


class KitchenProfile(Base):
    __tablename__ = "kitchen_profiles"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String(255), nullable=False)
    profile_type = Column(SAEnum(KitchenProfileType), nullable=False)
    description = Column(String(500), nullable=True)
    is_default = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))


class KitchenProfileItem(Base):
    __tablename__ = "kitchen_profile_items"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    kitchen_profile_id = Column(UUID(as_uuid=True), ForeignKey("kitchen_profiles.id"), nullable=False)
    ingredient_id = Column(UUID(as_uuid=True), ForeignKey("ingredients.id"), nullable=False)
    is_default = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
