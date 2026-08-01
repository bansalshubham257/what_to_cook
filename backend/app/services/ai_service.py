import json
import logging
from typing import Optional
from app.core.config import settings

logger = logging.getLogger(__name__)

AI_PROVIDER = None
AI_CLIENT = None


def _init_openai():
    global AI_PROVIDER, AI_CLIENT
    try:
        import openai
        kwargs = {"api_key": settings.AI_API_KEY, "timeout": 30.0}
        if settings.AI_API_BASE:
            kwargs["base_url"] = settings.AI_API_BASE
        AI_CLIENT = openai.OpenAI(**kwargs)
        AI_PROVIDER = "openai"
        logger.info("OpenAI client initialized with base_url=%s", kwargs.get("base_url", "default"))
    except Exception as e:
        logger.warning(f"Failed to initialize OpenAI: {e}")
        AI_PROVIDER = "mock"


def get_ai_client():
    global AI_PROVIDER, AI_CLIENT
    if AI_PROVIDER is None:
        if settings.AI_API_KEY and settings.AI_PROVIDER == "openai":
            _init_openai()
        else:
            AI_PROVIDER = "mock"
    return AI_CLIENT


INVENTORY_PARSING_SYSTEM_PROMPT = """You are a kitchen inventory parser. Parse the user's natural language statement about their kitchen inventory.

The user may speak Hindi, English, or Hinglish.

Return a JSON object with the following structure:
{
    "intent": "add" | "remove" | "set_low" | "replace_category" | "replace_all" | "general_group",
    "category": "vegetables" | "dairy" | "grains" | "pulses" | "spices" | "fruits" | "meat" | "occasional" | null,
    "add": ["list of ingredient canonical names to add"],
    "remove": ["list of ingredient canonical names to remove"],
    "set_low": ["list of ingredient canonical names to set as low"],
    "set_use_soon": [],
    "confidence": 0.0 to 1.0,
    "requires_confirmation": true/false,
    "message": "User-friendly summary of what was understood"
}

IMPORTANT RULES:
- "replace_category" means the user specified ONLY certain items in a category - others should be removed
- "replace_all" means the entire kitchen inventory should be replaced
- "general_group" like "all dals" or "normal dals" - set category to "pulses" (only if user ONLY says "dal"/"daal" with no other specifics)
- "general_group" like "sabzi" or "vegetables" - set category to "vegetables" (only if user says ONLY sabzi)
- If user mentions generic "dal" alongside specific items like "aloo", parse each item individually. "dal" should be treated as general_group AND the specific items should be in the "add" list.
- For "replace_category" and "replace_all", set requires_confirmation to true
- Use canonical English ingredient names (e.g., "potato" not "aloo", "okra" not "bhindi")
- If confidence < 0.7, set requires_confirmation to true
- Negations like "nahi hai", "khatam" should map to remove
- "thoda bacha hai", "low" should map to set_low
- "bhi hai", "bhi" after ingredient means add

Known ingredient canonical names: potato, onion, tomato, ginger, garlic, green_chilli, okra, eggplant, cauliflower, cabbage, capsicum, peas, spinach, lauki, tori, mushroom, paneer, milk, curd, butter, cream, bread, eggs, noodles, pasta, cheese, atta, rice, besan, suji, poha, toor_dal, moong_dal, masoor_dal, chana_dal, urad_dal, rajma, chickpeas, salt, sugar, cooking_oil, ghee, jeera, haldi, red_chilli_powder, coriander_powder, garam_masala, hing, mustard_seeds, dhaniya, pudina, lemon, coconut, peanuts, cashews, almonds, raisins, dates, honey, jaggery, tea, coffee, fruits."""
MIXED = "mixed"


def parse_inventory_text(text: str, language: str = "hi") -> dict:
    client = get_ai_client()

    if AI_PROVIDER == "mock":
        return _mock_parse_inventory(text, language)

    try:
        response = client.chat.completions.create(
            model=settings.AI_MODEL,
            messages=[
                {"role": "system", "content": INVENTORY_PARSING_SYSTEM_PROMPT},
                {"role": "user", "content": f"Parse this kitchen inventory statement: {text}"},
            ],
            response_format={"type": "json_object"},
            temperature=0.1,
            max_tokens=500,
        )
        result = json.loads(response.choices[0].message.content)
        result = _validate_parsed_result(result)

        mock_result = _mock_parse_inventory(text, language)
        ai_has_items = bool(result.get("add") or result.get("remove") or result.get("set_low"))
        mock_has_items = bool(mock_result.get("add") or mock_result.get("remove") or mock_result.get("set_low"))
        if not ai_has_items and mock_has_items:
            return mock_result
        if ai_has_items and mock_has_items:
            for key in ("add", "remove", "set_low"):
                merged = list(set(result.get(key, []) + mock_result.get(key, [])))
                result[key] = merged
        return result
    except Exception as e:
        logger.error(f"AI parsing error: {e}")
        return _mock_parse_inventory(text, language)


def _validate_parsed_result(result: dict) -> dict:
    required_keys = ["intent", "add", "remove", "set_low", "confidence"]
    for key in required_keys:
        if key not in result:
            result[key] = [] if key in ["add", "remove", "set_low"] else ("add" if key == "intent" else 0.5)
    if "requires_confirmation" not in result:
        result["requires_confirmation"] = result.get("confidence", 0.5) < 0.7
    if "message" not in result:
        result["message"] = "Parsed inventory update"
    return result


def _mock_parse_inventory(text: str, language: str = "hi") -> dict:
    text_lower = text.lower()

    result = {
        "intent": "add",
        "category": None,
        "add": [],
        "remove": [],
        "set_low": [],
        "set_use_soon": [],
        "confidence": 0.8,
        "requires_confirmation": False,
        "message": "Kitchen inventory updated",
    }

    known_items = {
        "aloo": "potato", "potato": "potato", "potatoes": "potato", "आलू": "potato",
        "pyaaz": "onion", "onion": "onion", "प्याज": "onion", "pyaz": "onion", "onions": "onion",
        "tamatar": "tomato", "tomato": "tomato", "टमाटर": "tomato", "tomatoes": "tomato",
        "adrak": "ginger", "ginger": "ginger", "अदरक": "ginger",
        "lasan": "garlic", "garlic": "garlic", "लहसुन": "garlic", "lahsun": "garlic",
        "mirchi": "green_chilli", "hari_mirch": "green_chilli", "हरी_मिर्च": "green_chilli",
        "bhindi": "okra", "okra": "okra", "lady_finger": "okra", "भिंडी": "okra",
        "baingan": "eggplant", "eggplant": "eggplant", "बैंगन": "eggplant",
        "gobi": "cauliflower", "cauliflower": "cauliflower", "फूलगोभी": "cauliflower",
        "patta_gobi": "cabbage", "cabbage": "cabbage", "पत्ता_गोभी": "cabbage",
        "shimla_mirch": "capsicum", "capsicum": "capsicum", "शिमला_मिर्च": "capsicum",
        "matar": "peas", "peas": "peas", "मटर": "peas",
        "palak": "spinach", "spinach": "spinach", "पालक": "spinach",
        "lauki": "lauki", "tori": "tori", "mushroom": "mushroom", "paneer": "paneer",
        "doodh": "milk", "milk": "milk", "दूध": "milk",
        "dahi": "curd", "curd": "curd", "दही": "curd",
        "bread": "bread", "eggs": "eggs", "anda": "eggs", "अंडा": "eggs", "ande": "eggs",
        "noodles": "noodles", "pasta": "pasta", "cheese": "cheese",
        "atta": "atta", "aata": "atta", "आटा": "atta",
        "chawal": "rice", "rice": "rice", "चावल": "rice",
        "besan": "besan", "suji": "suji", "suji": "suji", "poha": "poha",
        "nimbu": "lemon", "lemon": "lemon", "नींबू": "lemon",
        "namak": "salt", "salt": "salt", "नमक": "salt",
        "chini": "sugar", "sugar": "sugar", "cheeni": "sugar", "चीनी": "sugar",
        "tel": "cooking_oil", "oil": "cooking_oil", "cooking_oil": "cooking_oil", "तेल": "cooking_oil",
        "ghee": "ghee", "घी": "ghee",
        "jeera": "cumin_seeds", "cumin": "cumin_seeds", "जीरा": "cumin_seeds",
        "haldi": "turmeric_powder", "turmeric": "turmeric_powder", "हल्दी": "turmeric_powder",
        "mirch_powder": "red_chili_powder", "lal_mirch": "red_chili_powder", "red_chilli": "red_chili_powder",
        "dhaniya": "coriander_powder", "coriander": "coriander_powder", "धनिया": "coriander_powder",
        "garam_masala": "garam_masala",
        "methi": "fenugreek_seeds", "fenugreek": "fenugreek_seeds",
        "rai": "mustard_seeds", "mustard": "mustard_seeds", "sarson": "mustard_seeds",
        "hing": "asafoetida", "asafoetida": "asafoetida", "हींग": "asafoetida",
        "pudina": "coriander_leaves", "coriander_leaves": "coriander_leaves",
        "hara_dhaniya": "coriander_leaves", "dhaniya_patta": "coriander_leaves",
        "kadi_patta": "curry_leaves", "curry_leaves": "curry_leaves",
        "nariyal": "coconut", "coconut": "coconut", "नारियल": "coconut",
        "moongphali": "peanuts", "peanuts": "peanuts", "mungfali": "peanuts",
        "kaju": "cashews", "cashews": "cashews",
        "badam": "almonds", "almonds": "almonds",
        "kishmish": "raisins", "raisins": "raisins",
        "khajoor": "dates", "dates": "dates",
        "shahad": "honey", "honey": "honey",
        "gud": "jaggery", "jaggery": "jaggery", "गुड़": "jaggery",
        "chai": "tea", "tea": "tea",
        "coffee": "coffee", "kafi": "coffee",
        "maida": "maida",
        "sooji": "sooji", "rawa": "sooji", "suji": "sooji",
        "poha": "poha",
        "besan": "besan",
    }

    category_expansions = {
        "dal": ["toor_dal", "moong_dal", "masoor_dal", "chana_dal"],
        "daal": ["toor_dal", "moong_dal", "masoor_dal", "chana_dal"],
        "sabzi": ["potato", "onion", "tomato", "cauliflower", "cabbage", "capsicum", "peas", "spinach", "okra", "eggplant", "lauki", "tori"],
        "sabji": ["potato", "onion", "tomato", "cauliflower", "cabbage", "capsicum", "peas", "spinach", "okra", "eggplant", "lauki", "tori"],
        "vegetable": ["potato", "onion", "tomato", "cauliflower", "cabbage", "capsicum", "peas", "spinach", "okra", "eggplant", "lauki", "tori"],
        "masala": ["cumin_seeds", "turmeric_powder", "red_chili_powder", "coriander_powder", "garam_masala", "salt"],
    }

    text_lower = text_lower.replace(",", " , ")
    separators = [" aur ", " lekin ", " but ", " and ", " magar ", ","]
    clauses = [text_lower]
    for sep in separators:
        new_clauses = []
        for c in clauses:
            new_clauses.extend(c.split(sep))
        clauses = new_clauses
    clauses = [c.strip() for c in clauses if c.strip()]

    for clause in clauses:
        clause = clause.strip()
        if not clause:
            continue

        clause_has_negation = any(w in clause for w in ["nahi", "khatam", "nhi", "नहीं", "खत्म", "no", "not", "finished", "gone"])

        clause_words = clause.split()
        clause_has_low = any(w in clause_words for w in ["thoda", "bacha", "low", "little", "few", "थोड़ा", "बचा"])

        expanded = False
        for word in clause_words:
            clean_word = word.strip(".,!?;:()")
            if clean_word in category_expansions and len(clause_words) <= 5:
                for item in category_expansions[clean_word]:
                    if clause_has_negation:
                        result["remove"].append(item)
                    elif clause_has_low:
                        result["set_low"].append(item)
                    else:
                        result["add"].append(item)
                expanded = True
                break

        if expanded:
            continue

        for word in clause_words:
            clean_word = word.strip(".,!?;:()")
            if clean_word in known_items:
                canonical = known_items[clean_word]
                if clause_has_negation:
                    result["remove"].append(canonical)
                elif clause_has_low:
                    result["set_low"].append(canonical)
                else:
                    result["add"].append(canonical)

    result["remove"] = list(set(result["remove"]))
    result["add"] = list(set(result["add"]))
    result["set_low"] = list(set(result["set_low"]))

    is_category_replace = any(f"sirf {w}" in text_lower or f"only {w}" in text_lower for w in ["sabzi", "sabji", "vegetable", "सब्जी"])
    if is_category_replace and result["add"]:
        result["intent"] = "replace_category"
        result["category"] = "vegetables"
        result["requires_confirmation"] = True

    if "sirf" in text_lower or "only" in text_lower:
        for cat_word in ["sabzi", "sabji", "vegetable", "सब्जी"]:
            if cat_word in text_lower:
                result["intent"] = "replace_category"
                result["category"] = "vegetables"
                result["requires_confirmation"] = True
                break
        for cat_word in ["dal", "daal", "pulse", "दाल"]:
            if cat_word in text_lower:
                result["intent"] = "replace_category"
                result["category"] = "pulses"
                result["requires_confirmation"] = True
                break

    if not result["add"] and not result["remove"] and not result["set_low"]:
        result["confidence"] = 0.3
        result["requires_confirmation"] = True
        result["message"] = "Could not understand the inventory update"

    return result


def generate_recommendation_explanation(
    recipe_name: str,
    score: float,
    available_count: int,
    missing_count: int,
    use_soon_items: list[str],
    recent_meal: bool,
) -> list[str]:
    reasons = []

    if missing_count == 0:
        reasons.append(f"All ingredients available")
    elif missing_count == 1:
        reasons.append(f"Only 1 ingredient missing")
    else:
        reasons.append(f"{missing_count} ingredients needed")

    if use_soon_items:
        items_str = ", ".join(use_soon_items)
        reasons.append(f"{items_str} should be used soon")

    if not recent_meal:
        reasons.append("Not cooked recently")

    if score >= 80:
        reasons.append("Great match for your kitchen")

    return reasons


def generate_surprise_me_reason(
    recipe_name: str,
    total_time: int,
    available: bool,
    not_recent: bool,
) -> str:
    parts = []
    if available:
        parts.append("Everything is available")
    if total_time <= 30:
        parts.append(f"takes about {total_time} minutes")
    if not_recent:
        parts.append("you haven't cooked it recently")
    return f"**Why this?** {' • '.join(parts)}."


RECIPE_GENERATION_SYSTEM_PROMPT = """You are an expert Indian chef. Generate a complete recipe for the dish the user requests.

Return ONLY a valid JSON object with exactly this structure:
{
    "name": "clean dish name",
    "description": "2 line appetizing description",
    "cuisine": "one of: north_indian, south_indian, punjabi, bengali, odia, gujarati, rajasthani, maharashtrian, kashmiri, awadhi, bihari, himachali, haryanvi, goan, kerala, tamil, telugu, karnataka, assamese, nepali, sindhi, parsi, hyderabadi, muglai, indo_chinese, continental, italian, french, thai, chinese, mexican, japanese, mediterranean, korean, vietnamese (choose the closest; if the user names an international dish pick its real cuisine)",
    "meal_types": ["breakfast", "lunch", "snacks", "dinner", "dessert"],
    "diet_type": "vegetarian" | "non_vegetarian" | "vegan",
    "prep_time_minutes": 5-40,
    "cook_time_minutes": 5-60,
    "total_time_minutes": prep + cook,
    "difficulty": "easy" | "medium" | "hard",
    "servings": 2-6,
    "health_score": 40-90,
    "health_category": "balanced" | "moderate" | "indulgent",
    "tags": ["3-5 short tags describing the dish"],
    "ingredients": [{"name": "canonical english ingredient name", "quantity": "number or measurement", "unit": "g | ml | cup | tsp | tbsp | pieces | to taste"}],
    "instructions": "number each step with a new line like: 1. First step.\n2. Second step."
}

Rules:
- ingredient names must be simple lowercase canonical names (potato, onion, tomato, paneer, chicken, rice, dal, etc.)
- include 6-12 ingredients
- if the user's dish is not a real recipe, invent a reasonable homemade version of it
- if the user gives a language mix (Hindi/Hinglish), still return the recipe in English
"""


def generate_recipe_json(dish_name: str, cuisine: str = "", meal_type: str = "") -> dict:
    client = get_ai_client()

    if AI_PROVIDER == "mock":
        return _mock_generate_recipe(dish_name, cuisine, meal_type)

    hint = ""
    if cuisine:
        hint += f" The cuisine should be: {cuisine}."
    if meal_type:
        hint += f" The meal type should be: {meal_type}."

    try:
        response = client.chat.completions.create(
            model=settings.AI_MODEL,
            messages=[
                {"role": "system", "content": RECIPE_GENERATION_SYSTEM_PROMPT},
                {"role": "user", "content": f"Create a recipe for: {dish_name}.{hint}"},
            ],
            response_format={"type": "json_object"},
            temperature=0.7,
            max_tokens=900,
        )
        result = json.loads(response.choices[0].message.content)
        result = _validate_generated_recipe(result, dish_name, meal_type)
        return result
    except Exception as e:
        logger.error(f"AI recipe generation error: {e}")
        return _mock_generate_recipe(dish_name, cuisine, meal_type)


def _validate_generated_recipe(result: dict, dish_name: str, meal_type: str) -> dict:
    if not result.get("name") or not result.get("instructions"):
        return _mock_generate_recipe(dish_name, "", meal_type)
    result["name"] = result.get("name") or dish_name
    result.setdefault("description", f"A homemade {dish_name} recipe.")
    result.setdefault("meal_types", [meal_type or "dinner"])
    result.setdefault("diet_type", "vegetarian")
    result.setdefault("cuisine", "north_indian")
    result.setdefault("prep_time_minutes", 15)
    result.setdefault("cook_time_minutes", 25)
    result.setdefault("total_time_minutes", 40)
    result.setdefault("difficulty", "medium")
    result.setdefault("servings", 4)
    result.setdefault("health_score", 60)
    result.setdefault("health_category", "balanced")
    result.setdefault("tags", [])
    result.setdefault("ingredients", [])
    return result


def _mock_generate_recipe(dish_name: str, cuisine: str = "", meal_type: str = "") -> dict:
    return {
        "name": dish_name.strip().title(),
        "description": f"A simple homemade {dish_name} made with everyday kitchen ingredients.",
        "cuisine": cuisine.lower().strip().replace(" ", "_") or "north_indian",
        "meal_types": [meal_type or "dinner"],
        "diet_type": "vegetarian",
        "prep_time_minutes": 15,
        "cook_time_minutes": 25,
        "total_time_minutes": 40,
        "difficulty": "medium",
        "servings": 4,
        "health_score": 60,
        "health_category": "balanced",
        "tags": ["user_created", "homemade"],
        "ingredients": [
            {"name": "onion", "quantity": "2", "unit": "pieces"},
            {"name": "tomato", "quantity": "2", "unit": "pieces"},
            {"name": "ginger", "quantity": "1", "unit": "inch"},
            {"name": "garlic", "quantity": "4", "unit": "cloves"},
            {"name": "cooking_oil", "quantity": "2", "unit": "tbsp"},
            {"name": "salt", "quantity": "", "unit": "to taste"},
        ],
        "instructions": (
            "1. Wash and chop all vegetables.\n"
            "2. Heat oil in a pan and add ginger-garlic, saute until fragrant.\n"
            "3. Add onions and cook until soft.\n"
            "4. Add tomatoes and spices, cook until oil separates.\n"
            "5. Add the main ingredient and simmer until cooked.\n"
            "6. Season with salt and serve hot."
        ),
    }
