from app.models.recipe import Recipe, HealthCategory, RecipeIngredient
from app.models.ingredient import Ingredient, IngredientCategoryType
from app.models.meal import MealHistory, MealType
from sqlalchemy.orm import Session
from uuid import UUID
from datetime import datetime, timedelta, timezone
import logging

logger = logging.getLogger(__name__)


def calculate_recipe_health_score(recipe: Recipe, db: Session) -> int:
    score = 50

    recipe_ingredients = db.query(RecipeIngredient).filter(
        RecipeIngredient.recipe_id == recipe.id,
        RecipeIngredient.is_required == True,
    ).all()

    ingredient_ids = [ri.ingredient_id for ri in recipe_ingredients]
    ingredients = db.query(Ingredient).filter(Ingredient.id.in_(ingredient_ids)).all()

    categories = {ing.category for ing in ingredients}

    if IngredientCategoryType.VEGETABLE in categories:
        score += 10
    if IngredientCategoryType.PULSE in categories:
        score += 10
    if IngredientCategoryType.GRAIN in categories:
        score += 5
    if IngredientCategoryType.FRUIT in categories:
        score += 5
    if IngredientCategoryType.MEAT in categories:
        score += 5

    fried_keywords = ["fried", "deep fry", "tali", "talna", "bhujiya"]
    recipe_text = f"{recipe.name} {recipe.description or ''} {recipe.instructions}".lower()
    if any(kw in recipe_text for kw in fried_keywords):
        score -= 15

    sugar_keywords = ["sugar", "mithai", "sweet", "shakkar", "cheeni"]
    if any(kw in recipe_text for kw in sugar_keywords):
        score -= 5

    if recipe.health_score:
        score = (score + recipe.health_score) // 2

    return max(0, min(100, score))


def get_health_category(score: int) -> HealthCategory:
    if score >= 65:
        return HealthCategory.BALANCED
    elif score >= 40:
        return HealthCategory.MODERATE
    else:
        return HealthCategory.INDULGENT


def get_weekly_meal_stats(db: Session, household_id: UUID) -> dict:
    end_date = datetime.now(timezone.utc)
    start_date = end_date - timedelta(days=7)

    meals = (
        db.query(MealHistory)
        .filter(
            MealHistory.household_id == household_id,
            MealHistory.cooked_date >= start_date,
            MealHistory.cooked_date <= end_date,
        )
        .all()
    )

    total = len(meals)
    balanced = 0
    moderate = 0
    indulgent = 0

    for meal in meals:
        recipe = db.query(Recipe).filter(Recipe.id == meal.recipe_id).first()
        if recipe:
            if recipe.health_category == HealthCategory.BALANCED:
                balanced += 1
            elif recipe.health_category == HealthCategory.MODERATE:
                moderate += 1
            elif recipe.health_category == HealthCategory.INDULGENT:
                indulgent += 1

    return {
        "total_meals": total,
        "balanced_count": balanced,
        "moderate_count": moderate,
        "indulgent_count": indulgent,
        "balanced_percent": round(balanced / total * 100, 1) if total else 0,
        "moderate_percent": round(moderate / total * 100, 1) if total else 0,
        "indulgent_percent": round(indulgent / total * 100, 1) if total else 0,
    }


def get_meal_distribution(db: Session, household_id: UUID, start_date: datetime, end_date: datetime) -> dict:
    meals = (
        db.query(MealHistory)
        .filter(
            MealHistory.household_id == household_id,
            MealHistory.cooked_date >= start_date,
            MealHistory.cooked_date <= end_date,
        )
        .all()
    )

    cuisine_counts = {}
    veg_count = 0

    for meal in meals:
        recipe = db.query(Recipe).filter(Recipe.id == meal.recipe_id).first()
        if recipe:
            cuisine_name = str(recipe.cuisine_id)
            cuisine_counts[cuisine_name] = cuisine_counts.get(cuisine_name, 0) + 1

            recipe_ings = db.query(RecipeIngredient).filter(
                RecipeIngredient.recipe_id == recipe.id,
                RecipeIngredient.is_required == True,
            ).all()
            for ri in recipe_ings:
                ing = db.query(Ingredient).filter(Ingredient.id == ri.ingredient_id).first()
                if ing and ing.category == IngredientCategoryType.VEGETABLE:
                    veg_count += 1
                    break

    return {
        "cuisine_distribution": cuisine_counts,
        "vegetables_used": veg_count,
    }



