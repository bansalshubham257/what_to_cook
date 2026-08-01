from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
from uuid import UUID


class HouseholdCreate(BaseModel):
    name: Optional[str] = None
    adults_count: int = 2
    has_children: bool = False
    children_count: int = 0
    child_age_groups: Optional[List[str]] = None


class HouseholdMemberResponse(BaseModel):
    id: UUID
    user_id: UUID
    is_primary: bool
    role: str
    adults_count: int
    has_children: bool
    children_count: int
    child_age_groups: Optional[str]

    class Config:
        from_attributes = True


class HouseholdResponse(BaseModel):
    id: UUID
    name: Optional[str]
    created_by: UUID
    members: List[HouseholdMemberResponse] = []
    created_at: datetime

    class Config:
        from_attributes = True


class OnboardingRequest(BaseModel):
    diet_type: str
    cuisine_preferences: List[str]
    kitchen_profile_type: str
    adults_count: int = 2
    has_children: bool = False
    children_count: int = 0
    child_age_groups: Optional[List[str]] = None
    language_preference: str = "en"


class OnboardingResponse(BaseModel):
    user: dict
    household: dict
    message: str
