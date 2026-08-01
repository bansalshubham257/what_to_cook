from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.api.deps import get_current_user
from app.models.user import User, DietType
from app.models.household import Household, HouseholdMember
from app.models.kitchen_profile import KitchenProfile, KitchenProfileItem
from app.models.inventory import InventoryItem, InventoryStatus
from app.schemas.household import OnboardingRequest, OnboardingResponse
from app.crud.household_crud import create_household, add_household_member
from uuid import UUID

router = APIRouter(prefix="/onboarding", tags=["Onboarding"])


@router.post("/complete", response_model=OnboardingResponse)
def complete_onboarding(
    req: OnboardingRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    current_user.diet_type = DietType(req.diet_type)
    current_user.language_preference = req.language_preference
    current_user.onboarding_completed = True

    child_age_str = ",".join(req.child_age_groups) if req.child_age_groups else None

    household = create_household(db, current_user.id, "My Household")
    add_household_member(
        db,
        household.id,
        current_user.id,
        is_primary=True,
        adults_count=req.adults_count,
        has_children=req.has_children,
        children_count=req.children_count,
        child_age_groups=child_age_str,
    )

    _apply_kitchen_profile(db, household.id, req.kitchen_profile_type)

    db.commit()

    return OnboardingResponse(
        user={"id": str(current_user.id), "diet_type": req.diet_type, "onboarding_completed": True},
        household={"id": str(household.id), "name": household.name},
        message="Onboarding completed successfully",
    )


def _apply_kitchen_profile(db: Session, household_id: UUID, profile_type: str):
    profile = db.query(KitchenProfile).filter(KitchenProfile.profile_type == profile_type).first()
    if not profile:
        profile = db.query(KitchenProfile).filter(KitchenProfile.is_default == True).first()
    if not profile:
        return

    items = db.query(KitchenProfileItem).filter(KitchenProfileItem.kitchen_profile_id == profile.id).all()
    for item in items:
        existing = db.query(InventoryItem).filter(
            InventoryItem.household_id == household_id,
            InventoryItem.ingredient_id == item.ingredient_id,
        ).first()
        if not existing:
            inv = InventoryItem(
                household_id=household_id,
                ingredient_id=item.ingredient_id,
                status=InventoryStatus.AVAILABLE if item.is_default else InventoryStatus.NOT_AVAILABLE,
            )
            db.add(inv)
