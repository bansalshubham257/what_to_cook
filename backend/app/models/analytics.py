import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Integer, Float, Boolean, DateTime, ForeignKey, Enum as SAEnum, JSON
from sqlalchemy.dialects.postgresql import UUID
from app.base import Base
import enum


class EventType(str, enum.Enum):
    ONBOARDING_COMPLETED = "onboarding_completed"
    INVENTORY_VOICE_USED = "inventory_voice_used"
    INVENTORY_UPDATED = "inventory_updated"
    RECOMMENDATION_VIEWED = "recommendation_viewed"
    RECIPE_OPENED = "recipe_opened"
    RECIPE_COOKED = "recipe_cooked"
    RECIPE_SKIPPED = "recipe_skipped"
    RECIPE_FAVORITED = "recipe_favorited"
    SHOPPING_ITEM_ADDED = "shopping_item_added"
    USE_SOON_CLICKED = "use_soon_clicked"
    WEEKLY_REPORT_VIEWED = "weekly_report_viewed"
    SURPRISE_ME_USED = "surprise_me_used"


class RecommendationEvent(Base):
    __tablename__ = "recommendation_events"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    event_type = Column(SAEnum(EventType), nullable=False)
    recipe_id = Column(UUID(as_uuid=True), ForeignKey("recipes.id"), nullable=True)
    event_metadata = Column("metadata", JSON, nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))


class AiParsingLog(Base):
    __tablename__ = "ai_parsing_logs"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=True)
    input_text = Column(String(2000), nullable=False)
    parsed_result = Column(JSON, nullable=True)
    confidence = Column(Float, nullable=True)
    was_confirmed = Column(Boolean, nullable=True)
    language = Column(String(10), nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
