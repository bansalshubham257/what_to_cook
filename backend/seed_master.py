"""Master seed: every cuisine gets 10 dishes per category (5 classic + 5 trending)
for each meal type (breakfast/lunch/snacks/dinner/dessert) and healthy (balanced).

Resumable: commits per cuisine, skips already-satisfied slots.
Use --max to cap generations per run for chunked execution.
"""
import argparse
import re
import sys
import time
from app.core.database import SessionLocal
from app.models.recipe import Cuisine, Recipe, RecipeIngredient
from app.models.ingredient import Ingredient, IngredientCategoryType, IngredientStorageType
from app.services.ai_service import generate_recipe_json

MEALS = ["breakfast", "lunch", "snacks", "dinner", "dessert"]
TARGET = 5
MAX_ATTEMPTS = 3

BANNED = ["viral", "trending", "reels", "shorts", "instagram", "youtube",
          "recipe for", "recipe from", "the following", "dish for"]

CLASSIC_FALLBACKS = [
    "Stuffed Paratha", "Dal Rice Bowl", "Vegetable Khichdi", "Masala Omelette",
    "Curd Rice", "Mixed Veg Sabzi", "Tadka Dal", "Sweet Kheer", "Crispy Pakoras",
    "Fluffy Poori", "Chana Masala", "Vegetable Pulao", "Spiced Tea", "Banana Sheera",
]

TRENDING_FALLBACKS = [
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


def sanitize_name(name):
    if not name:
        return ""
    name = name.strip().strip('"\'“”‘’').strip()
    low = name.lower()
    if any(b in low for b in BANNED):
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
        m = re.search(r"\d+", value)
        if m:
            return int(m.group(0))
    return default


def build_prompt(cuisine, meal, kind, healthy, existing_names):
    if kind == "classic":
        prompt = f"an AUTHENTIC classic {meal} dish from {cuisine} cuisine, a well-known traditional recipe"
    else:
        prompt = (
            f"a VIRAL trending {meal} dish from {cuisine} cuisine blowing up on Instagram Reels "
            f"and YouTube Shorts in 2026, a unique visually-stunning modern dish (cheese pull, "
            f"crispy crunch, layered or fusion twist) that is NOT a classic dish, with a short catchy viral name"
        )
    if healthy:
        prompt += (", healthy and balanced (health_category must be 'balanced', health_score 70-85)")
    if existing_names:
        prompt += ". It MUST NOT be any of these already-existing dishes: " + ", ".join(existing_names[:25])
    return prompt


def add_recipe(db, result, name, cuisine_id, meal, kind, healthy, imap, existing_names):
    meal_types = result.get("meal_types") or [meal]
    if meal and meal not in meal_types:
        meal_types = [meal] + meal_types
    diet = result.get("diet_type") or "vegetarian"
    if diet not in ("vegetarian", "non_vegetarian", "vegan", "vegetarian_egg"):
        diet = "vegetarian"
    difficulty = result.get("difficulty") or "medium"
    if difficulty not in ("easy", "medium", "hard"):
        difficulty = "medium"
    hcat = "balanced" if healthy else (result.get("health_category") or "moderate")
    if hcat not in ("balanced", "moderate", "indulgent"):
        hcat = "balanced"
    hscore = to_int(result.get("health_score"), 60)
    if healthy and hscore < 65:
        hscore = 70
    tags = list(result.get("tags") or [])
    tags = [t for t in tags if isinstance(t, str)][:3]
    tags = [kind, "ai_fill" if kind == "classic" else "ai", meal] + tags

    recipe = Recipe(
        name=name,
        description=result.get("description") or f"A {kind} {meal} from {cuisine}.",
        cuisine_id=cuisine_id,
        meal_types=meal_types,
        diet_type=diet,
        prep_time_minutes=to_int(result.get("prep_time_minutes"), 15),
        cook_time_minutes=to_int(result.get("cook_time_minutes"), 25),
        total_time_minutes=to_int(result.get("total_time_minutes"), 40),
        difficulty=difficulty,
        servings=to_int(result.get("servings"), 4),
        instructions=result.get("instructions") or "1. Prepare all ingredients.\n2. Cook as per taste.\n3. Serve hot.",
        health_score=hscore,
        health_category=hcat,
        tags=tags,
        source="ai_fill" if kind == "classic" else "ai",
    )
    db.add(recipe)
    db.flush()
    order = 0
    for ing in result.get("ingredients") or []:
        ing_name = (ing.get("name") or "").strip().lower()
        if not ing_name:
            continue
        if ing_name not in imap:
            db.add(Ingredient(
                name=ing_name,
                display_name_en=ing_name.replace("_", " ").title(),
                display_name_hi=None,
                category=CAT_GUESS.get(ing.get("category", ""), DEFAULT_CAT),
                storage_type=IngredientStorageType.PANTRY,
                is_common=True,
                is_active=True,
            ))
            db.flush()
            imap[ing_name] = db.query(Ingredient).filter(Ingredient.name == ing_name).first()
        db.add(RecipeIngredient(
            recipe_id=recipe.id,
            ingredient_id=imap[ing_name].id,
            quantity=str(ing.get("quantity", "")),
            unit=ing.get("unit"),
            is_required=True,
            sort_order=order,
        ))
        order += 1
    existing_names.add(name.lower())
    return recipe


def generate_one(db, cuisine_obj, meal, kind, healthy, imap, existing_names):
    display = cuisine_obj.display_name_en or cuisine_obj.name.replace("_", " ").title()
    cuisine_names = [r.name for r in db.query(Recipe).filter(Recipe.cuisine_id == cuisine_obj.id).all()]
    prompt = build_prompt(display, meal, kind, healthy, cuisine_names)
    result = None
    name = ""
    for attempt in range(MAX_ATTEMPTS):
        try:
            result = generate_recipe_json(prompt, cuisine=display, meal_type=meal or "")
        except Exception:
            time.sleep(1)
            continue
        name = sanitize_name(result.get("name", ""))
        if name and name.lower() not in existing_names:
            break
        result = None
        time.sleep(0.5)
    if not result:
        pool = TRENDING_FALLBACKS if kind == "trending" else CLASSIC_FALLBACKS
        fallback = None
        for f in pool:
            cand = f"{display} {f}".strip()
            if cand.lower() not in existing_names:
                fallback = cand
                break
        if not fallback:
            return None
        result = generate_recipe_json(fallback, cuisine=display, meal_type=meal or "")
        name = sanitize_name(result.get("name", "")) or fallback
        if name.lower() in existing_names:
            name = fallback
    if not result or not name:
        return None
    return add_recipe(db, result, name, cuisine_obj.id, meal, kind, healthy, imap, existing_names)


def counts_for(cuisine_id, recipes):
    classic_meal = {m: 0 for m in MEALS}
    trending_meal = {m: 0 for m in MEALS}
    classic_healthy = 0
    trending_healthy = 0
    for r in recipes:
        is_trending = r.tags and "trending" in r.tags
        is_balanced = r.health_category is not None and r.health_category.value == "balanced"
        if is_trending:
            for m in (r.meal_types or []):
                if m in trending_meal:
                    trending_meal[m] += 1
            if is_balanced:
                trending_healthy += 1
        else:
            for m in (r.meal_types or []):
                if m in classic_meal:
                    classic_meal[m] += 1
            if is_balanced:
                classic_healthy += 1
    return classic_meal, trending_meal, classic_healthy, trending_healthy


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--max", type=int, default=10 ** 9, help="max generations per run")
    args = parser.parse_args()

    db = SessionLocal()
    budget = args.max
    try:
        imap = {i.name: i for i in db.query(Ingredient).all()}
        existing_names = {r.name.lower() for r in db.query(Recipe.name).all()}
        cuisines = db.query(Cuisine).order_by(Cuisine.name).all()
        total_added = 0

        for c in cuisines:
            if budget <= 0:
                print("budget exhausted", flush=True)
                break
            display = c.display_name_en or c.name.replace("_", " ").title()
            recipes = db.query(Recipe).filter(Recipe.cuisine_id == c.id).all()
            classic_meal, trending_meal, classic_healthy, trending_healthy = counts_for(c.id, recipes)

            slots = []
            for m in MEALS:
                slots.append(("classic", m, False, classic_meal[m]))
                slots.append(("trending", m, False, trending_meal[m]))
            slots.append(("classic", None, True, classic_healthy))
            slots.append(("trending", None, True, trending_healthy))

            added_here = 0
            for kind, meal, healthy, cur in slots:
                if budget <= 0:
                    break
                target = TARGET
                while cur < target and budget > 0:
                    result = generate_one(db, c, meal, kind, healthy, imap, existing_names)
                    if result is None:
                        print(f"  !! {display} [{kind}/{meal or 'healthy'}]: slot give-up", flush=True)
                        break
                    added_here += 1
                    cur += 1
                    budget -= 1
                    total_added += 1
                    print(f"  {display} [{kind}/{meal or 'healthy'}]: + {result.name}", flush=True)

            db.commit()
            meals = ", ".join(f"{m}={classic_meal[m]}" for m in MEALS)
            tmeals = ", ".join(f"{m}={trending_meal[m]}" for m in MEALS)
            print(f"--- {display}: +{added_here} | classic {meals} h={classic_healthy} | trending {tmeals} h={trending_healthy} ---", flush=True)

        print(f"\nDone this run: {total_added} added. Budget left: {budget}", flush=True)
    finally:
        db.close()


if __name__ == "__main__":
    main()
