import typing as tp

import cashews
from fastapi import Depends
from motor.motor_asyncio import AsyncIOMotorClient, AsyncIOMotorDatabase
from pymongo import ReadPreference, WriteConcern
from redis import asyncio as aioredis

from api.config import settings

cashews.cache.setup("mem://")


@cashews.cache(ttl=None)
# async is needed for the cache to work
async def get_db_client() -> AsyncIOMotorClient:
    # cannot yield with cache
    return AsyncIOMotorClient(settings.mongodb.url, read_preference=ReadPreference.SECONDARY_PREFERRED)


@cashews.cache(ttl=None)
async def get_db(
    client: tp.Annotated[AsyncIOMotorClient, Depends(get_db_client)],
) -> AsyncIOMotorDatabase:
    return client.get_database(settings.mongodb.db_name, write_concern=WriteConcern(w=2))


@cashews.cache(ttl=None)
async def get_cache_backend() -> aioredis.Redis | aioredis.RedisCluster | None:
    if not settings.redis:
        return None
    if settings.redis.is_cluster:
        return aioredis.RedisCluster.from_url(settings.redis.url, decode_responses=True)
    return aioredis.Redis.from_url(settings.redis.url, decode_responses=True)
