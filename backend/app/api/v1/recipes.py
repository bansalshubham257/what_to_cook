from fastapi import APIRouter, Depends, Query, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import and_, or_, cast, String, func
from app.core.database import get_db
from app.api.deps import get_current_user
from app.models.user import User
from app.models.recipe import Recipe, RecipeIngredient, Cuisine
from app.models.ingredient import Ingredient
from app.models.favorite import UserFavorite
from app.services.ai_service import parse_inventory_text, generate_recipe_json

router = APIRouter(prefix="/recipes", tags=["Recipes"])

CUISINE_KEYWORDS = {
    "north_indian": ["north indian", "northindian"],
    "south_indian": ["south indian", "southindian"],
    "punjabi": ["punjabi", "punjab"],
    "bengali": ["bengali", "bengal"],
    "odia": ["odia", "odisha"],
    "gujarati": ["gujarati", "gujarat"],
    "rajasthani": ["rajasthani", "rajasthan"],
    "maharashtrian": ["maharashtrian", "maharashtra"],
    "indo_chinese": ["indo chinese", "indochinese", "indo-chinese", "indian chinese"],
    "continental": ["continental"],
    "assamese": ["assamese", "assam"],
    "awadhi": ["awadhi", "lucknowi", "lucknow"],
    "bihari": ["bihari", "bihar"],
    "goan": ["goan", "goa"],
    "haryanvi": ["haryanvi", "haryana"],
    "himachali": ["himachali", "himachal", "pahadi"],
    "hyderabadi": ["hyderabadi", "hyderabad"],
    "jharkhandi": ["jharkhandi", "jharkhand"],
    "karnataka": ["karnataka", "kannada", "mangalorean"],
    "kashmiri": ["kashmiri", "kashmir"],
    "kerala": ["kerala", "keralite", "kuttanad"],
    "manipuri": ["manipuri", "manipur"],
    "muglai": ["muglai", "mughlai"],
    "naga": ["naga", "nagaland"],
    "nepali": ["nepali", "nepal"],
    "parsi": ["parsi", "parsi"],
    "sindhi": ["sindhi", "sindh"],
    "tamil": ["tamil", "tamil nadu", "tamilnadu", "chettinad"],
    "telugu": ["telugu", "andhra", "hyderabadi"],
    "uttarakhandi": ["uttarakhandi", "uttarakhand", "kumaoni", "garhwali"],
    "italian": ["italian", "italy", "pizza", "pasta"],
    "french": ["french", "france"],
    "thai": ["thai", "thailand"],
    "chinese": ["chinese", "china", "szechuan", "schezwan", "hakka"],
    "mexican": ["mexican", "mexico", "taco", "burrito"],
    "japanese": ["japanese", "japan", "sushi", "ramen"],
    "mediterranean": ["mediterranean", "mediterranian", "greek"],
    "korean": ["korean", "korea", "kimchi"],
    "vietnamese": ["vietnamese", "vietnam", "pho"],
}


def _extract_cuisine_terms(raw_query):
    lowered = raw_query.lower().strip()
    matched_slugs = []
    remaining = lowered
    for slug, keywords in CUISINE_KEYWORDS.items():
        for kw in keywords:
            if kw in remaining:
                matched_slugs.append(slug)
                remaining = remaining.replace(kw, " ")
                break
    return matched_slugs, remaining


@router.get("/cuisines")
def list_cuisines(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    rows = (
        db.query(Cuisine, func.count(Recipe.id).label("recipe_count"))
        .outerjoin(Recipe, Recipe.cuisine_id == Cuisine.id)
        .filter(Recipe.is_active == True)
        .group_by(Cuisine.id)
        .order_by(Cuisine.name)
        .all()
    )
    return {
        "cuisines": [
            {
                "name": c.name,
                "display_name": c.display_name_en,
                "recipe_count": count,
            }
            for c, count in rows
        ]
    }


@router.get("/search")
def search_recipes(
    q: str = Query(default=""),
    meal_type: str = None,
    cuisine: str = None,
    diet_type: str = None,
    max_time: int = None,
    favorites: int = Query(default=0),
    limit: int = Query(default=20, le=50),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    query = db.query(Recipe).filter(Recipe.is_active == True)

    if favorites:
        fav_ids = (
            db.query(UserFavorite.recipe_id)
            .filter(UserFavorite.user_id == current_user.id)
            .all()
        )
        ids = [r[0] for r in fav_ids]
        if not ids:
            return {"recipes": []}
        query = query.filter(Recipe.id.in_(ids))

    if q:
        cuisine_slugs, remaining = _extract_cuisine_terms(q)
        if cuisine_slugs:
            cuisine_ids = [
                c[0] for c in db.query(Cuisine.id).filter(Cuisine.name.in_(cuisine_slugs)).all()
            ]
            if cuisine_ids:
                query = query.filter(Recipe.cuisine_id.in_(cuisine_ids))
        terms = [t.strip() for t in remaining.split() if t.strip()]
        if terms:
            text_terms = []
            for term in terms:
                if term == "healthy":
                    query = query.filter(Recipe.health_category == "balanced")
                elif term == "quick":
                    query = query.filter(Recipe.total_time_minutes <= 30)
                elif term == "veg":
                    query = query.filter(Recipe.diet_type == "vegetarian")
                elif term in ("non-veg", "non_veg", "nonveg"):
                    query = query.filter(Recipe.diet_type == "non_vegetarian")
                elif term in ("breakfast", "lunch", "dinner", "snacks"):
                    query = query.filter(Recipe.meal_types.any(term))
                elif term in ("sweet", "dessert"):
                    query = query.filter(Recipe.tags.any(term))
                elif term == "kids":
                    query = query.filter(Recipe.tags.any(term))
                else:
                    text_terms.append(term)
            if text_terms:
                filters = []
                for term in text_terms:
                    search_term = f"%{term}%"
                    filters.append(
                        Recipe.name.ilike(search_term)
                        | Recipe.description.ilike(search_term)
                        | Recipe.tags.any(term)
                        | Recipe.meal_types.any(term)
                        | cast(Recipe.health_category, String).ilike(search_term)
                    )
                query = query.filter(and_(*filters))
    if cuisine:
        cuisine_row = db.query(Cuisine).filter(Cuisine.name == cuisine, Cuisine.is_active == True).first()
        if not cuisine_row:
            return {"recipes": []}
        query = query.filter(Recipe.cuisine_id == cuisine_row.id)
    if meal_type:
        query = query.filter(Recipe.meal_types.any(meal_type))
    if diet_type:
        query = query.filter(Recipe.diet_type == diet_type)
    if max_time:
        query = query.filter(Recipe.total_time_minutes <= max_time)

    recipes = query.order_by(Recipe.name).limit(limit).all()

    return {
        "recipes": [
            {
                "id": str(r.id),
                "name": r.name,
                "description": r.description,
                "total_time_minutes": r.total_time_minutes,
                "difficulty": r.difficulty.value if r.difficulty else None,
                "diet_type": r.diet_type.value if r.diet_type else None,
                "health_category": r.health_category.value if r.health_category else None,
                "image_url": r.image_url,
            }
            for r in recipes
        ]
    }


@router.get("/favorites")
def get_favorites(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    favorites = (
        db.query(Recipe)
        .join(UserFavorite, UserFavorite.recipe_id == Recipe.id)
        .filter(UserFavorite.user_id == current_user.id, Recipe.is_active == True)
        .order_by(UserFavorite.created_at.desc())
        .all()
    )
    cuisine_map = {c.id: c.display_name_en for c in db.query(Cuisine).all()}
    return {
        "recipes": [
            {
                "id": str(r.id),
                "name": r.name,
                "description": r.description,
                "total_time_minutes": r.total_time_minutes,
                "difficulty": r.difficulty.value if r.difficulty else None,
                "diet_type": r.diet_type.value if r.diet_type else None,
                "health_category": r.health_category.value if r.health_category else None,
                "image_url": r.image_url,
                "cuisine_name": cuisine_map.get(r.cuisine_id),
                "meal_types": r.meal_types,
            }
            for r in favorites
        ]
    }


@router.get("/favorites/ids")
def get_favorite_ids(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    rows = (
        db.query(UserFavorite.recipe_id)
        .filter(UserFavorite.user_id == current_user.id)
        .all()
    )
    return {"ids": [str(r[0]) for r in rows]}


@router.post("/{recipe_id}/favorite")
def add_favorite(
    recipe_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    recipe = db.query(Recipe).filter(Recipe.id == recipe_id, Recipe.is_active == True).first()
    if not recipe:
        raise HTTPException(status_code=404, detail="Recipe not found")

    existing = (
        db.query(UserFavorite)
        .filter(UserFavorite.user_id == current_user.id, UserFavorite.recipe_id == recipe_id)
        .first()
    )
    if existing:
        return {"message": "Already favorited"}

    fav = UserFavorite(user_id=current_user.id, recipe_id=recipe_id)
    db.add(fav)
    db.commit()
    return {"message": "Recipe favorited"}


@router.delete("/{recipe_id}/favorite")
def remove_favorite(
    recipe_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    fav = (
        db.query(UserFavorite)
        .filter(UserFavorite.user_id == current_user.id, UserFavorite.recipe_id == recipe_id)
        .first()
    )
    if not fav:
        raise HTTPException(status_code=404, detail="Favorite not found")
    db.delete(fav)
    db.commit()
    return {"message": "Favorite removed"}


@router.post("/search/natural")
def natural_search(
    req: dict,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    query_text = req.get("query", "")
    if not query_text:
        return {"recipes": []}

    parsed = parse_inventory_text(query_text, "hi")

    db_query = db.query(Recipe).filter(Recipe.is_active == True)

    if parsed.get("add"):
        ing_names = parsed["add"]
        ingredient_ids = [
            ing.id
            for ing in db.query(Ingredient).filter(Ingredient.name.in_(ing_names)).all()
        ]
        if ingredient_ids:
            matches = (
                db.query(RecipeIngredient.recipe_id, func.count(RecipeIngredient.ingredient_id).label("cnt"))
                .filter(RecipeIngredient.ingredient_id.in_(ingredient_ids))
                .group_by(RecipeIngredient.recipe_id)
                .subquery()
            )
            db_query = db_query.join(matches, Recipe.id == matches.c.recipe_id)
            db_query = db_query.order_by(matches.c.cnt.desc(), Recipe.name)

    recipes = db_query.limit(20).all()

    return {
        "recipes": [
            {
                "id": str(r.id),
                "name": r.name,
                "description": r.description,
                "total_time_minutes": r.total_time_minutes,
            }
            for r in recipes
        ]
    }


@router.post("/enrich-dish")
def enrich_dish(
    req: dict,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Uses the AI to fill in recipe details (description, time, ingredients,
    difficulty, etc.) for a dish the user added to a category but gave only a
    name for. Mirrors the shape of our database recipes."""
    dish_name = (req.get("name") or "").strip()
    if not dish_name:
        return {"error": "dish name is required"}

    cuisine = (req.get("cuisine") or "").strip()
    meal_type = (req.get("meal_type") or "").strip()

    result = generate_recipe_json(dish_name, cuisine, meal_type)

    return {
        "name": result.get("name") or dish_name,
        "description": result.get("description"),
        "cuisine": result.get("cuisine"),
        "meal_types": result.get("meal_types") or [],
        "diet_type": result.get("diet_type"),
        "prep_time_minutes": result.get("prep_time_minutes"),
        "cook_time_minutes": result.get("cook_time_minutes"),
        "total_time_minutes": result.get("total_time_minutes"),
        "difficulty": result.get("difficulty"),
        "servings": result.get("servings"),
        "health_score": result.get("health_score"),
        "health_category": result.get("health_category"),
        "instructions": result.get("instructions"),
        "tags": result.get("tags") or [],
        "ingredients": [
            {
                "name": i.get("name"),
                "quantity": i.get("quantity"),
                "unit": i.get("unit"),
            }
            for i in result.get("ingredients", [])
        ],
    }


@router.get("/{recipe_id}")
def get_recipe(
    recipe_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    recipe = db.query(Recipe).filter(Recipe.id == recipe_id, Recipe.is_active == True).first()
    if not recipe:
        return {"error": "Recipe not found"}, 404

    ingredients = (
        db.query(RecipeIngredient, Ingredient)
        .join(Ingredient, RecipeIngredient.ingredient_id == Ingredient.id)
        .filter(RecipeIngredient.recipe_id == recipe.id)
        .order_by(RecipeIngredient.sort_order)
        .all()
    )

    return {
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
        "instructions": recipe.instructions,
        "health_score": recipe.health_score,
        "health_category": recipe.health_category.value if recipe.health_category else None,
        "image_url": recipe.image_url,
        "tags": recipe.tags,
        "ingredients": [
            {
                "ingredient_id": str(ri.ingredient_id),
                "name": ing.display_name_en,
                "quantity": ri.quantity,
                "unit": ri.unit,
                "is_required": ri.is_required,
                "notes": ri.notes,
            }
            for ri, ing in ingredients
        ],
    }


@router.post("/admin/seed")
def seed_database(db: Session = Depends(get_db)):
    """Seed the database with ingredients and recipes. Call once after deployment."""
    import seed_discover
    result = seed_discover.seed_all(db)
    return {"message": "Seeding completed", "status": result}
