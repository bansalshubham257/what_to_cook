from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
from uuid import UUID


class RecipeIngredientResponse(BaseModel):
    id: UUID
    ingredient_id: UUID
    ingredient: Optional[dict]
    quantity: Optional[str]
    unit: Optional[str]
    is_required: bool
    substitution_group: Optional[int]
    notes: Optional[str]

    class Config:
        from_attributes = True


class RecipeResponse(BaseModel):
    id: UUID
    name: str
    description: Optional[str]
    cuisine_id: UUID
    cuisine: Optional[dict]
    meal_types: Optional[List[str]]
    diet_type: str
    prep_time_minutes: int
    cook_time_minutes: int
    total_time_minutes: int
    difficulty: str
    servings: int
    instructions: str
    health_score: int
    health_category: str
    image_url: Optional[str]
    tags: Optional[List[str]]
    ingredients: List[RecipeIngredientResponse] = []

    class Config:
        from_attributes = True


class RecommendationRequest(BaseModel):
    meal_type: Optional[str] = None
    cuisine: Optional[str] = None
    intent: Optional[str] = None
    limit: int = 5


class RecommendationResponse(BaseModel):
    recipe: RecipeResponse
    score: float
    reasons: List[str]
    available_ingredients_count: int
    missing_ingredients_count: int
    missing_ingredients: List[str]
    use_soon_ingredients: List[str]


class SurpriseMeResponse(BaseModel):
    recipe: RecipeResponse
    reason: str


class MealHistoryCreate(BaseModel):
    recipe_id: UUID
    meal_type: str
    feedback: Optional[dict] = None


class MealDishCreate(BaseModel):
    name: str
    meal_type: str
    cuisine: Optional[str] = None
    health_category: Optional[str] = None
    diet_type: Optional[str] = None
    time_minutes: Optional[int] = 0
    description: Optional[str] = None


class MealHistoryResponse(BaseModel):
    id: UUID
    recipe_id: UUID
    recipe: Optional[RecipeResponse]
    meal_type: str
    cooked_date: datetime

    class Config:
        from_attributes = True


class MealFeedbackCreate(BaseModel):
    rating: Optional[int] = None
    liked: Optional[bool] = None
    family_liked: Optional[bool] = None
    kids_liked: Optional[bool] = None
    notes: Optional[str] = None


class SearchRequest(BaseModel):
    query: str
    limit: int = 10
