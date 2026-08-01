from pydantic import BaseModel
from typing import Optional, List, Dict
from uuid import UUID
from datetime import datetime


class MealStats(BaseModel):
    total_meals: int
    balanced_count: int
    moderate_count: int
    indulgent_count: int
    balanced_percent: float
    moderate_percent: float
    indulgent_percent: float


class WeeklyReport(BaseModel):
    start_date: datetime
    end_date: datetime
    meals_logged: int
    home_cooked_meals: int
    meal_stats: MealStats
    healthy_streak_days: int
    most_cooked_dish: Optional[str]
    cuisine_distribution: Dict[str, int]
    vegetables_used: int
    food_waste_prevented_count: int


class MonthlyReport(BaseModel):
    month: str
    year: int
    total_meals: int
    meal_stats: MealStats
    most_cooked_dish: Optional[str]
    vegetables_used: int
    cuisine_distribution: Dict[str, int]
    cooking_streak: int
    food_waste_prevented_count: int
    previous_month_comparison: Optional[Dict] = None


class BalanceMyWeekResponse(BaseModel):
    recent_pattern: str
    suggestion: str
    recommended_intent: str
