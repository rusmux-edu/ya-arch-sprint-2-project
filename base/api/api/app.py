import logging.config
import traceback
import typing as tp
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request, status
from fastapi.responses import PlainTextResponse
from fastapi_cache import FastAPICache
from fastapi_cache.backends.redis import RedisBackend
from logmiddleware import RouterLoggingMiddleware, logging_config
from redis import asyncio as aioredis

from api import __version__
from api.config import settings
from api.routes import router


async def internal_exception_handler(_request: Request, exc: Exception) -> PlainTextResponse:  # noqa: RUF029
    return PlainTextResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content="".join(traceback.format_exception_only(exc)),
    )


@asynccontextmanager
async def lifespan(_app: FastAPI) -> tp.AsyncIterator[None]:
    if settings.redis_url:
        redis = aioredis.from_url(settings.redis_url, encoding="utf8", decode_responses=True)
        FastAPICache.init(RedisBackend(redis), prefix="api:cache")
    yield


def create_app() -> FastAPI:
    logging.config.dictConfig(logging_config)
    logger = logging.getLogger(__name__)

    app = FastAPI(
        title="pymongo-api",
        version=__version__,
        root_path="/api/v1",
        lifespan=lifespan,
        exception_handlers={status.HTTP_500_INTERNAL_SERVER_ERROR: internal_exception_handler},
    )
    app.add_middleware(RouterLoggingMiddleware, logger=logger)
    app.include_router(router)
    return app
