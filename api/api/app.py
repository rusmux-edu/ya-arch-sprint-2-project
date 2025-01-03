# mypy: disable-error-code="union-attr"
import traceback
import typing as tp
from contextlib import asynccontextmanager

import httpx
from fastapi import FastAPI, Request, status
from fastapi.responses import PlainTextResponse
from fastapi_cache import FastAPICache
from fastapi_cache.backends.redis import RedisBackend
from redis import asyncio as aioredis

from api import __version__
from api.config import SERVICE_HOST_IP, SERVICE_NAME, settings
from api.routes import router


async def internal_exception_handler(_request: Request, exc: Exception) -> PlainTextResponse:  # noqa: RUF029
    return PlainTextResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content="".join(traceback.format_exception_only(exc)),
    )


@asynccontextmanager
async def lifespan(_app: FastAPI) -> tp.AsyncIterator[None]:
    if settings.redis:
        redis = aioredis.from_url(settings.redis.url, encoding="utf8", decode_responses=True)
        FastAPICache.init(RedisBackend(redis), prefix="api:cache")

    if settings.use_gateway and not settings.gateway:
        raise ValueError("gateway settings are required in production mode")

    if settings.use_gateway:
        registration_payload = {
            "ID": settings.gateway.service_id,
            "Name": SERVICE_NAME,
            "Tags": settings.gateway.service_tags,
            "Address": settings.gateway.service_host_ip,
            "Port": settings.gateway.service_port,
            "Weights": {"Passing": 10, "Warning": 1},
            "Check": {
                "HTTP": f"http://{settings.gateway.service_host_ip}:{settings.gateway.service_port}/livez",
                "Interval": "10s",
                "Timeout": "5s",
                "DeregisterCriticalServiceAfter": "1m",
            },
        }

        async with httpx.AsyncClient() as client:
            response = await client.put(
                f"{settings.gateway.consul_url}/v1/agent/service/register",
                json=registration_payload,
            )
            response.raise_for_status()

    yield

    if settings.use_gateway:
        async with httpx.AsyncClient() as client:
            response = await client.put(
                f"{settings.gateway.consul_url}/v1/agent/service/deregister/{settings.gateway.service_id}",
            )
            response.raise_for_status()


def create_app() -> FastAPI:
    app = FastAPI(
        title="pymongo-api",
        description=f"Hosted at {SERVICE_HOST_IP}.",
        version=__version__,
        root_path=settings.gateway.route_prefix if settings.use_gateway else "",
        lifespan=lifespan,
        exception_handlers={status.HTTP_500_INTERNAL_SERVER_ERROR: internal_exception_handler},
    )
    app.include_router(router)

    return app
