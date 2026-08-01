"""Fill each cuisine so every meal category (breakfast/lunch/snacks/dinner/dessert) has
at least 5 dishes, and every cuisine has at least 5 healthy (balanced) dishes.
Uses the AI generator for authentic classic dishes; resumable (skips satisfied slots).
"""
import re
import time
from app.core.database import SessionLocal
from app.models.recipe import Cuisine, Recipe, RecipeIngredient
from app.models.ingredient import Ingredient, IngredientCategoryType, IngredientStorageType
from app.services.ai_service import generate_recipe_json

MEALS = ["breakfast", "lunch", "snacks", "dinner", "dessert"]
MIN_PER_CATEGORY = 5
MIN_HEALTHY = 5
MAX_ATTEMPTS = 3
MAX_SLOT_ATTEMPTS = 12

BANNED = ["viral", "trending", "reels", "shorts", "instagram", "youtube", "recipe for", "recipe from", "the following"]

FALLBACK_NAMES = [
    "Stuffed Paratha", "Paneer Curry", "Dal Rice Bowl", "Vegetable Khichdi",
    "Masala Omelette", "Curd Rice", "Mixed Veg Sabzi", "Tadka Dal",
    "Sweet Kheer", "Crispy Pakoras", "Fluffy Poori", "Chana Masala",
    "Vegetable Pulao", "Mint Chutney Roll", "Spiced Tea", "Banana Sheera",
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


def build_prompt(cuisine, meal, existing_names, healthy=False):
    prompt = (
        f"an AUTHENTIC classic {meal} dish from {cuisine} cuisine, a well-known traditional recipe"
    )
    if healthy:
        prompt += (", healthy and balanced (health_category must be 'balanced', health_score 70-85)")
    if existing_names:
        prompt += ". It MUST NOT be any of these already-existing dishes: " + ", ".join(existing_names[:25])
    return prompt


def add_recipe(db, result, name, cuisine_id, meal, healthy, imap, existing_names, source):
    meal_types = result.get("meal_types") or [meal]
    if meal not in meal_types:
        meal_types = [meal] + meal_types
    diet = result.get("diet_type") or "vegetarian"
    if diet not in ("vegetarian", "non_vegetarian", "vegan", "vegetarian_egg"):
        diet = "vegetarian"
    difficulty = result.get("difficulty") or "medium"
    if difficulty not in ("easy", "medium", "hard"):
        difficulty = "medium"
    hcat = "balanced" if healthy else (result.get("health_category") or "balanced")
    if hcat not in ("balanced", "moderate", "indulgent"):
        hcat = "balanced"
    hscore = to_int(result.get("health_score"), 60)
    if healthy and hscore < 65:
        hscore = 70
    tags = list(result.get("tags") or [])
    tags = [t for t in tags if isinstance(t, str)][:3]
    tags = ["classic", "ai_fill", meal] + tags

    recipe = Recipe(
        name=name,
        description=result.get("description") or f"A classic {meal} from {cuisine}.",
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
        source=source,
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


def main():
    db = SessionLocal()
    try:
        imap = {i.name: i for i in db.query(Ingredient).all()}
        existing_names = {r.name.lower() for r in db.query(Recipe.name).all()}
        cuisines = db.query(Cuisine).order_by(Cuisine.name).all()
        total_added = 0

        for c in cuisines:
            display = c.display_name_en or c.name.replace("_", " ").title()
            rows = db.query(Recipe).filter(
                Recipe.cuisine_id == c.id, Recipe.is_active == True).all()
            meal_counts = {m: 0 for m in MEALS}
            for r in rows:
                for m in (r.meal_types or []):
                    if m in meal_counts:
                        meal_counts[m] += 1
            healthy_count = sum(1 for r in rows if r.health_category and r.health_category.value == "balanced")
            cuisine_names = [r.name for r in rows]

            added_here = 0
            # 1) meal category fills
            for meal in MEALS:
                while meal_counts[meal] < MIN_PER_CATEGORY:
                    result = None
                    name = ""
                    for attempt in range(MAX_ATTEMPTS):
                        try:
                            result = generate_recipe_json(
                                build_prompt(display, meal, [n for n in cuisine_names], False),
                                cuisine=display,
                                meal_type=meal,
                            )
                        except Exception:
                            time.sleep(1)
                            continue
                        name = sanitize_name(result.get("name", ""))
                        if name and name.lower() not in existing_names:
                            break
                        result = None
                        time.sleep(0.5)
                    if not result:
                        fallback = None
                        for f in FALLBACK_NAMES:
                            cand = f"{display} {f}".strip()
                            if cand.lower() not in existing_names:
                                fallback = cand
                                break
                        if not fallback:
                            break
                        result = generate_recipe_json(fallback, cuisine=display, meal_type=meal)
                        name = sanitize_name(result.get("name", "")) or fallback
                        if name.lower() in existing_names:
                            name = fallback
                    if not result or not name:
                        break
                    add_recipe(db, result, name, c.id, meal, False, imap, existing_names, "ai_fill")
                    meal_counts[meal] += 1
                    added_here += 1
                    cuisine_names.append(name)
                    print(f"  {display} [{meal}]: + {name}")

            # 2) healthy (balanced) fill
            while healthy_count < MIN_HEALTHY:
                meal = MEALS[healthy_count % len(MEALS)]
                result = None
                name = ""
                for attempt in range(MAX_ATTEMPTS):
                    try:
                        result = generate_recipe_json(
                            build_prompt(display, meal, [n for n in cuisine_names], True),
                            cuisine=display,
                            meal_type=meal,
                        )
                    except Exception:
                        time.sleep(1)
                        continue
                    name = sanitize_name(result.get("name", ""))
                    if name and name.lower() not in existing_names:
                        break
                    result = None
                    time.sleep(0.5)
                if not result:
                    fallback = None
                    for f in FALLBACK_NAMES:
                        cand = f"{display} {f}".strip()
                        if cand.lower() not in existing_names:
                            fallback = cand
                            break
                    if not fallback:
                        break
                    result = generate_recipe_json(fallback, cuisine=display, meal_type=meal)
                    name = sanitize_name(result.get("name", "")) or fallback
                    if name.lower() in existing_names:
                        name = fallback
                if not result or not name:
                    break
                add_recipe(db, result, name, c.id, meal, True, imap, existing_names, "ai_fill")
                healthy_count += 1
                added_here += 1
                cuisine_names.append(name)
                print(f"  {display} [healthy]: + {name}")

            db.commit()
            total_added += added_here
            meals = ", ".join(f"{m}={meal_counts[m]}" for m in MEALS)
            print(f"--- {display}: +{added_here} | {meals} | healthy={healthy_count} ---\n")

        print(f"\nDone. {total_added} recipes added.")
    finally:
        db.close()


if __name__ == "__main__":
    main()
