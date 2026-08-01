import json
import logging
from datetime import datetime, timedelta, timezone
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.api.deps import get_current_user, get_current_household
from app.models.user import User
from app.models.household import Household
from app.models.recipe import Recipe
from app.models.favorite import UserFavorite
from app.models.recommendation_history import RecommendationHistory
from app.services.recommendation_engine import (
    get_recommendations,
    get_missing_ingredient_opportunities,
    get_surprise_me,
)
from app.services.ai_service import get_ai_client, AI_PROVIDER
from app.core.config import settings
from app.schemas.recipe import RecommendationRequest, SurpriseMeResponse

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/recommendations", tags=["Recommendations"])


@router.get("/")
def recommend(
    meal_type: str = None,
    cuisine: str = None,
    intent: str = None,
    limit: int = Query(default=5, le=10),
    current_user: User = Depends(get_current_user),
    household: Household = Depends(get_current_household),
    db: Session = Depends(get_db),
):
    recs = get_recommendations(
        db,
        household.id,
        current_user.id,
        meal_type=meal_type,
        cuisine=cuisine,
        intent=intent,
        limit=limit,
    )

    result = []
    for r in recs:
        recipe = r["recipe"]
        result.append({
            "recipe": {
                "id": str(recipe.id),
                "name": recipe.name,
                "description": recipe.description,
                "cuisine_id": str(recipe.cuisine_id) if recipe.cuisine_id else None,
                "meal_types": recipe.meal_types,
                "diet_type": recipe.diet_type.value if recipe.diet_type else None,
                "prep_time_minutes": recipe.prep_time_minutes,
                "cook_time_minutes": recipe.cook_time_minutes,
                "total_time_minutes": recipe.total_time_minutes,
                "difficulty": recipe.difficulty.value if recipe.difficulty else None,
                "servings": recipe.servings,
                "health_score": recipe.health_score,
                "health_category": recipe.health_category.value if recipe.health_category else None,
                "image_url": recipe.image_url,
            },
            "score": r["score"],
            "reasons": r["reasons"],
            "available_ingredients_count": r["available_count"],
            "missing_ingredients_count": r["missing_count"],
            "missing_ingredients": r["missing_ingredients"],
            "use_soon_ingredients": r["use_soon_ingredients"],
        })

    return {"recommendations": result}


@router.get("/missing-ingredients")
def missing_ingredients(
    limit: int = Query(default=10, le=20),
    current_user: User = Depends(get_current_user),
    household: Household = Depends(get_current_household),
    db: Session = Depends(get_db),
):
    opps = get_missing_ingredient_opportunities(db, household.id, limit)
    return {"opportunities": opps}


@router.get("/surprise-me")
def surprise_me(
    current_user: User = Depends(get_current_user),
    household: Household = Depends(get_current_household),
    db: Session = Depends(get_db),
):
    result = get_surprise_me(db, household.id, current_user.id)
    if not result:
        return {"message": "No recommendations available", "recipe": None}
    recipe = result["recipe"]
    return {
        "recipe": {
            "id": str(recipe.id),
            "name": recipe.name,
            "description": recipe.description,
            "total_time_minutes": recipe.total_time_minutes,
            "difficulty": recipe.difficulty.value if recipe.difficulty else None,
            "image_url": recipe.image_url,
        },
        "reason": result["reason"],
    }


@router.get("/ai")
def ai_recommend(
    meal_type: str = None,
    intent: str = None,
    limit: int = Query(default=5, le=10),
    current_user: User = Depends(get_current_user),
    household: Household = Depends(get_current_household),
    db: Session = Depends(get_db),
):
    today = datetime.now(timezone.utc).date()

    favorite_ids = {
        r[0] for r in db.query(UserFavorite.recipe_id)
        .filter(UserFavorite.user_id == current_user.id)
        .all()
    }

    engine_recs = get_recommendations(
        db, household.id, current_user.id,
        meal_type=meal_type, intent=intent, limit=10,
    )

    candidate_recipes = [{
        "id": str(r["recipe"].id),
        "name": r["recipe"].name,
        "meal_types": r["recipe"].meal_types or [],
        "cuisine": str(r["recipe"].cuisine_id) if r["recipe"].cuisine_id else "",
        "diet_type": r["recipe"].diet_type.value if r["recipe"].diet_type else "",
        "total_time": r["recipe"].total_time_minutes or 0,
        "is_favorite": r["recipe"].id in favorite_ids,
        "score": r["score"],
        "reasons": r["reasons"],
        "available_count": r["available_count"],
        "missing_count": r["missing_count"],
        "missing_ingredients": r["missing_ingredients"],
        "use_soon_ingredients": r["use_soon_ingredients"],
    } for r in engine_recs]

    if not candidate_recipes:
        return {"recommendations": []}

    selected = candidate_recipes[:limit]

    if AI_PROVIDER != "mock":
        try:
            client = get_ai_client()
            candidates_text = "\n".join(
                f"{r['id']}|{r['name']}|{','.join(r['meal_types'])}|{r['cuisine']}|{r['diet_type']}|{r['total_time']}min|{'favorite' if r['is_favorite'] else ''}"
                for r in candidate_recipes
            )
            prompt = f"""Pick {limit} diverse recipes from this list. Prefer recipes marked 'favorite' while keeping variety. Return ONLY a JSON array of IDs.

{candidates_text}"""
            response = client.chat.completions.create(
                model=settings.AI_MODEL,
                messages=[
                    {"role": "system", "content": "You are a chef. Return only valid JSON arrays, no other text."},
                    {"role": "user", "content": prompt},
                ],
                temperature=0.8,
                max_tokens=500,
            )
            content = response.choices[0].message.content.strip()
            if "[" in content and "]" in content:
                start = content.index("[")
                end = content.rindex("]") + 1
                content = content[start:end]
            ai_ids = json.loads(content)
            id_to_rec = {r["id"]: r for r in candidate_recipes}
            ai_selected = [id_to_rec[rid] for rid in ai_ids if rid in id_to_rec]
            if ai_selected:
                selected = ai_selected
        except Exception as e:
            logger.error(f"AI recommendation error: {e}")

    for r in selected:
        hist = RecommendationHistory(
            user_id=current_user.id,
            recipe_id=r["id"],
            recommended_date=today,
        )
        db.add(hist)
    db.commit()

    return {
        "recommendations": [{
            "recipe": {
                "id": r["id"],
                "name": r["name"],
                "meal_types": r["meal_types"],
                "total_time_minutes": r["total_time"],
            },
            "score": r["score"],
            "reasons": r["reasons"],
            "available_ingredients_count": r["available_count"],
            "missing_ingredients_count": r["missing_count"],
            "missing_ingredients": r["missing_ingredients"],
            "use_soon_ingredients": r["use_soon_ingredients"],
            "is_favorite": r["is_favorite"],
        } for r in selected],
    }
