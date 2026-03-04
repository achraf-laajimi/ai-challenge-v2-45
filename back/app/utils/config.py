"""Application configuration (env, secrets)."""
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """App settings from environment."""

    app_name: str = "Family Health API"
    debug: bool = False

    # MongoDB
    mongodb_url: str = "mongodb://localhost:27017"
    mongodb_db_name: str = "family_health"

    # JWT
    jwt_secret_key: str = "change-me-in-production-use-env"
    jwt_algorithm: str = "HS256"
    jwt_expire_minutes: int = 60 * 24 * 7  # 7 days
    # External APIs
    google_maps_api_key: str | None = None
    gemini_api_key: str | None = None

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


settings = Settings()
