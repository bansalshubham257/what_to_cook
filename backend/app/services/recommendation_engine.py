import logging
from typing import Optional
from sqlalchemy.orm import Session
from uuid import UUID

from app.models.inventory import InventoryItem, InventoryStatus
from app.models.favorite import UserFavorite
from app.models.recipe import Recipe, RecipeIngredient
from app.models.meal import MealHistory
from app.models.ingredient import Ingredient
from app.models.user import User

logger = logging.getLogger(__name__)

RECOMMENDATION_WEIGHTS = {
    "ingredient_match_weight": 35.0,
    "preference_match_weight": 15.0,
    "meal_match_weight": 10.0,
    "cuisine_match_weight": 10.0,
    "freshness_priority_weight": 10.0,
    "variety_score_weight": 5.0,
    "time_match_weight": 5.0,
    "health_goal_match_weight": 5.0,
    "missing_ingredient_penalty": -15.0,
    "recent_meal_penalty": -20.0,
    "use_soon_bonus": 10.0,
    "favorite_bonus": 12.0,
}


def get_household_available_ingredient_ids(db: Session, household_id: UUID) -> set[UUID]:
    items = (
        db.query(InventoryItem)
        .filter(
            InventoryItem.household_id == household_id,
            InventoryItem.status.in_([InventoryStatus.AVAILABLE, InventoryStatus.LOW, InventoryStatus.USE_SOON]),
        )
        .all()
    )
    return {item.ingredient_id for item in items}


def get_household_use_soon_ids(db: Session, household_id: UUID) -> set[UUID]:
    items = (
        db.query(InventoryItem)
        .filter(
            InventoryItem.household_id == household_id,
            InventoryItem.status == InventoryStatus.USE_SOON,
        )
        .all()
    )
    return {item.ingredient_id for item in items}


def get_recent_recipe_ids(db: Session, household_id: UUID, days: int = 3) -> set[UUID]:
    from datetime import datetime, timedelta, timezone
    cutoff = datetime.now(timezone.utc) - timedelta(days=days)
    meals = (
        db.query(MealHistory)
        .filter(
            MealHistory.household_id == household_id,
            MealHistory.cooked_date >= cutoff,
        )
        .all()
    )
    return {m.recipe_id for m in meals}


def get_user_preferences(db: Session, user_id: UUID) -> dict:
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        return {}
    return {
        "diet_type": user.diet_type.value if user.diet_type else None,
    }


def score_recipe(
    db: Session,
    recipe: Recipe,
    available_ids: set[UUID],
    use_soon_ids: set[UUID],
    recent_ids: set[UUID],
    meal_type: Optional[str],
    favorite_ids: Optional[set[UUID]] = None,
) -> tuple[float, list[str], int, int, list[str]]:
    recipe_ingredients = (
        db.query(RecipeIngredient)
        .filter(RecipeIngredient.recipe_id == recipe.id)
        .all()
    )
    required_ingredients = [ri for ri in recipe_ingredients if ri.is_required]
    optional_ingredients = [ri for ri in recipe_ingredients if not ri.is_required]

    available_required = sum(1 for ri in required_ingredients if ri.ingredient_id in available_ids)
    total_required = len(required_ingredients) if required_ingredients else 1
    missing_required = total_required - available_required

    use_soon_in_recipe = [ri for ri in required_ingredients if ri.ingredient_id in use_soon_ids]
    use_soon_names = []
    for ri in use_soon_in_recipe:
        ing = db.query(Ingredient).filter(Ingredient.id == ri.ingredient_id).first()
        if ing:
            use_soon_names.append(ing.display_name_en)

    score = 50.0
    ingredient_match = (available_required / total_required) * RECOMMENDATION_WEIGHTS["ingredient_match_weight"]
    score += ingredient_match

    if missing_required > 0:
        penalty = RECOMMENDATION_WEIGHTS["missing_ingredient_penalty"] * missing_required
        score += penalty

    if use_soon_in_recipe:
        score += RECOMMENDATION_WEIGHTS["use_soon_bonus"]

    if favorite_ids and recipe.id in favorite_ids:
        score += RECOMMENDATION_WEIGHTS["favorite_bonus"]

    if meal_type:
        if recipe.meal_types and meal_type in recipe.meal_types:
            score += RECOMMENDATION_WEIGHTS["meal_match_weight"]
        else:
            score -= 100.0

    if recipe.id in recent_ids:
        score += RECOMMENDATION_WEIGHTS["recent_meal_penalty"]

    if recipe.total_time_minutes and recipe.total_time_minutes <= 30:
        score += RECOMMENDATION_WEIGHTS["time_match_weight"]

    score = max(0, min(100, score))

    reasons = []
    if missing_required == 0:
        reasons.append("All ingredients available")
    elif missing_required == 1:
        reasons.append("Only 1 ingredient missing")
    else:
        reasons.append(f"{missing_required} ingredients needed")

    if use_soon_names:
        reasons.append(f"{', '.join(use_soon_names)} should be used soon")
    if recipe.id not in recent_ids:
        reasons.append("Not cooked recently")
    if recipe.total_time_minutes and recipe.total_time_minutes <= 30:
        reasons.append(f"Quick meal ({recipe.total_time_minutes} min)")
    if favorite_ids and recipe.id in favorite_ids:
        reasons.append("In your favourites")

    return score, reasons, available_required, missing_required, use_soon_names


def _intent_filter(recipe: Recipe, intent: str) -> bool:
    if not intent:
        return True
    intent = intent.lower()
    if intent == "healthy":
        return recipe.health_score and recipe.health_score >= 65
    if intent == "quick":
        return recipe.total_time_minutes and recipe.total_time_minutes <= 30
    if intent == "indulgent":
        return recipe.health_category and recipe.health_category.value == "indulgent"
    if intent in ("roti_sabzi", "rice", "kids"):
        tags_lower = {str(t).lower() for t in (recipe.tags or []) if t}
        return intent in tags_lower
    return True


def get_recommendations(
    db: Session,
    household_id: UUID,
    user_id: UUID,
    meal_type: Optional[str] = None,
    cuisine: Optional[str] = None,
    intent: Optional[str] = None,
    limit: int = 5,
) -> list[dict]:
    available_ids = get_household_available_ingredient_ids(db, household_id)
    use_soon_ids = get_household_use_soon_ids(db, household_id)
    recent_ids = get_recent_recipe_ids(db, household_id)
    favorite_ids = {
        r[0] for r in db.query(UserFavorite.recipe_id)
        .filter(UserFavorite.user_id == user_id).all()
    }

    recipes = (
        db.query(Recipe)
        .filter(Recipe.is_active == True)
        .all()
    )

    scored = []
    for recipe in recipes:
        if not _intent_filter(recipe, intent):
            continue
        s, reasons, avail, missing, use_soon = score_recipe(
            db, recipe, available_ids, use_soon_ids, recent_ids, meal_type, favorite_ids
        )
        missing_ingredient_names = _get_missing_ingredient_names(db, recipe.id, available_ids)
        scored.append({
            "recipe": recipe,
            "score": round(s, 1),
            "reasons": reasons,
            "available_count": avail,
            "missing_count": missing,
            "missing_ingredients": missing_ingredient_names,
            "use_soon_ingredients": use_soon,
        })

    scored.sort(key=lambda x: x["score"], reverse=True)
    return scored[:limit]


def get_missing_ingredient_opportunities(
    db: Session,
    household_id: UUID,
    limit: int = 10,
) -> list[dict]:
    available_ids = get_household_available_ingredient_ids(db, household_id)
    recipes = db.query(Recipe).filter(Recipe.is_active == True).all()

    opportunities = []
    for recipe in recipes:
        recipe_ingredients = (
            db.query(RecipeIngredient)
            .filter(RecipeIngredient.recipe_id == recipe.id, RecipeIngredient.is_required == True)
            .all()
        )
        total = len(recipe_ingredients)
        available = sum(1 for ri in recipe_ingredients if ri.ingredient_id in available_ids)
        missing = total - available

        if 1 <= missing <= 3:
            missing_ingredients = _get_missing_ingredient_names(db, recipe.id, available_ids)
            opportunities.append({
                "recipe_id": recipe.id,
                "recipe_name": recipe.name,
                "available_count": available,
                "missing_count": missing,
                "missing_ingredients": missing_ingredients,
            })

    opportunities.sort(key=lambda x: x["missing_count"])
    return opportunities[:limit]


def get_surprise_me(
    db: Session,
    household_id: UUID,
    user_id: UUID,
) -> dict | None:
    recs = get_recommendations(db, household_id, user_id, limit=1)
    if recs:
        r = recs[0]
        return {
            "recipe": r["recipe"],
            "reason": f"Everything is available, takes about {r['recipe'].total_time_minutes} minutes, and you haven't cooked it recently.",
        }
    return None


def _get_missing_ingredient_names(db: Session, recipe_id: UUID, available_ids: set[UUID]) -> list[str]:
    missing = (
        db.query(RecipeIngredient, Ingredient)
        .join(Ingredient, RecipeIngredient.ingredient_id == Ingredient.id)
        .filter(
            RecipeIngredient.recipe_id == recipe_id,
            RecipeIngredient.is_required == True,
            ~RecipeIngredient.ingredient_id.in_(available_ids),
        )
        .all()
    )
    return [ing.display_name_en for _, ing in missing]
