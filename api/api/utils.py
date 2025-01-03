import typing as tp

from fastapi_cache.decorator import cache

from api.config import settings


def nocache(*_args: tp.Any, **_kwargs: tp.Any) -> tp.Callable:
    def decorator(func: tp.Callable) -> tp.Callable:
        return func

    return decorator


cache = cache if settings.redis else nocache
