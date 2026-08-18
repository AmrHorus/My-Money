"""Idempotency management for financial operations.

This module provides idempotency key tracking to prevent duplicate
financial operations caused by:
- Network retries
- Timeout/retry scenarios
- Duplicate sync operations
- Client-side bugs

All financial mutation endpoints should check and record idempotency keys.
"""

from datetime import UTC, datetime, timedelta
from typing import Any

from motor.motor_asyncio import AsyncIOMotorDatabase

from app.core.logging import get_logger

logger = get_logger(__name__)


class IdempotencyManager:
    """Manages idempotency keys for financial operations."""
    
    def __init__(self, db: AsyncIOMotorDatabase):
        self.db = db
    
    async def check_idempotency(
        self,
        user_id: str,
        idempotency_key: str,
    ) -> dict[str, Any] | None:
        """Check if an idempotency key has been used.
        
        Args:
            user_id: User ID making the request
            idempotency_key: Unique key for this operation
            
        Returns:
            Previous response if key was used, None otherwise
        """
        record = await self.db.idempotency_keys.find_one({
            "user_id": user_id,
            "idempotency_key": idempotency_key,
            "expires_at": {"$gt": datetime.now(UTC)},
        })
        
        if record:
            if record.get("status") == "completed":
                logger.info(
                    f"Idempotency key reused: {idempotency_key} for user {user_id}"
                )
                return record.get("response")
            
            # Key is being processed (concurrent request)
            if record.get("status") == "processing":
                logger.warning(
                    f"Concurrent request detected for key: {idempotency_key}"
                )
                # Could wait and retry, or return conflict
                return None
        
        return None
    
    async def start_processing(
        self,
        user_id: str,
        idempotency_key: str,
        request_hash: str,
        endpoint: str,
        ttl_hours: int = 24,
    ) -> bool:
        """Mark an idempotency key as being processed.
        
        Uses an atomic upsert with condition to prevent race conditions.
        
        Args:
            user_id: User ID making the request
            idempotency_key: Unique key for this operation
            request_hash: Hash of request data for validation
            endpoint: API endpoint being called
            ttl_hours: Time-to-live for the idempotency record
            
        Returns:
            True if successfully marked as processing, False if key already exists
        """
        now = datetime.now(UTC)
        expires_at = now + timedelta(hours=ttl_hours)
        
        try:
            result = await self.db.idempotency_keys.update_one(
                {
                    "user_id": user_id,
                    "idempotency_key": idempotency_key,
                    "$or": [
                        {"expires_at": {"$lte": now}},
                        {"status": "completed"}
                    ]
                },
                {
                    "$setOnInsert": {
                        "user_id": user_id,
                        "idempotency_key": idempotency_key,
                        "request_hash": request_hash,
                        "endpoint": endpoint,
                        "created_at": now,
                        "status": "processing",
                        "response": None,
                    }
                },
                upsert=True,
            )
            
            # If matched_count > 0, an expired/completed record was found and will be replaced
            # If upserted_id is set, a new record was created
            return result.matched_count > 0 or result.upserted_id is not None
            
        except Exception as e:
            logger.error(f"Failed to start idempotency processing: {e}")
            return False
    
    async def complete_operation(
        self,
        user_id: str,
        idempotency_key: str,
        response: dict[str, Any],
    ) -> bool:
        """Mark an idempotency key as completed with response.
        
        Args:
            user_id: User ID making the request
            idempotency_key: Unique key for this operation
            response: Response data to store
            
        Returns:
            True if successfully updated, False otherwise
        """
        try:
            result = await self.db.idempotency_keys.update_one(
                {
                    "user_id": user_id,
                    "idempotency_key": idempotency_key,
                    "status": "processing",
                },
                {
                    "$set": {
                        "status": "completed",
                        "response": response,
                        "completed_at": datetime.now(UTC),
                    }
                },
            )
            
            return result.modified_count > 0
            
        except Exception as e:
            logger.error(f"Failed to complete idempotency operation: {e}")
            return False
    
    async def validate_request_hash(
        self,
        user_id: str,
        idempotency_key: str,
        request_hash: str,
    ) -> bool:
        """Validate that a repeated request has the same hash.
        
        If the same idempotency key is used with different request data,
        this indicates a potential bug or attack.
        
        Args:
            user_id: User ID making the request
            idempotency_key: Unique key for this operation
            request_hash: Hash of current request data
            
        Returns:
            True if hash matches, False otherwise
        """
        record = await self.db.idempotency_keys.find_one({
            "user_id": user_id,
            "idempotency_key": idempotency_key,
            "status": "completed",
        })
        
        if not record:
            return True  # No previous record to compare
        
        stored_hash = record.get("request_hash")
        if stored_hash != request_hash:
            logger.warning(
                f"Idempotency key {idempotency_key} reused with different request data"
            )
            return False
        
        return True
    
    async def cleanup_expired(self) -> int:
        """Remove expired idempotency keys.
        
        Should be run periodically (e.g., daily).
        
        Returns:
            Number of records deleted
        """
        result = await self.db.idempotency_keys.delete_many({
            "expires_at": {"$lte": datetime.now(UTC)},
        })
        
        logger.info(f"Cleaned up {result.deleted_count} expired idempotency keys")
        return result.deleted_count


def compute_request_hash(request_data: dict[str, Any]) -> str:
    """Compute a hash of request data for idempotency validation.
    
    Args:
        request_data: Request payload data
        
    Returns:
        SHA-256 hash of sorted JSON representation
    """
    import hashlib
    import json
    
    # Sort keys for deterministic hashing
    canonical = json.dumps(request_data, sort_keys=True, separators=(',', ':'))
    return hashlib.sha256(canonical.encode()).hexdigest()
