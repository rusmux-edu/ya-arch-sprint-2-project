import os
import socket
import uuid

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict

SERVICE_NAME = "mongodb-api"
SERVICE_HOST_IP = socket.gethostbyname(socket.gethostname())


class BasePydanticSettings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        extra="ignore",
        validate_assignment=True,
        validate_default=True,
        validate_return=True,
    )


class MongoDBSettings(BasePydanticSettings):
    url: str
    db_name: str


class RedisSettings(BasePydanticSettings):
    url: str
    is_cluster: bool = False


class GatewaySettings(BasePydanticSettings):
    consul_url: str
    service_host_ip: str = SERVICE_HOST_IP
    service_port: int = int(os.environ["UVICORN_PORT"])
    service_id: str = Field(
        default_factory=lambda: f"{SERVICE_NAME}-{SERVICE_HOST_IP}-{str(uuid.uuid4())[:8]}"  # noqa: WPS221
    )
    service_tags: tuple[str] = ("mongodb-api",)
    route_prefix: str = "/mongodb-api"


class Settings(BasePydanticSettings):
    model_config = SettingsConfigDict(env_nested_delimiter="__")

    use_gateway: bool = False
    mongodb: MongoDBSettings
    redis: RedisSettings | None = None
    gateway: GatewaySettings | None = None

    def __str__(self) -> str:
        return self.__repr__()


settings = Settings()
