"""Seed 5 AI-generated viral/trending (reels-style) recipes per cuisine."""
import re
import time
from app.core.database import SessionLocal
from app.models.recipe import Cuisine, Recipe, RecipeIngredient
from app.models.ingredient import Ingredient, IngredientCategoryType, IngredientStorageType
from app.services.ai_service import generate_recipe_json

PER_CUISINE = 5
MAX_ATTEMPTS = 4

BANNED_NAME_WORDS = ["viral", "trending", "reels", "shorts", "instagram", "youtube", "recipe from"]

FALLBACK_NAMES = [
    "Cheese Pull Roll", "Crunchy Tikka Crunchwrap", "Lava Cheese Kulcha",
    "Fusion Stuffed Toast", "Crispy Chaat Bomb", "Molten Paneer Pocket",
    "Loaded Cheese Fries", "Butter Garlic Cheese Bomb", "Saffron Croissant Crunch",
    "Double Cheese Tikka Stack",
]

CAT_GUESS = {
    "vegetable": IngredientCategoryType.VEGETABLE,
    "fruit": IngredientCategoryType.FRUIT,
    "dairy": IngredientCategoryType.DAIRY,
    "meat": IngredientCategoryType.MEAT,
    "grain": IngredientCategoryType.GRAIN,
    "pulse": IngredientCategoryType.PULSE,
    "spice": IngredientCategoryType.SPICE,
    "oil": IngredientCategoryType.OIL,
}
DEFAULT_CAT = IngredientCategoryType.OTHER

PROMPT_TEMPLATE = (
    "a VIRAL trending recipe from {cuisine} cuisine that is blowing up on Instagram Reels "
    "and YouTube Shorts in 2026. It must be a UNIQUE, catchy, visually-stunning modern dish "
    "(cheese pull, crispy crunch, layered or fusion twist) that is NOT a classic dish. "
    "Give it a short catchy viral name."
)


def sanitize_name(name: str) -> str:
    if not name:
        return ""
    name = name.strip().strip('"\'“”‘’').strip()
    lowered = name.lower()
    if any(w in lowered for w in BANNED_NAME_WORDS):
        return ""
    if len(name) > 60:
        name = name[:60].rsplit(" ", 1)[0]
    return name


def to_int(value, default):
    if isinstance(value, bool):
        return default
    if isinstance(value, int):
        return value
    if isinstance(value, float):
        return int(value)
    if isinstance(value, str):
        match = re.search(r"\d+", value)
        if match:
            return int(match.group(0))
    return default


def main():
    db = SessionLocal()
    try:
        imap = {i.name: i for i in db.query(Ingredient).all()}
        existing_names = {r.name.lower() for r in db.query(Recipe.name).all()}
        stale = db.query(Recipe).filter(
            Recipe.source == "ai",
            Recipe.tags.contains(["trending"]),
        ).all()
        if stale:
            for r in stale:
                db.query(RecipeIngredient).filter(RecipeIngredient.recipe_id == r.id).delete(
                    synchronize_session=False)
            for r in stale:
                db.delete(r)
            db.commit()
            print(f"cleaned {len(stale)} stale trending rows\n")
        existing_names = {r.name.lower() for r in db.query(Recipe.name).all()}
        cuisines = db.query(Cuisine).order_by(Cuisine.name).all()
        total_added = 0
        total_failed = 0

        for c in cuisines:
            display = c.display_name_en or c.name.replace("_", " ").title()
            c_added = 0
            c_failed = 0
            for i in range(PER_CUISINE):
                result = None
                name = ""
                for attempt in range(MAX_ATTEMPTS):
                    try:
                        result = generate_recipe_json(
                            PROMPT_TEMPLATE.format(cuisine=display),
                            cuisine=display,
                            meal_type="",
                        )
                    except Exception as e:
                        print(f"  attempt {attempt+1} error: {e}")
                        time.sleep(1)
                        continue
                    name = sanitize_name(result.get("name", ""))
                    if name and name.lower() not in existing_names:
                        result["name"] = name
                        break
                    result = None
                    time.sleep(0.5)
                if not result:
                    fallback = f"{display} {FALLBACK_NAMES[i % len(FALLBACK_NAMES)]}"
                    if fallback.lower() in existing_names:
                        fallback = f"{fallback} {i+1}"
                    result = generate_recipe_json(
                        fallback,
                        cuisine=display,
                        meal_type="",
                    )
                    name = sanitize_name(result.get("name", "")) or fallback
                    if name.lower() in existing_names:
                        name = fallback
                    result["name"] = name
                if not name:
                    c_failed += 1
                    total_failed += 1
                    print(f"{display}: FAILED recipe {i+1}")
                    continue

                existing_names.add(name.lower())
                meal_types = result.get("meal_types") or ["dinner"]
                diet = result.get("diet_type") or "vegetarian"
                if diet not in ("vegetarian", "non_vegetarian", "vegan", "vegetarian_egg"):
                    diet = "vegetarian"
                difficulty = result.get("difficulty") or "medium"
                if difficulty not in ("easy", "medium", "hard"):
                    difficulty = "medium"
                health_cat = result.get("health_category") or "balanced"
                if health_cat not in ("balanced", "moderate", "indulgent"):
                    health_cat = "balanced"
                tags = list(result.get("tags") or [])
                tags = [t for t in tags if isinstance(t, str)][:4]
                tags = ["trending", "ai", c.name] + tags

                recipe = Recipe(
                    name=name,
                    description=result.get("description") or f"A viral trending {display} recipe.",
                    cuisine_id=c.id,
                    meal_types=meal_types,
                    diet_type=diet,
                    prep_time_minutes=to_int(result.get("prep_time_minutes"), 15),
                    cook_time_minutes=to_int(result.get("cook_time_minutes"), 25),
                    total_time_minutes=to_int(result.get("total_time_minutes"), 40),
                    difficulty=difficulty,
                    servings=to_int(result.get("servings"), 4),
                    instructions=result.get("instructions") or "1. Prepare all ingredients.\n2. Cook as per taste.",
                    health_score=to_int(result.get("health_score"), 60),
                    health_category=health_cat,
                    tags=tags,
                    source="ai",
                )
                db.add(recipe)
                db.flush()

                order = 0
                for ing in result.get("ingredients") or []:
                    ing_name = (ing.get("name") or "").strip().lower()
                    if not ing_name:
                        continue
                    if ing_name not in imap:
                        new_ing = Ingredient(
                            name=ing_name,
                            display_name_en=ing_name.replace("_", " ").title(),
                            display_name_hi=None,
                            category=CAT_GUESS.get(
                                ing.get("category", ""), DEFAULT_CAT),
                            storage_type=IngredientStorageType.PANTRY,
                            is_common=True,
                            is_active=True,
                        )
                        db.add(new_ing)
                        db.flush()
                        imap[ing_name] = new_ing
                    db.add(RecipeIngredient(
                        recipe_id=recipe.id,
                        ingredient_id=imap[ing_name].id,
                        quantity=str(ing.get("quantity", "")),
                        unit=ing.get("unit"),
                        is_required=True,
                        sort_order=order,
                    ))
                    order += 1

                c_added += 1
                total_added += 1
                print(f"{display}: + {name}")

            db.commit()
            print(f"--- {display}: +{c_added} (failed {c_failed}) ---\n")

        print(f"\nDone. {total_added} trending recipes added, {total_failed} failed.")
    finally:
        db.close()


if __name__ == "__main__":
    main()
