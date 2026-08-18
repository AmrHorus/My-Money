"""UUID-based ID generation strategy for consistent domain IDs.

This module provides a centralized ID generation strategy using UUIDv4.
All domain entities should use UUIDs for their public-facing IDs to ensure:
- Offline creation capability
- Cross-platform consistency
- Idempotency support
- Conflict resolution
"""

import uuid


def generate_uuid() -> str:
    """Generate a new UUIDv4 string.
    
    Returns:
        UUIDv4 string in standard format (e.g., "550e8400-e29b-41d4-a716-446655440000")
    """
    return str(uuid.uuid4())


def validate_uuid(id_string: str) -> bool:
    """Validate that a string is a valid UUID.
    
    Args:
        id_string: String to validate
        
    Returns:
        True if valid UUID, False otherwise
    """
    try:
        uuid.UUID(id_string)
        return True
    except (ValueError, AttributeError):
        return False


def generate_idempotency_key(user_id: str, endpoint: str, timestamp: int) -> str:
    """Generate a deterministic idempotency key for a request.
    
    This can be used by clients to ensure exactly-once semantics for
    financial operations.
    
    Args:
        user_id: User ID
        endpoint: API endpoint path
        timestamp: Request timestamp (unix epoch seconds)
        
    Returns:
        Deterministic idempotency key
    """
    import hashlib
    
    data = f"{user_id}:{endpoint}:{timestamp}"
    hash_bytes = hashlib.sha256(data.encode()).digest()
    return str(uuid.UUID(bytes=hash_bytes[:16]))
