import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Integer, Boolean, Float, Text, DateTime, ForeignKey, Enum as SAEnum
from sqlalchemy.dialects.postgresql import UUID, ARRAY
from app.base import Base
import enum


class DietType(str, enum.Enum):
    VEGETARIAN = "vegetarian"
    VEGETARIAN_EGG = "vegetarian_egg"
    NON_VEGETARIAN = "non_vegetarian"
    VEGAN = "vegan"


class DifficultyLevel(str, enum.Enum):
    EASY = "easy"
    MEDIUM = "medium"
    HARD = "hard"


class HealthCategory(str, enum.Enum):
    BALANCED = "balanced"
    MODERATE = "moderate"
    INDULGENT = "indulgent"


class Cuisine(Base):
    __tablename__ = "cuisines"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String(100), nullable=False, unique=True)
    display_name_en = Column(String(100), nullable=False)
    display_name_hi = Column(String(100), nullable=True)
    region = Column(String(100), nullable=True)
    is_active = Column(Boolean, default=True)
    sort_order = Column(Integer, default=0)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))


class Recipe(Base):
    __tablename__ = "recipes"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String(255), nullable=False)
    description = Column(Text, nullable=True)
    cuisine_id = Column(UUID(as_uuid=True), ForeignKey("cuisines.id"), nullable=False)
    meal_types = Column(ARRAY(String(50)), nullable=True)
    diet_type = Column(SAEnum(DietType), nullable=False)
    prep_time_minutes = Column(Integer, default=0)
    cook_time_minutes = Column(Integer, default=0)
    total_time_minutes = Column(Integer, default=0)
    difficulty = Column(SAEnum(DifficultyLevel), default=DifficultyLevel.MEDIUM)
    servings = Column(Integer, default=2)
    instructions = Column(Text, nullable=False)
    health_score = Column(Integer, default=50)
    health_category = Column(SAEnum(HealthCategory), default=HealthCategory.MODERATE)
    image_url = Column(String(500), nullable=True)
    is_active = Column(Boolean, default=True)
    tags = Column(ARRAY(String(100)), nullable=True)
    source = Column(String(255), nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))


class RecipeIngredient(Base):
    __tablename__ = "recipe_ingredients"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    recipe_id = Column(UUID(as_uuid=True), ForeignKey("recipes.id"), nullable=False)
    ingredient_id = Column(UUID(as_uuid=True), ForeignKey("ingredients.id"), nullable=False)
    quantity = Column(String(100), nullable=True)
    unit = Column(String(50), nullable=True)
    is_required = Column(Boolean, default=True)
    substitution_group = Column(Integer, nullable=True)
    notes = Column(String(255), nullable=True)
    sort_order = Column(Integer, default=0)


class RecipeTag(Base):
    __tablename__ = "recipe_tags"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    recipe_id = Column(UUID(as_uuid=True), ForeignKey("recipes.id"), nullable=False)
    tag = Column(String(100), nullable=False)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
