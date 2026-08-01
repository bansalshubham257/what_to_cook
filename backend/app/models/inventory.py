import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Integer, Boolean, DateTime, ForeignKey, Enum as SAEnum, Date, Index
from sqlalchemy.dialects.postgresql import UUID
from app.base import Base
import enum


class InventoryStatus(str, enum.Enum):
    AVAILABLE = "available"
    LOW = "low"
    USE_SOON = "use_soon"
    NOT_AVAILABLE = "not_available"


class InventoryItem(Base):
    __tablename__ = "inventory_items"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    household_id = Column(UUID(as_uuid=True), ForeignKey("households.id"), nullable=False)
    ingredient_id = Column(UUID(as_uuid=True), ForeignKey("ingredients.id"), nullable=False)
    status = Column(SAEnum(InventoryStatus), default=InventoryStatus.AVAILABLE)
    quantity = Column(String(50), nullable=True)
    unit = Column(String(50), nullable=True)
    date_added = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    last_confirmed_date = Column(DateTime(timezone=True), nullable=True)
    freshness_window_days = Column(Integer, nullable=True)
    storage_type = Column(String(50), nullable=True)
    notes = Column(String(500), nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    class Config:
        indexes = [
            Index("idx_inventory_household_ingredient", "household_id", "ingredient_id", unique=True),
        ]
