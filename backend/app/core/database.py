from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
from app.base import Base
from app.core.config import settings

def _build_database_url(base_url: str, schema: str) -> str:
    """Append schema as search_path option to PostgreSQL URL."""
    if "postgresql" in base_url and schema:
        separator = "&" if "?" in base_url else "?"
        return f"{base_url}{separator}options=-csearch_path%3D{schema}"
    return base_url

engine = create_engine(
    _build_database_url(settings.DATABASE_URL, settings.DATABASE_SCHEMA),
    pool_pre_ping=True,
    pool_size=10,
    max_overflow=20,
    connect_args={"options": f"-csearch_path={settings.DATABASE_SCHEMA}"} if "postgresql" in settings.DATABASE_URL else {},
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def init_db():
    """Create schema and all tables."""
    with engine.connect() as conn:
        conn.execute(text(f"CREATE SCHEMA IF NOT EXISTS {settings.DATABASE_SCHEMA}"))
        conn.commit()
    Base.metadata.create_all(bind=engine)