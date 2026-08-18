"""MongoDB database connection and management."""


from motor.motor_asyncio import AsyncIOMotorClient, AsyncIOMotorDatabase
from pymongo.errors import ConnectionFailure, ServerSelectionTimeoutError

from app.core.config import settings
from app.core.logging import get_logger

logger = get_logger(__name__)

# Global database client instance
_client: AsyncIOMotorClient | None = None
_db: AsyncIOMotorDatabase | None = None


def get_connection_string() -> str:
    """Get MongoDB connection string from settings."""
    return settings.mongodb_uri


def get_database_name() -> str:
    """Get database name from settings."""
    return settings.mongodb_database


async def connect_to_mongodb() -> None:
    """
    Establish connection to MongoDB.
    
    Raises:
        ConnectionFailure: If connection cannot be established
    """
    global _client, _db

    try:
        logger.info(f"Connecting to MongoDB at {settings.mongodb_uri}")

        _client = AsyncIOMotorClient(
            settings.mongodb_uri,
            serverSelectionTimeoutMS=5000,
            connectTimeoutMS=10000,
            socketTimeoutMS=10000,
            maxPoolSize=50,
            minPoolSize=10,
        )

        # Verify connection by pinging
        await _client.admin.command("ping")

        _db = _client[settings.mongodb_database]

        logger.info(f"Successfully connected to MongoDB database: {settings.mongodb_database}")

    except (ConnectionFailure, ServerSelectionTimeoutError) as e:
        logger.error(f"Failed to connect to MongoDB: {e}")
        raise


async def disconnect_from_mongodb() -> None:
    """Close MongoDB connection."""
    global _client, _db

    if _client:
        logger.info("Closing MongoDB connection")
        _client.close()
        _client = None
        _db = None


def get_database() -> AsyncIOMotorDatabase:
    """
    Get the database instance.
    
    Returns:
        AsyncIOMotorDatabase instance
        
    Raises:
        RuntimeError: If not connected to MongoDB
    """
    if _db is None:
        raise RuntimeError("Not connected to MongoDB. Call connect_to_mongodb() first.")
    return _db


def get_client() -> AsyncIOMotorClient:
    """
    Get the database client instance.
    
    Returns:
        AsyncIOMotorClient instance
        
    Raises:
        RuntimeError: If not connected to MongoDB
    """
    if _client is None:
        raise RuntimeError("Not connected to MongoDB. Call connect_to_mongodb() first.")
    return _client


async def verify_connection() -> bool:
    """
    Verify that MongoDB connection is healthy.
    
    Returns:
        True if connection is healthy, False otherwise
    """
    try:
        if _client is None:
            return False

        await _client.admin.command("ping")
        return True

    except Exception as e:
        logger.error(f"MongoDB connection verification failed: {e}")
        return False


# Collection names constants
COLLECTION_USERS = "users"
COLLECTION_TRANSACTIONS = "transactions"
COLLECTION_ACCOUNTS = "accounts"
COLLECTION_BUDGETS = "budgets"
COLLECTION_SAVINGS_GOALS = "savings_goals"
COLLECTION_RECURRING_EXPENSES = "recurring_expenses"
COLLECTION_CATEGORIES = "categories"
COLLECTION_SYNC_EVENTS = "sync_events"
COLLECTION_AUDIT_LOGS = "audit_logs"
COLLECTION_SESSIONS = "sessions"
