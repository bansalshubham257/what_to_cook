from sqlalchemy.orm import Session
from sqlalchemy import or_
from app.models.user import User, DietType
from app.core.security import hash_password
from uuid import UUID


def get_user_by_id(db: Session, user_id: UUID) -> User | None:
    return db.query(User).filter(User.id == user_id, User.is_active == True).first()


def get_user_by_email(db: Session, email: str) -> User | None:
    return db.query(User).filter(User.email == email, User.is_active == True).first()


def get_user_by_phone(db: Session, phone: str) -> User | None:
    return db.query(User).filter(User.phone == phone, User.is_active == True).first()


def get_user_by_firebase_uid(db: Session, firebase_uid: str) -> User | None:
    return db.query(User).filter(User.firebase_uid == firebase_uid).first()


def create_user(db: Session, user_data: dict) -> User:
    if "password" in user_data and user_data["password"]:
        user_data["password_hash"] = hash_password(user_data.pop("password"))
    user = User(**user_data)
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


def update_user(db: Session, user_id: UUID, update_data: dict) -> User | None:
    user = get_user_by_id(db, user_id)
    if not user:
        return None
    for key, value in update_data.items():
        if value is not None:
            setattr(user, key, value)
    db.commit()
    db.refresh(user)
    return user
