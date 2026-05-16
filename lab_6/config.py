from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    DATABASE_URL: str = "postgresql://user:password@localhost:5432/postgres"
    API_PREFIX: str = "/api/v1"

    class Config:
        env_file = ".env"


settings = Settings()
