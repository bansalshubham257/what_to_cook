from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.api.deps import get_current_user, get_current_household
from app.models.user import User
from app.models.household import Household
from app.models.inventory import InventoryItem, InventoryStatus
from app.models.ingredient import Ingredient
from app.schemas.ingredient import (
    InventoryItemCreate,
    InventoryItemUpdate,
    InventoryItemResponse,
    VoiceInventoryRequest,
    VoiceInventoryResponse,
    IngredientResponse,
)
from app.crud.inventory_crud import (
    get_inventory,
    get_inventory_with_ingredients,
    upsert_inventory_item,
    delete_inventory_item,
    bulk_update_inventory,
    set_category_inventory,
)
from app.services.ai_service import parse_inventory_text
from app.services.freshness_engine import get_use_soon_items, check_and_update_freshness
from app.models.ingredient import IngredientCategoryType, IngredientStorageType
from uuid import UUID

router = APIRouter(prefix="/kitchen", tags=["Kitchen"])

_PROFILE_INGREDIENTS = {
    "basic_north_indian_veg": [
        "onion", "tomato", "potato", "garlic", "ginger",
        "rice", "wheat_flour", "besan", "sooji", "maida",
        "salt", "turmeric_powder", "red_chili_powder", "cumin_seeds",
        "mustard_oil", "vegetable_oil", "green_chili",
        "coriander_powder", "garam_masala", "mustard_seeds",
        "fenugreek_seeds", "asafoetida", "coriander_leaves",
        "curd", "milk", "ghee", "lemon", "sugar", "jaggery",
        "moong_dal", "masoor_dal", "chana_dal", "toor_dal",
    ],
    "north_indian_non_veg": [
        "onion", "tomato", "potato", "garlic", "ginger",
        "rice", "wheat_flour", "besan", "sooji", "maida",
        "salt", "turmeric_powder", "red_chili_powder", "cumin_seeds",
        "mustard_oil", "vegetable_oil", "green_chili",
        "coriander_powder", "garam_masala", "mustard_seeds",
        "coriander_leaves", "curd", "milk", "ghee", "lemon", "sugar",
        "eggs", "chicken", "mutton", "fish",
        "onion", "garlic_paste", "ginger_garlic_paste",
        "moong_dal", "masoor_dal", "chana_dal", "toor_dal",
    ],
    "south_indian": [
        "onion", "tomato", "potato", "garlic", "ginger",
        "rice", "wheat_flour", "sooji", "idli_rice", "dosa_rice",
        "urad_dal", "chana_dal", "toor_dal", "moong_dal",
        "salt", "turmeric_powder", "red_chili_powder", "cumin_seeds",
        "coconut", "coconut_oil", "vegetable_oil",
        "curry_leaves", "mustard_seeds", "fenugreek_seeds",
        "tamarind", "coriander_leaves", "curd", "milk", "ghee",
        "green_chili", "black_pepper", "sugar", "jaggery",
        "sambar_powder", "rasam_powder",
    ],
    "mixed_indian": [
        "onion", "tomato", "potato", "garlic", "ginger",
        "rice", "wheat_flour", "besan", "sooji", "maida",
        "salt", "turmeric_powder", "red_chili_powder", "cumin_seeds",
        "mustard_oil", "vegetable_oil", "coconut_oil", "ghee",
        "green_chili", "coriander_powder", "garam_masala",
        "mustard_seeds", "curry_leaves", "coriander_leaves",
        "coconut", "tamarind", "curd", "milk",
        "lemon", "sugar", "jaggery",
        "moong_dal", "masoor_dal", "chana_dal", "toor_dal", "urad_dal",
        "black_pepper", "asafoetida",
    ],
}


def _seed_default_inventory(db: Session, household_id: UUID, profile: str = "basic_north_indian_veg"):
    ingredients = _PROFILE_INGREDIENTS.get(profile, _PROFILE_INGREDIENTS["basic_north_indian_veg"])
    for name in ingredients:
        ing = db.query(Ingredient).filter(Ingredient.name == name).first()
        if ing:
            existing = (
                db.query(InventoryItem)
                .filter(
                    InventoryItem.household_id == household_id,
                    InventoryItem.ingredient_id == ing.id,
                )
                .first()
            )
            if not existing:
                item = InventoryItem(
                    household_id=household_id,
                    ingredient_id=ing.id,
                    status=InventoryStatus.AVAILABLE,
                )
                db.add(item)
    db.commit()


@router.get("/inventory")
def get_kitchen_inventory(
    kitchen_profile: str = "basic_north_indian_veg",
    current_user: User = Depends(get_current_user),
    household: Household = Depends(get_current_household),
    db: Session = Depends(get_db),
):
    items = get_inventory_with_ingredients(db, household.id)
    if not items:
        _seed_default_inventory(db, household.id, kitchen_profile)
        items = get_inventory_with_ingredients(db, household.id)
    result = []
    for inv, ing in items:
        result.append({
            "id": str(inv.id),
            "ingredient_id": str(ing.id),
            "ingredient": {
                "id": str(ing.id),
                "name": ing.name,
                "display_name_en": ing.display_name_en,
                "display_name_hi": ing.display_name_hi,
                "category": ing.category.value,
                "storage_type": ing.storage_type.value,
            },
            "status": inv.status.value,
            "quantity": inv.quantity,
            "unit": inv.unit,
            "date_added": inv.date_added.isoformat() if inv.date_added else None,
            "last_confirmed_date": inv.last_confirmed_date.isoformat() if inv.last_confirmed_date else None,
            "freshness_window_days": inv.freshness_window_days,
        })
    return {"items": result}


@router.post("/inventory/update")
def update_inventory_item(
    item_data: InventoryItemCreate,
    current_user: User = Depends(get_current_user),
    household: Household = Depends(get_current_household),
    db: Session = Depends(get_db),
):
    item = upsert_inventory_item(
        db,
        household.id,
        item_data.ingredient_id,
        item_data.status,
        item_data.quantity,
        item_data.unit,
        item_data.freshness_window_days,
    )
    return {"message": "Inventory updated", "item_id": str(item.id)}


@router.delete("/inventory/{item_id}")
def delete_inventory(
    item_id: UUID,
    current_user: User = Depends(get_current_user),
    household: Household = Depends(get_current_household),
    db: Session = Depends(get_db),
):
    item = db.query(InventoryItem).filter(
        InventoryItem.id == item_id,
        InventoryItem.household_id == household.id,
    ).first()
    if not item:
        raise HTTPException(status_code=404, detail="Item not found")
    db.delete(item)
    db.commit()
    return {"message": "Item removed"}


@router.post("/inventory/bulk")
def bulk_update(
    available_ids: list[str] = None,
    low_ids: list[str] = None,
    not_available_ids: list[str] = None,
    current_user: User = Depends(get_current_user),
    household: Household = Depends(get_current_household),
    db: Session = Depends(get_db),
):
    count = bulk_update_inventory(
        db,
        household.id,
        [UUID(x) for x in (available_ids or [])],
        [UUID(x) for x in (low_ids or [])],
        [UUID(x) for x in (not_available_ids or [])],
    )
    return {"message": f"{count} items updated"}


@router.post("/voice", response_model=VoiceInventoryResponse)
def voice_update_inventory(
    voice_req: VoiceInventoryRequest,
    current_user: User = Depends(get_current_user),
    household: Household = Depends(get_current_household),
    db: Session = Depends(get_db),
):
    parsed = parse_inventory_text(voice_req.text, voice_req.language)

    if parsed["requires_confirmation"]:
        return VoiceInventoryResponse(
            intent=parsed["intent"],
            category=parsed.get("category"),
            add=parsed["add"],
            remove=parsed["remove"],
            set_low=parsed["set_low"],
            set_use_soon=parsed.get("set_use_soon", []),
            confidence=parsed["confidence"],
            message=parsed.get("message", "Please confirm this inventory update"),
            requires_confirmation=True,
        )

    _apply_inventory_parsed(db, household.id, parsed)

    return VoiceInventoryResponse(
        intent=parsed["intent"],
        category=parsed.get("category"),
        add=parsed["add"],
        remove=parsed["remove"],
        set_low=parsed["set_low"],
        set_use_soon=parsed.get("set_use_soon", []),
        confidence=parsed["confidence"],
        message="Kitchen Updated",
        requires_confirmation=False,
    )


@router.post("/voice/confirm")
def confirm_voice_update(
    voice_req: VoiceInventoryRequest,
    current_user: User = Depends(get_current_user),
    household: Household = Depends(get_current_household),
    db: Session = Depends(get_db),
):
    parsed = parse_inventory_text(voice_req.text, voice_req.language)
    _apply_inventory_parsed(db, household.id, parsed)
    return {"message": "Kitchen Updated", "parsed": parsed}


def _apply_inventory_parsed(db: Session, household_id: UUID, parsed: dict):
    ingredient_cache = {}
    ingredients = db.query(Ingredient).all()
    for ing in ingredients:
        ingredient_cache[ing.name] = ing
        ingredient_cache[ing.display_name_en.lower()] = ing
        for alias in ing.aliases:
            ingredient_cache[alias.alias.lower()] = ing

    def _resolve(name: str):
        key = name.lower().strip()
        key = key.replace(" ", "_")
        if key in ingredient_cache:
            return ingredient_cache[key]
        for k, v in ingredient_cache.items():
            if isinstance(v, Ingredient) and (v.display_name_en.lower() == key or v.name.lower() == key):
                return v
        return None

    category_expansions = {
        "pulses": ["toor_dal", "moong_dal", "masoor_dal", "chana_dal", "urad_dal"],
        "vegetables": ["potato", "onion", "tomato", "cauliflower", "cabbage", "capsicum", "peas", "spinach", "okra", "eggplant", "lauki", "tori"],
        "spices": ["cumin_seeds", "turmeric_powder", "red_chili_powder", "coriander_powder", "garam_masala", "salt", "mustard_seeds", "asafoetida"],
        "grains": ["rice", "atta", "besan", "suji", "maida", "poha"],
        "dairy": ["milk", "curd", "paneer", "ghee", "butter", "cream", "cheese"],
    }

    if parsed["intent"] == "replace_all":
        db.query(InventoryItem).filter(InventoryItem.household_id == household_id).delete()
        for name in parsed.get("add", []):
            ing = _resolve(name)
            if ing:
                upsert_inventory_item(db, household_id, ing.id, "available")

    elif parsed["intent"] == "general_group" and parsed.get("category"):
        category_name = parsed["category"].lower()
        expansions = category_expansions.get(category_name, [])
        for name in expansions:
            ing = _resolve(name)
            if ing:
                upsert_inventory_item(db, household_id, ing.id, "available")

    elif parsed["intent"] == "replace_category" and parsed.get("category"):
        category_name = parsed["category"].upper()
        try:
            from app.models.ingredient import IngredientCategoryType
            cat = IngredientCategoryType[category_name]
            cat_ingredients = db.query(Ingredient).filter(Ingredient.category == cat).all()
            cat_ids = {c.id for c in cat_ingredients}

            current = db.query(InventoryItem).filter(
                InventoryItem.household_id == household_id,
                InventoryItem.ingredient_id.in_(cat_ids),
            ).all()
            for item in current:
                db.delete(item)

            for name in parsed.get("add", []):
                ing = _resolve(name)
                if ing and ing.category == cat:
                    upsert_inventory_item(db, household_id, ing.id, "available")
        except (KeyError, ValueError):
            pass

    else:
        for name in parsed.get("add", []):
            ing = _resolve(name)
            if ing:
                upsert_inventory_item(db, household_id, ing.id, "available")

        for name in parsed.get("remove", []):
            ing = _resolve(name)
            if ing:
                delete_inventory_item(db, household_id, ing.id)

        for name in parsed.get("set_low", []):
            ing = _resolve(name)
            if ing:
                upsert_inventory_item(db, household_id, ing.id, "low")

    db.commit()


@router.get("/use-soon")
def get_use_soon(
    current_user: User = Depends(get_current_user),
    household: Household = Depends(get_current_household),
    db: Session = Depends(get_db),
):
    items = get_use_soon_items(db, household.id)
    return {"items": items}


@router.get("/ingredients")
def list_ingredients(
    category: str = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    query = db.query(Ingredient).filter(Ingredient.is_active == True)
    if category:
        from app.models.ingredient import IngredientCategoryType
        try:
            cat = IngredientCategoryType[category.upper()]
            query = query.filter(Ingredient.category == cat)
        except (KeyError, ValueError):
            pass
    ingredients = query.order_by(Ingredient.name).all()
    return {
        "ingredients": [
            {
                "id": str(i.id),
                "name": i.name,
                "display_name_en": i.display_name_en,
                "display_name_hi": i.display_name_hi,
                "category": i.category.value,
                "storage_type": i.storage_type.value,
            }
            for i in ingredients
        ]
    }
