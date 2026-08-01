from pydantic_settings import BaseSettings
from typing import List
import os


class Settings(BaseSettings):
    APP_NAME: str = "WhatToCook"
    DEBUG: bool = True
    ENVIRONMENT: str = "development"
    LOG_LEVEL: str = "DEBUG"

    DATABASE_URL: str = "postgresql://postgres:password@localhost:5432/what_to_cook"

    JWT_SECRET_KEY: str = "change-this-to-a-secure-random-key"
    JWT_ALGORITHM: str = "HS256"
    JWT_EXPIRATION_HOURS: int = 72

    AI_API_KEY: str = ""
    AI_PROVIDER: str = "openai"
    AI_MODEL: str = "gpt-4o-mini"
    AI_API_BASE: str = ""

    FIREBASE_CREDENTIALS_PATH: str = "./firebase-credentials.json"

    CORS_ORIGINS: List[str] = ["*"]

    REDIS_URL: str = "redis://localhost:6379/0"

    SENTRY_DSN: str = ""

    class Config:
        env_file = ".env"
        case_sensitive = True


settings = Settings()

if os.getenv("DATABASE_URL"):
    settings.DATABASE_URL = os.getenv("DATABASE_URL")
if os.getenv("AI_API_KEY"):
    settings.AI_API_KEY = os.getenv("AI_API_KEY")
if os.getenv("JWT_SECRET_KEY"):
    settings.JWT_SECRET_KEY = os.getenv("JWT_SECRET_KEY")
