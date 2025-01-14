import json
import time
import typing as tp

import async_timeout
import pymongo.errors
import redis.asyncio as aioredis
from fastapi import APIRouter, Depends, status
from fastapi.exceptions import HTTPException
from fastapi_cache import FastAPICache
from motor.motor_asyncio import AsyncIOMotorClient, AsyncIOMotorDatabase

from api.config import SERVICE_HOST_IP, settings
from api.factory import get_cache_backend, get_db, get_db_client
from api.models import UserCollection, UserModel
from api.utils.fastapi import route_cache

router = APIRouter()


@router.get("/livez")
async def livez() -> dict[str, str]:
    """Check if the service is alive."""
    return {"status": "alive", "host": SERVICE_HOST_IP}


@router.get("/readyz")
async def readyz(
    db: tp.Annotated[AsyncIOMotorDatabase, Depends(get_db)],
    cache_backend: tp.Annotated[aioredis.Redis | aioredis.RedisCluster | None, Depends(get_cache_backend)],
) -> dict[str, str]:
    """Check if the service is ready."""
    try:
        async with async_timeout.timeout(3):
            await db.command("ping")
    except Exception:  # noqa: BLE001
        raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE) from None

    if cache_backend:
        try:
            async with async_timeout.timeout(3):
                await cache_backend.ping()
        except Exception:  # noqa: BLE001
            raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE) from None

    return {"status": "ready", "host": SERVICE_HOST_IP}


@router.get("/")
async def root(
    client: tp.Annotated[AsyncIOMotorClient, Depends(get_db_client)],
    db: tp.Annotated[AsyncIOMotorDatabase, Depends(get_db)],
) -> dict:
    """Get metadata about MongoDB."""
    collections = {}
    for collection_name in await db.list_collection_names():
        collection = db.get_collection(collection_name)
        collections[collection_name] = {"documents_count": await collection.count_documents({})}
    try:
        replica_status = await client.admin.command("replSetGetStatus")
    except pymongo.errors.OperationFailure:
        replica_status = "No Replicas"
    else:
        replica_status = json.dumps(replica_status, indent=2, default=str)

    topology_description = client.topology_description
    topology_type = topology_description.topology_type_name  # type: ignore[attr-defined]

    shards = None
    if topology_type == "Sharded":
        shards_list = await client.admin.command("listShards")
        shards = {}
        for shard in shards_list.get("shards", {}):
            shards[shard["_id"]] = shard["host"]

    return {
        "mongo_topology_type": topology_type,
        "mongo_replicaset_name": topology_description.replica_set_name,  # type: ignore[attr-defined]
        "mongo_db": settings.mongodb.db_name,
        "read_preference": str(client.client_options.read_preference),
        "mongo_nodes": client.nodes,
        "mongo_primary_host": client.primary,
        "mongo_secondary_hosts": client.secondaries,
        "mongo_address": client.address,
        "mongo_is_primary": client.is_primary,
        "mongo_is_mongos": client.is_mongos,
        "collections": collections,
        "shards": shards,
        "cache_enabled": FastAPICache.get_enable() if settings.redis else False,
        "status": "OK",
    }


@router.get("/{collection_name}/count")
async def collection_count(
    db: tp.Annotated[AsyncIOMotorDatabase, Depends(get_db)],
    collection_name: str,
) -> dict:
    collection = db.get_collection(collection_name)
    items_count = await collection.count_documents({})
    return {"status": "OK", "mongo_db": settings.mongodb.db_name, "items_count": items_count}


@router.get("/{collection_name}/users", response_model_by_alias=False)
@route_cache(expire=60)
async def list_users(
    db: tp.Annotated[AsyncIOMotorDatabase, Depends(get_db)],
    collection_name: str,
) -> UserCollection:
    """List all the user data in the database.
    The response is not paginated and limited to 1000 results.
    """
    time.sleep(1)  # for demonstrating caching # noqa: ASYNC251
    collection = db.get_collection(collection_name)
    return UserCollection(users=await collection.find().to_list(1000))


@router.get("/{collection_name}/users/{name}", response_model_by_alias=False)
async def show_user(
    db: tp.Annotated[AsyncIOMotorDatabase, Depends(get_db)],
    collection_name: str,
    name: str,
) -> UserModel:
    """Get the record for a specific user, looked up by `name`."""
    collection = db.get_collection(collection_name)
    if (user := await collection.find_one({"name": name})) is not None:
        return user
    raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"User {name} not found")


@router.post(
    "/{collection_name}/users",
    status_code=status.HTTP_201_CREATED,
    response_model_by_alias=False,
)
async def create_user(
    db: tp.Annotated[AsyncIOMotorDatabase, Depends(get_db)],
    collection_name: str,
    user: UserModel,
) -> UserModel:
    """Insert a new user record. A unique `id` will be created and provided in the response."""
    collection = db.get_collection(collection_name)
    new_user = await collection.insert_one(user.model_dump(by_alias=True, exclude={"id"}))
    return await collection.find_one({"_id": new_user.inserted_id})  # type: ignore[return-value]
