import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings
from app.core.database import init_db
from app.api.v1.auth import router as auth_router
from app.api.v1.onboarding import router as onboarding_router
from app.api.v1.kitchen import router as kitchen_router
from app.api.v1.recommendations import router as recommendations_router
from app.api.v1.recipes import router as recipes_router
from app.api.v1.meals import router as meals_router
from app.api.v1.insights import router as insights_router
from app.api.v1.shopping import router as shopping_router

logging.basicConfig(level=getattr(logging, settings.LOG_LEVEL, logging.INFO))
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info(f"Starting {settings.APP_NAME} in {settings.ENVIRONMENT} mode")
    init_db()
    logger.info("Database schema and tables created/verified")
    yield
    logger.info("Shutting down")


app = FastAPI(
    title=settings.APP_NAME,
    description="AI Smart Kitchen & What Should I Cook App",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_router, prefix="/api/v1")
app.include_router(onboarding_router, prefix="/api/v1")
app.include_router(kitchen_router, prefix="/api/v1")
app.include_router(recommendations_router, prefix="/api/v1")
app.include_router(recipes_router, prefix="/api/v1")
app.include_router(meals_router, prefix="/api/v1")
app.include_router(insights_router, prefix="/api/v1")
app.include_router(shopping_router, prefix="/api/v1")


@app.get("/")
def root():
    return {"app": settings.APP_NAME, "version": "1.0.0", "status": "running"}


@app.get("/health")
def health():
    return {"status": "healthy"}
