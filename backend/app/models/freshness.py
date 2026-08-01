import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Integer, DateTime, ForeignKey, Enum as SAEnum
from sqlalchemy.dialects.postgresql import UUID
from app.base import Base
import enum


class StorageType(str, enum.Enum):
    ROOM_TEMPERATURE = "room_temperature"
    REFRIGERATED = "refrigerated"
    FROZEN = "frozen"


class FreshnessRule(Base):
    __tablename__ = "freshness_rules"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    ingredient_id = Column(UUID(as_uuid=True), ForeignKey("ingredients.id"), nullable=False)
    storage_type = Column(SAEnum(StorageType), default=StorageType.ROOM_TEMPERATURE)
    freshness_days_min = Column(Integer, default=1)
    freshness_days_max = Column(Integer, default=7)
    use_soon_threshold_days = Column(Integer, default=3)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
