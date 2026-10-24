"""Environment configuration (Appendix A)."""
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore", case_sensitive=False)

    supabase_url: str = ""
    supabase_service_role_key: str = ""
    supabase_jwt_audience: str = "authenticated"
    supabase_jwks_url: str = ""
    supabase_jwt_secret: str = ""
    operator_signup_code: str = ""
    database_url: str = "postgresql+asyncpg://postgres:postgres@localhost:5432/postgres"
    twin_service_token: str = ""
    cors_origins: str = ""
    ml_model_bucket: str = "ml-models"
    evidence_bucket: str = "repair-evidence"
    fcm_credentials_json: str = ""
    log_level: str = "INFO"
    # extras
    enable_workers: bool = True
    app_timezone: str = "Asia/Kolkata"
    ml_local_dir: str = "./artifacts"

    @property
    def cors_list(self) -> list[str]:
        return [o.strip() for o in self.cors_origins.split(",") if o.strip()]


settings = Settings()
