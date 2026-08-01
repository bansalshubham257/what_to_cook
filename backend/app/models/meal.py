import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Integer, Boolean, Text, DateTime, ForeignKey, Enum as SAEnum
from sqlalchemy.dialects.postgresql import UUID, ARRAY
from app.base import Base
import enum


class MealType(str, enum.Enum):
    BREAKFAST = "breakfast"
    LUNCH = "lunch"
    SNACKS = "snacks"
    DINNER = "dinner"


class MealHistory(Base):
    __tablename__ = "meal_history"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    household_id = Column(UUID(as_uuid=True), ForeignKey("households.id"), nullable=False)
    recipe_id = Column(UUID(as_uuid=True), ForeignKey("recipes.id"), nullable=False)
    meal_type = Column(SAEnum(MealType), nullable=False)
    cooked_by = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=True)
    cooked_date = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    ingredients_used = Column(ARRAY(UUID), nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))


class MealFeedback(Base):
    __tablename__ = "meal_feedback"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    meal_history_id = Column(UUID(as_uuid=True), ForeignKey("meal_history.id"), nullable=False)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=True)
    rating = Column(Integer, nullable=True)
    liked = Column(Boolean, nullable=True)
    family_liked = Column(Boolean, nullable=True)
    kids_liked = Column(Boolean, nullable=True)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
