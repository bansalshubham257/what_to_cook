from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.api.deps import get_current_user, get_current_household
from app.models.user import User
from app.models.household import Household
from app.models.meal import MealHistory, MealFeedback, MealType
from app.models.recipe import Recipe
from app.schemas.recipe import MealHistoryCreate, MealFeedbackCreate, MealDishCreate
from app.crud.inventory_crud import get_inventory, upsert_inventory_item, delete_inventory_item
from datetime import datetime, timezone
from uuid import UUID

router = APIRouter(prefix="/meals", tags=["Meals"])


@router.post("/log")
def log_meal(
    meal_data: MealHistoryCreate,
    current_user: User = Depends(get_current_user),
    household: Household = Depends(get_current_household),
    db: Session = Depends(get_db),
):
    recipe = db.query(Recipe).filter(Recipe.id == meal_data.recipe_id).first()
    if not recipe:
        raise HTTPException(status_code=404, detail="Recipe not found")

    meal = MealHistory(
        household_id=household.id,
        recipe_id=meal_data.recipe_id,
        meal_type=MealType(meal_data.meal_type),
        cooked_by=current_user.id,
        cooked_date=datetime.now(timezone.utc),
    )
    db.add(meal)
    db.commit()
    db.refresh(meal)

    if meal_data.feedback:
        feedback = MealFeedback(
            meal_history_id=meal.id,
            user_id=current_user.id,
            **meal_data.feedback,
        )
        db.add(feedback)
        db.commit()

    return {
        "message": "Meal logged successfully",
        "meal_id": str(meal.id),
    }


@router.post("/log-dish")
def log_dish(
    meal_data: MealDishCreate,
    current_user: User = Depends(get_current_user),
    household: Household = Depends(get_current_household),
    db: Session = Depends(get_db),
):
    """Logs a curated/user dish that may not exist in the recipes table yet.

    Finds a recipe by name; if missing, creates one using the details the app
    already has for the dish, so insights (computed from meal_history joined to
    recipes) reflect curated meals too.
    """
    from app.models.recipe import (
        Recipe,
        Cuisine,
        DietType,
        HealthCategory,
        DifficultyLevel,
    )

    name = meal_data.name.strip()
    if not name:
        raise HTTPException(status_code=422, detail="Dish name is required")

    recipe = db.query(Recipe).filter(Recipe.name == name).first()

    if not recipe:
        cuisine = None
        if meal_data.cuisine:
            cuisine = (
                db.query(Cuisine)
                .filter(Cuisine.name == meal_data.cuisine, Cuisine.is_active == True)
                .first()
            )
        if not cuisine:
            cuisine = (
                db.query(Cuisine).filter(Cuisine.is_active == True).order_by(Cuisine.sort_order).first()
            )

        diet = DietType.VEGETARIAN
        if meal_data.diet_type:
            try:
                diet = DietType(meal_data.diet_type)
            except ValueError:
                diet = DietType.VEGETARIAN

        health = None
        if meal_data.health_category:
            try:
                health = HealthCategory(meal_data.health_category)
            except ValueError:
                health = None

        recipe = Recipe(
            name=name,
            description=meal_data.description,
            cuisine_id=cuisine.id if cuisine else None,
            meal_types=[meal_data.meal_type],
            diet_type=diet,
            total_time_minutes=meal_data.time_minutes or 0,
            difficulty=DifficultyLevel.MEDIUM,
            instructions="",
            health_category=health or HealthCategory.MODERATE,
            source="curated",
            is_active=True,
        )
        db.add(recipe)
        db.flush()

    meal = MealHistory(
        household_id=household.id,
        recipe_id=recipe.id,
        meal_type=MealType(meal_data.meal_type),
        cooked_by=current_user.id,
        cooked_date=datetime.now(timezone.utc),
    )
    db.add(meal)
    db.commit()
    db.refresh(meal)

    return {
        "message": "Meal logged successfully",
        "meal_id": str(meal.id),
        "recipe_id": str(recipe.id),
    }


@router.post("/{meal_id}/feedback")
def provide_feedback(
    meal_id: str,
    feedback_data: MealFeedbackCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    meal = db.query(MealHistory).filter(MealHistory.id == meal_id).first()
    if not meal:
        raise HTTPException(status_code=404, detail="Meal not found")

    feedback = MealFeedback(
        meal_history_id=meal.id,
        user_id=current_user.id,
        **feedback_data.model_dump(exclude_none=True),
    )
    db.add(feedback)
    db.commit()

    return {"message": "Feedback recorded"}


@router.get("/history")
def get_meal_history(
    days: int = 30,
    current_user: User = Depends(get_current_user),
    household: Household = Depends(get_current_household),
    db: Session = Depends(get_db),
):
    from datetime import timedelta
    cutoff = datetime.now(timezone.utc) - timedelta(days=days)
    meals = (
        db.query(MealHistory, Recipe)
        .join(Recipe, MealHistory.recipe_id == Recipe.id)
        .filter(
            MealHistory.household_id == household.id,
            MealHistory.cooked_date >= cutoff,
        )
        .order_by(MealHistory.cooked_date.desc())
        .all()
    )

    return {
        "meals": [
            {
                "id": str(meal.id),
                "recipe_id": str(recipe.id),
                "recipe_name": recipe.name,
                "recipe_image": recipe.image_url,
                "meal_type": meal.meal_type.value,
                "cooked_date": meal.cooked_date.isoformat(),
                "health_category": recipe.health_category.value if recipe.health_category else None,
            }
            for meal, recipe in meals
        ]
    }


@router.post("/{meal_id}/update-inventory")
def update_inventory_after_cooking(
    meal_id: str,
    used_ingredients: list[dict],
    current_user: User = Depends(get_current_user),
    household: Household = Depends(get_current_household),
    db: Session = Depends(get_db),
):
    meal = db.query(MealHistory).filter(MealHistory.id == meal_id).first()
    if not meal:
        raise HTTPException(status_code=404, detail="Meal not found")

    for item in used_ingredients:
        ingredient_id = UUID(item["ingredient_id"])
        status = item.get("status", "finished")

        if status == "finished":
            delete_inventory_item(db, household.id, ingredient_id)
        elif status == "low":
            upsert_inventory_item(db, household.id, ingredient_id, "low")
        elif status == "still_have":
            upsert_inventory_item(db, household.id, ingredient_id, "available")

    return {"message": "Inventory updated after cooking"}
