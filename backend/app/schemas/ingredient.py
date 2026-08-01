from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
from uuid import UUID


class IngredientResponse(BaseModel):
    id: UUID
    name: str
    display_name_en: str
    display_name_hi: Optional[str]
    category: str
    storage_type: str
    is_common: bool
    is_allergen: bool
    image_url: Optional[str]

    class Config:
        from_attributes = True


class IngredientCategoryResponse(BaseModel):
    id: UUID
    name: str
    display_name_en: str
    display_name_hi: Optional[str]
    sort_order: int

    class Config:
        from_attributes = True


class InventoryItemCreate(BaseModel):
    ingredient_id: UUID
    status: str = "available"
    quantity: Optional[str] = None
    unit: Optional[str] = None
    freshness_window_days: Optional[int] = None


class InventoryItemUpdate(BaseModel):
    status: Optional[str] = None
    quantity: Optional[str] = None
    unit: Optional[str] = None
    last_confirmed_date: Optional[datetime] = None


class InventoryItemResponse(BaseModel):
    id: UUID
    household_id: UUID
    ingredient_id: UUID
    ingredient: Optional[IngredientResponse]
    status: str
    quantity: Optional[str]
    unit: Optional[str]
    date_added: datetime
    last_confirmed_date: Optional[datetime]
    freshness_window_days: Optional[int]
    notes: Optional[str]

    class Config:
        from_attributes = True


class VoiceInventoryRequest(BaseModel):
    text: str
    language: str = "hi"


class VoiceInventoryResponse(BaseModel):
    intent: str
    category: Optional[str]
    add: List[str]
    remove: List[str]
    set_low: List[str]
    set_use_soon: List[str]
    confidence: float
    message: str
    requires_confirmation: bool = False
