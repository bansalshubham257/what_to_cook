from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.api.deps import get_current_user, get_current_household
from app.models.user import User
from app.models.household import Household
from app.models.meal import MealHistory
from app.models.recipe import Recipe
from app.models.ingredient import Ingredient, IngredientCategoryType
from app.models.recipe import RecipeIngredient
from app.services.health_scoring import get_weekly_meal_stats
from datetime import datetime, timedelta, timezone

router = APIRouter(prefix="/insights", tags=["Insights"])


@router.get("/weekly")
def weekly_insights(
    current_user: User = Depends(get_current_user),
    household: Household = Depends(get_current_household),
    db: Session = Depends(get_db),
):
    stats = get_weekly_meal_stats(db, household.id)
    return {"period": "7_days", **stats}


@router.get("/monthly")
def monthly_insights(
    month: int = None,
    year: int = None,
    current_user: User = Depends(get_current_user),
    household: Household = Depends(get_current_household),
    db: Session = Depends(get_db),
):
    now = datetime.now(timezone.utc)
    month = month or now.month
    year = year or now.year

    start_date = datetime(year, month, 1, tzinfo=timezone.utc)
    if month == 12:
        end_date = datetime(year + 1, 1, 1, tzinfo=timezone.utc)
    else:
        end_date = datetime(year, month + 1, 1, tzinfo=timezone.utc)

    meals = (
        db.query(MealHistory, Recipe)
        .join(Recipe, MealHistory.recipe_id == Recipe.id)
        .filter(
            MealHistory.household_id == household.id,
            MealHistory.cooked_date >= start_date,
            MealHistory.cooked_date < end_date,
        )
        .all()
    )

    total = len(meals)
    balanced = sum(1 for _, r in meals if r.health_category and r.health_category.value == "balanced")
    moderate = sum(1 for _, r in meals if r.health_category and r.health_category.value == "moderate")
    indulgent = sum(1 for _, r in meals if r.health_category and r.health_category.value == "indulgent")

    cuisine_counts = {}
    recipe_counts = {}
    for _, recipe in meals:
        cuisine_id = str(recipe.cuisine_id)
        cuisine_counts[cuisine_id] = cuisine_counts.get(cuisine_id, 0) + 1
        recipe_counts[recipe.name] = recipe_counts.get(recipe.name, 0) + 1

    most_cooked = max(recipe_counts, key=recipe_counts.get) if recipe_counts else None

    veg_set = set()
    for _, recipe in meals:
        req_ings = (
            db.query(RecipeIngredient)
            .filter(RecipeIngredient.recipe_id == recipe.id, RecipeIngredient.is_required == True)
            .all()
        )
        for ri in req_ings:
            ing = db.query(Ingredient).filter(Ingredient.id == ri.ingredient_id).first()
            if ing and ing.category == IngredientCategoryType.VEGETABLE:
                veg_set.add(ing.name)

    return {
        "month": month,
        "year": year,
        "total_meals": total,
        "balanced_count": balanced,
        "moderate_count": moderate,
        "indulgent_count": indulgent,
        "balanced_percent": round(balanced / total * 100, 1) if total else 0,
        "moderate_percent": round(moderate / total * 100, 1) if total else 0,
        "indulgent_percent": round(indulgent / total * 100, 1) if total else 0,
        "most_cooked_dish": most_cooked,
        "vegetables_used": len(veg_set),
        "cuisine_distribution": cuisine_counts,
    }


@router.get("/balance")
def balance_my_week(
    current_user: User = Depends(get_current_user),
    household: Household = Depends(get_current_household),
    db: Session = Depends(get_db),
):
    stats = get_weekly_meal_stats(db, household.id)

    if stats["indulgent_percent"] > 50:
        suggestion = "Your logged meals contained more indulgent choices this week. Try balancing with lighter meals."
        recommended_intent = "healthy"
    elif stats["balanced_percent"] > 60:
        suggestion = "Great balance this week! Keep up the variety."
        recommended_intent = "balanced"
    else:
        suggestion = "Your week has a good mix of meals."
        recommended_intent = "mixed"

    pattern = "indulgent" if stats["indulgent_percent"] > stats["balanced_percent"] else "balanced"

    return {
        "recent_pattern": pattern,
        "suggestion": suggestion,
        "recommended_intent": recommended_intent,
    }


@router.get("/cuisine-distribution")
def cuisine_distribution(
    days: int = 30,
    current_user: User = Depends(get_current_user),
    household: Household = Depends(get_current_household),
    db: Session = Depends(get_db),
):
    cutoff = datetime.now(timezone.utc) - timedelta(days=days)
    meals = (
        db.query(MealHistory, Recipe)
        .join(Recipe, MealHistory.recipe_id == Recipe.id)
        .filter(
            MealHistory.household_id == household.id,
            MealHistory.cooked_date >= cutoff,
        )
        .all()
    )

    cuisine_map = {}
    for _, recipe in meals:
        from app.models.recipe import Cuisine
        cuisine = db.query(Cuisine).filter(Cuisine.id == recipe.cuisine_id).first()
        name = cuisine.display_name_en if cuisine else "Unknown"
        cuisine_map[name] = cuisine_map.get(name, 0) + 1

    return {"cuisines": cuisine_map}
