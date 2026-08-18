"""Application configuration with security validation."""

import os
import secrets
from typing import List
from pydantic_settings import BaseSettings
from pydantic import Field, field_validator


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""

    # Application
    app_env: str = Field(default="development", description="Environment: development or production")
    log_level: str = Field(default="INFO", description="Logging level")

    # MongoDB
    mongodb_uri: str = Field(..., description="MongoDB connection URI")
    mongodb_database: str = Field(default="my_money", description="MongoDB database name")

    # JWT Security
    jwt_secret: str = Field(..., description="JWT signing secret")
    jwt_refresh_secret: str = Field(..., description="JWT refresh token secret")
    access_token_expire_minutes: int = Field(default=30, description="Access token expiration in minutes")
    refresh_token_expire_days: int = Field(default=7, description="Refresh token expiration in days")

    # CORS
    cors_origins: str = Field(default="http://localhost:8000", description="Allowed CORS origins (comma-separated)")

    # Rate Limiting
    rate_limit_per_minute: int = Field(default=60, description="API rate limit per minute")

    # Rust Security Library (optional)
    rust_security_library: str | None = Field(default=None, description="Path to Rust security library")

    @field_validator("app_env")
    @classmethod
    def validate_app_env(cls, v: str) -> str:
        """Validate application environment."""
        if v not in ["development", "production"]:
            raise ValueError("APP_ENV must be 'development' or 'production'")
        return v

    @field_validator("jwt_secret", "jwt_refresh_secret")
    @classmethod
    def validate_secrets(cls, v: str, info) -> str:
        """Validate that secrets are sufficiently random in production."""
        if os.getenv("APP_ENV") == "production":
            if len(v) < 32:
                raise ValueError(f"{info.field_name} must be at least 32 characters in production")
            # Check for default/weak secrets
            weak_secrets = [
                "your-super-secret",
                "change-me",
                "secret",
                "password",
            ]
            if any(weak in v.lower() for weak in weak_secrets):
                raise ValueError(f"{info.field_name} appears to be a default value. Use a secure random value.")
        return v

    @property
    def parsed_cors_origins(self) -> List[str]:
        """Parse CORS origins from comma-separated string."""
        return [origin.strip() for origin in self.cors_origins.split(",") if origin.strip()]

    @property
    def is_production(self) -> bool:
        """Check if running in production environment."""
        return self.app_env == "production"

    def validate_production_secrets(self) -> None:
        """Validate that all required secrets are properly configured for production."""
        if not self.is_production:
            return

        errors = []

        # Check JWT secrets
        if len(self.jwt_secret) < 32:
            errors.append("JWT_SECRET must be at least 32 characters in production")
        if len(self.jwt_refresh_secret) < 32:
            errors.append("JWT_REFRESH_SECRET must be at least 32 characters in production")

        # Check for default secrets
        default_indicators = ["your-", "change-me", "secret", "password", "changeme"]
        for secret_name, secret_value in [
            ("JWT_SECRET", self.jwt_secret),
            ("JWT_REFRESH_SECRET", self.jwt_refresh_secret),
        ]:
            if any(indicator in secret_value.lower() for indicator in default_indicators):
                errors.append(f"{secret_name} appears to be a default value")

        if errors:
            raise ValueError(
                "Production security validation failed:\n" + "\n".join(f"  - {e}" for e in errors)
            )

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        case_sensitive = False


# Global settings instance
settings = Settings()

# Validate production secrets on import if in production mode
if settings.is_production:
    settings.validate_production_secrets()
