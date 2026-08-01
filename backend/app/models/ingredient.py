import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Integer, Boolean, DateTime, ForeignKey, Enum as SAEnum, Index
from sqlalchemy.orm import relationship
from sqlalchemy.dialects.postgresql import UUID
from app.base import Base
import enum


class IngredientCategoryType(str, enum.Enum):
    GRAIN = "grain"
    PULSE = "pulse"
    SPICE = "spice"
    VEGETABLE = "vegetable"
    FRUIT = "fruit"
    DAIRY = "dairy"
    MEAT = "meat"
    OIL = "oil"
    CONDIMENT = "condiment"
    HERB = "herb"
    OTHER = "other"


class IngredientStorageType(str, enum.Enum):
    PANTRY = "pantry"
    FRESH = "fresh"
    OCCASIONAL = "occasional"


class Ingredient(Base):
    __tablename__ = "ingredients"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String(255), nullable=False, unique=True)
    display_name_en = Column(String(255), nullable=False)
    display_name_hi = Column(String(255), nullable=True)
    category = Column(SAEnum(IngredientCategoryType), nullable=False)
    storage_type = Column(SAEnum(IngredientStorageType), default=IngredientStorageType.PANTRY)
    is_common = Column(Boolean, default=False)
    is_allergen = Column(Boolean, default=False)
    is_essential = Column(Boolean, default=False)
    is_active = Column(Boolean, default=True)
    image_url = Column(String(500), nullable=True)
    aliases = relationship("IngredientAlias", backref="ingredient", lazy="selectin")
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))


class IngredientAlias(Base):
    __tablename__ = "ingredient_aliases"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    ingredient_id = Column(UUID(as_uuid=True), ForeignKey("ingredients.id"), nullable=False)
    alias = Column(String(255), nullable=False)
    language = Column(String(10), default="en")
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    class Config:
        indexes = [
            Index("idx_ingredient_alias", "alias"),
        ]


class IngredientCategory(Base):
    __tablename__ = "ingredient_categories"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String(255), nullable=False, unique=True)
    display_name_en = Column(String(255), nullable=False)
    display_name_hi = Column(String(255), nullable=True)
    sort_order = Column(Integer, default=0)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
