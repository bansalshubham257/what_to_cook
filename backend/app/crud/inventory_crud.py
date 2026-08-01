from sqlalchemy.orm import Session
from sqlalchemy import and_
from app.models.inventory import InventoryItem, InventoryStatus
from app.models.ingredient import Ingredient
from uuid import UUID


def get_inventory(db: Session, household_id: UUID) -> list:
    return (
        db.query(InventoryItem)
        .filter(InventoryItem.household_id == household_id)
        .all()
    )


def get_inventory_with_ingredients(db: Session, household_id: UUID) -> list:
    return (
        db.query(InventoryItem, Ingredient)
        .join(Ingredient, InventoryItem.ingredient_id == Ingredient.id)
        .filter(InventoryItem.household_id == household_id)
        .all()
    )


def get_inventory_item(db: Session, household_id: UUID, ingredient_id: UUID) -> InventoryItem | None:
    return (
        db.query(InventoryItem)
        .filter(
            and_(
                InventoryItem.household_id == household_id,
                InventoryItem.ingredient_id == ingredient_id,
            )
        )
        .first()
    )


def upsert_inventory_item(
    db: Session,
    household_id: UUID,
    ingredient_id: UUID,
    status: str = "available",
    quantity: str = None,
    unit: str = None,
    freshness_window_days: int = None,
) -> InventoryItem:
    item = get_inventory_item(db, household_id, ingredient_id)
    if item:
        item.status = InventoryStatus(status)
        if quantity:
            item.quantity = quantity
        if unit:
            item.unit = unit
        if freshness_window_days:
            item.freshness_window_days = freshness_window_days
    else:
        item = InventoryItem(
            household_id=household_id,
            ingredient_id=ingredient_id,
            status=InventoryStatus(status),
            quantity=quantity,
            unit=unit,
            freshness_window_days=freshness_window_days,
        )
        db.add(item)
    db.commit()
    db.refresh(item)
    return item


def delete_inventory_item(db: Session, household_id: UUID, ingredient_id: UUID) -> bool:
    item = get_inventory_item(db, household_id, ingredient_id)
    if item:
        db.delete(item)
        db.commit()
        return True
    return False


def bulk_update_inventory(
    db: Session,
    household_id: UUID,
    available_ids: list[UUID] = None,
    low_ids: list[UUID] = None,
    not_available_ids: list[UUID] = None,
) -> int:
    count = 0
    if available_ids:
        for iid in available_ids:
            upsert_inventory_item(db, household_id, iid, "available")
            count += 1
    if low_ids:
        for iid in low_ids:
            upsert_inventory_item(db, household_id, iid, "low")
            count += 1
    if not_available_ids:
        for iid in not_available_ids:
            db_item = get_inventory_item(db, household_id, iid)
            if db_item:
                delete_inventory_item(db, household_id, iid)
            count += 1
    return count


def set_category_inventory(
    db: Session,
    household_id: UUID,
    category: str,
    available_ingredient_names: list[str],
) -> int:
    ingredients = (
        db.query(Ingredient)
        .filter(Ingredient.category == category, Ingredient.name.in_(available_ingredient_names))
        .all()
    )
    category_ingredients = db.query(Ingredient).filter(Ingredient.category == category).all()

    available_ids = {i.id for i in ingredients}
    all_category_ids = {i.id for i in category_ingredients}
    to_remove_ids = all_category_ids - available_ids

    for iid in available_ids:
        upsert_inventory_item(db, household_id, iid, "available")

    for iid in to_remove_ids:
        delete_inventory_item(db, household_id, iid)

    return len(available_ids)
