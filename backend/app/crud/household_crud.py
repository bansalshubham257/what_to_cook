from sqlalchemy.orm import Session
from app.models.household import Household, HouseholdMember
from app.models.user import User
from uuid import UUID


def create_household(db: Session, created_by: UUID, name: str = None) -> Household:
    household = Household(created_by=created_by, name=name)
    db.add(household)
    db.commit()
    db.refresh(household)
    return household


def add_household_member(
    db: Session,
    household_id: UUID,
    user_id: UUID,
    is_primary: bool = False,
    adults_count: int = 2,
    has_children: bool = False,
    children_count: int = 0,
    child_age_groups: str = None,
) -> HouseholdMember:
    member = HouseholdMember(
        household_id=household_id,
        user_id=user_id,
        is_primary=is_primary,
        adults_count=adults_count,
        has_children=has_children,
        children_count=children_count,
        child_age_groups=child_age_groups,
    )
    db.add(member)
    db.commit()
    db.refresh(member)
    return member


def get_household_by_id(db: Session, household_id: UUID) -> Household | None:
    return db.query(Household).filter(Household.id == household_id).first()


def get_household_for_user(db: Session, user_id: UUID) -> Household | None:
    member = db.query(HouseholdMember).filter(HouseholdMember.user_id == user_id).first()
    if member:
        return db.query(Household).filter(Household.id == member.household_id).first()
    return None


def get_household_members(db: Session, household_id: UUID) -> list:
    return db.query(HouseholdMember).filter(HouseholdMember.household_id == household_id).all()
