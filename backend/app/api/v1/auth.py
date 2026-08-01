from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.core.security import verify_password, create_access_token
from app.crud.user_crud import get_user_by_email, get_user_by_phone, get_user_by_firebase_uid, create_user
from app.schemas.user import UserCreate, UserLogin, TokenResponse, UserResponse

router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post("/register", response_model=TokenResponse)
def register(user_data: UserCreate, db: Session = Depends(get_db)):
    if user_data.email:
        existing = get_user_by_email(db, user_data.email)
        if existing:
            raise HTTPException(status_code=400, detail="Email already registered")
    if user_data.phone:
        existing = get_user_by_phone(db, user_data.phone)
        if existing:
            raise HTTPException(status_code=400, detail="Phone already registered")

    user = create_user(db, user_data.model_dump(exclude_none=True))

    token = create_access_token({"sub": str(user.id), "email": user.email})
    return TokenResponse(
        access_token=token,
        user=UserResponse.model_validate(user),
    )


@router.post("/login", response_model=TokenResponse)
def login(login_data: UserLogin, db: Session = Depends(get_db)):
    user = None

    if login_data.firebase_token:
        user = get_user_by_firebase_uid(db, login_data.firebase_token)
    elif login_data.email:
        user = get_user_by_email(db, login_data.email)
        if user and login_data.password:
            if not verify_password(login_data.password, user.password_hash):
                raise HTTPException(status_code=401, detail="Invalid credentials")
    elif login_data.phone:
        user = get_user_by_phone(db, login_data.phone)

    if not user:
        raise HTTPException(status_code=401, detail="Invalid credentials")

    token = create_access_token({"sub": str(user.id), "email": user.email})
    return TokenResponse(
        access_token=token,
        user=UserResponse.model_validate(user),
    )
