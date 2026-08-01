from fastapi import Depends
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.models.user import User
from app.models.household import Household, HouseholdMember


def get_current_user(db: Session = Depends(get_db)):
    user = db.query(User).filter(User.is_active == True).first()
    if user is None:
        user = User(display_name="Guest", email="guest@whattocook.app")
        db.add(user)
        db.commit()
        db.refresh(user)
    return user


def get_current_household(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    household = db.query(Household).first()
    if household is None:
        household = Household(name="Default Kitchen", created_by=current_user.id)
        db.add(household)
        db.flush()
        member = HouseholdMember(
            household_id=household.id,
            user_id=current_user.id,
            is_primary=True,
            role="owner",
        )
        db.add(member)
        db.commit()
        db.refresh(household)
    return household
