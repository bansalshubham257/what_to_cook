from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import datetime
from uuid import UUID


class UserCreate(BaseModel):
    email: Optional[EmailStr] = None
    phone: Optional[str] = None
    firebase_uid: Optional[str] = None
    display_name: Optional[str] = None
    password: Optional[str] = None


class UserLogin(BaseModel):
    email: Optional[EmailStr] = None
    phone: Optional[str] = None
    password: Optional[str] = None
    firebase_token: Optional[str] = None


class UserResponse(BaseModel):
    id: UUID
    email: Optional[str]
    phone: Optional[str]
    display_name: Optional[str]
    diet_type: Optional[str]
    language_preference: str
    onboarding_completed: bool
    is_active: bool
    created_at: datetime

    class Config:
        from_attributes = True


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserResponse
