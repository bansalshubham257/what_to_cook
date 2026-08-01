from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.api.deps import get_current_user, get_current_household
from app.models.user import User
from app.models.household import Household
from app.models.shopping_list import ShoppingList, ShoppingListItem, ShoppingItemStatus
from app.models.ingredient import Ingredient
from uuid import UUID
from datetime import datetime, timezone

router = APIRouter(prefix="/shopping", tags=["Shopping List"])


@router.get("/")
def get_shopping_list(
    current_user: User = Depends(get_current_user),
    household: Household = Depends(get_current_household),
    db: Session = Depends(get_db),
):
    shopping_list = (
        db.query(ShoppingList)
        .filter(ShoppingList.household_id == household.id, ShoppingList.is_active == True)
        .first()
    )
    if not shopping_list:
        return {"items": []}

    items = (
        db.query(ShoppingListItem, Ingredient)
        .join(Ingredient, ShoppingListItem.ingredient_id == Ingredient.id)
        .filter(ShoppingListItem.shopping_list_id == shopping_list.id)
        .all()
    )

    return {
        "list_id": str(shopping_list.id),
        "items": [
            {
                "id": str(item.id),
                "ingredient_id": str(ing.id),
                "name": ing.display_name_en,
                "quantity": item.quantity,
                "unit": item.unit,
                "status": item.status.value,
                "notes": item.notes,
            }
            for item, ing in items
        ],
    }


@router.post("/add")
def add_to_shopping_list(
    req: dict,
    current_user: User = Depends(get_current_user),
    household: Household = Depends(get_current_household),
    db: Session = Depends(get_db),
):
    ingredient_id = UUID(req["ingredient_id"])
    quantity = req.get("quantity")
    unit = req.get("unit")

    shopping_list = (
        db.query(ShoppingList)
        .filter(ShoppingList.household_id == household.id, ShoppingList.is_active == True)
        .first()
    )
    if not shopping_list:
        shopping_list = ShoppingList(household_id=household.id, name="Shopping List")
        db.add(shopping_list)
        db.flush()

    existing = (
        db.query(ShoppingListItem)
        .filter(
            ShoppingListItem.shopping_list_id == shopping_list.id,
            ShoppingListItem.ingredient_id == ingredient_id,
            ShoppingListItem.status == ShoppingItemStatus.PENDING,
        )
        .first()
    )
    if existing:
        return {"message": "Item already in shopping list", "item_id": str(existing.id)}

    item = ShoppingListItem(
        shopping_list_id=shopping_list.id,
        ingredient_id=ingredient_id,
        quantity=quantity,
        unit=unit,
        status=ShoppingItemStatus.PENDING,
        added_by=current_user.id,
    )
    db.add(item)
    db.commit()

    return {"message": "Added to shopping list", "item_id": str(item.id)}


@router.post("/{item_id}/toggle")
def toggle_item(
    item_id: str,
    current_user: User = Depends(get_current_user),
    household: Household = Depends(get_current_household),
    db: Session = Depends(get_db),
):
    item = db.query(ShoppingListItem).filter(ShoppingListItem.id == item_id).first()
    if not item:
        raise HTTPException(status_code=404, detail="Item not found")

    item.status = (
        ShoppingItemStatus.BOUGHT
        if item.status == ShoppingItemStatus.PENDING
        else ShoppingItemStatus.PENDING
    )
    db.commit()

    return {"message": "Item toggled", "status": item.status.value}


@router.delete("/{item_id}")
def remove_item(
    item_id: str,
    current_user: User = Depends(get_current_user),
    household: Household = Depends(get_current_household),
    db: Session = Depends(get_db),
):
    item = db.query(ShoppingListItem).filter(ShoppingListItem.id == item_id).first()
    if not item:
        raise HTTPException(status_code=404, detail="Item not found")
    db.delete(item)
    db.commit()
    return {"message": "Item removed"}


@router.post("/add-from-recipe/{recipe_id}")
def add_recipe_missing_ingredients(
    recipe_id: str,
    current_user: User = Depends(get_current_user),
    household: Household = Depends(get_current_household),
    db: Session = Depends(get_db),
):
    from app.models.inventory import InventoryItem, InventoryStatus
    from app.models.recipe import RecipeIngredient

    recipe_ingredients = (
        db.query(RecipeIngredient)
        .filter(RecipeIngredient.recipe_id == recipe_id, RecipeIngredient.is_required == True)
        .all()
    )

    inventory_ids = {
        item.ingredient_id
        for item in db.query(InventoryItem)
        .filter(InventoryItem.household_id == household.id, InventoryItem.status != InventoryStatus.NOT_AVAILABLE)
        .all()
    }

    shopping_list = (
        db.query(ShoppingList)
        .filter(ShoppingList.household_id == household.id, ShoppingList.is_active == True)
        .first()
    )
    if not shopping_list:
        shopping_list = ShoppingList(household_id=household.id, name="Shopping List")
        db.add(shopping_list)
        db.flush()

    added = []
    for ri in recipe_ingredients:
        if ri.ingredient_id not in inventory_ids:
            existing = (
                db.query(ShoppingListItem)
                .filter(
                    ShoppingListItem.shopping_list_id == shopping_list.id,
                    ShoppingListItem.ingredient_id == ri.ingredient_id,
                    ShoppingListItem.status == ShoppingItemStatus.PENDING,
                )
                .first()
            )
            if not existing:
                item = ShoppingListItem(
                    shopping_list_id=shopping_list.id,
                    ingredient_id=ri.ingredient_id,
                    quantity=ri.quantity,
                    unit=ri.unit,
                    status=ShoppingItemStatus.PENDING,
                    added_by=current_user.id,
                )
                db.add(item)
                ing = db.query(Ingredient).filter(Ingredient.id == ri.ingredient_id).first()
                added.append(ing.display_name_en if ing else str(ri.ingredient_id))

    db.commit()

    return {"message": f"Added {len(added)} items to shopping list", "items": added}
