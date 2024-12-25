from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        extra="ignore",
        validate_assignment=True,
        validate_default=True,
        validate_return=True,
    )
    mongodb_url: str
    mongodb_database_name: str
    redis_url: str | None = None

    def __str__(self) -> str:
        return self.__repr__()


settings = Settings()
