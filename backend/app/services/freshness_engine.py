import logging
from datetime import datetime, timedelta, timezone
from typing import Optional
from sqlalchemy.orm import Session
from uuid import UUID

from app.models.inventory import InventoryItem, InventoryStatus
from app.models.freshness import FreshnessRule, StorageType
from app.models.ingredient import Ingredient

logger = logging.getLogger(__name__)


def get_freshness_window(ingredient_id: UUID, db: Session) -> tuple[int, int, int]:
    rule = db.query(FreshnessRule).filter(FreshnessRule.ingredient_id == ingredient_id).first()
    if rule:
        return rule.freshness_days_min, rule.freshness_days_max, rule.use_soon_threshold_days
    return 1, 7, 3


def calculate_freshness_status(
    date_added: datetime,
    freshness_max_days: int,
    use_soon_threshold: int,
) -> tuple[InventoryStatus, int]:
    if not date_added.tzinfo:
        date_added = date_added.replace(tzinfo=timezone.utc)
    days_since_added = (datetime.now(timezone.utc) - date_added).days

    if days_since_added >= use_soon_threshold:
        return InventoryStatus.USE_SOON, days_since_added
    elif days_since_added >= freshness_max_days:
        return InventoryStatus.USE_SOON, days_since_added
    else:
        return InventoryStatus.AVAILABLE, days_since_added


def get_use_soon_items(db: Session, household_id: UUID) -> list[dict]:
    items = (
        db.query(InventoryItem, Ingredient)
        .join(Ingredient, InventoryItem.ingredient_id == Ingredient.id)
        .filter(
            InventoryItem.household_id == household_id,
            InventoryItem.status.in_([InventoryStatus.AVAILABLE, InventoryStatus.LOW, InventoryStatus.USE_SOON]),
        )
        .all()
    )

    use_soon = []
    for inv_item, ingredient in items:
        if inv_item.date_added:
            freshness_days = inv_item.freshness_window_days or 7
            status, days = calculate_freshness_status(
                inv_item.date_added, freshness_days, max(3, freshness_days // 2)
            )
            if status == InventoryStatus.USE_SOON or inv_item.status == InventoryStatus.USE_SOON:
                use_soon.append({
                    "ingredient_id": ingredient.id,
                    "ingredient_name": ingredient.display_name_en,
                    "days_since_added": days,
                    "status": inv_item.status.value,
                })

    use_soon.sort(key=lambda x: x["days_since_added"], reverse=True)
    return use_soon


def check_and_update_freshness(db: Session, household_id: UUID) -> int:
    items = (
        db.query(InventoryItem, Ingredient)
        .join(Ingredient, InventoryItem.ingredient_id == Ingredient.id)
        .filter(
            InventoryItem.household_id == household_id,
            InventoryItem.date_added.isnot(None),
        )
        .all()
    )

    updated_count = 0
    for inv_item, ingredient in items:
        freshness_days = inv_item.freshness_window_days or 7
        status, days = calculate_freshness_status(
            inv_item.date_added, freshness_days, max(3, freshness_days // 2)
        )
        if status == InventoryStatus.USE_SOON and inv_item.status != InventoryStatus.USE_SOON:
            inv_item.status = InventoryStatus.USE_SOON
            updated_count += 1

    if updated_count:
        db.commit()

    return updated_count
