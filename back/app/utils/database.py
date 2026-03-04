"""MongoDB connection and collections."""
from motor.motor_asyncio import AsyncIOMotorClient, AsyncIOMotorDatabase

from app.utils.config import settings

_client: AsyncIOMotorClient | None = None
_db: AsyncIOMotorDatabase | None = None


async def get_database() -> AsyncIOMotorDatabase:
    """Return the MongoDB database instance (singleton)."""
    global _client, _db
    if _db is None:
        _client = AsyncIOMotorClient(settings.mongodb_url)
        _db = _client[settings.mongodb_db_name]
    return _db


async def close_database() -> None:
    """Close MongoDB connection (e.g. on shutdown)."""
    global _client, _db
    if _client is not None:
        _client.close()
        _client = None
        _db = None


def get_users_collection(db: AsyncIOMotorDatabase):
    return db["users"]


def get_families_collection(db: AsyncIOMotorDatabase):
    return db["families"]


def get_persons_collection(db: AsyncIOMotorDatabase):
    return db["persons"]
