"""API dependencies for authentication and authorization."""

from typing import Annotated

from fastapi import Depends
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.core.errors import (
    AuthenticationError,
    InvalidTokenError,
    TokenRevokedError,
    UserNotFoundError,
)
from app.core.logging import get_logger
from app.core.security import decode_token, validate_token_claims
from app.db.mongodb import get_database

logger = get_logger(__name__)

# HTTP Bearer token security scheme
security = HTTPBearer(auto_error=False)


class CurrentUser:
    """Represents the currently authenticated user."""

    def __init__(self, user_id: str, email: str, full_name: str):
        self.user_id = user_id
        self.email = email
        self.full_name = full_name

    @property
    def id(self) -> str:
        """Get user ID."""
        return self.user_id


async def get_current_user(
    credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(security)],
    db: Annotated[AsyncIOMotorDatabase, Depends(get_database)],
) -> CurrentUser:
    """
    Get the currently authenticated user from JWT token.
    
    This dependency:
    1. Extracts and validates the JWT token
    2. Verifies the token hasn't been revoked
    3. Retrieves the user from the database
    4. Returns a CurrentUser object
    
    Args:
        credentials: HTTP Bearer credentials
        db: Database instance
        
    Returns:
        CurrentUser object
        
    Raises:
        AuthenticationError: If authentication fails
        InvalidTokenError: If token is invalid
        TokenRevokedError: If token has been revoked
        UserNotFoundError: If user doesn't exist
    """
    if credentials is None:
        raise AuthenticationError("No authentication credentials provided")

    token = credentials.credentials

    # Decode and validate access token
    payload = decode_token(token, refresh=False)

    if payload is None:
        raise InvalidTokenError()

    # Validate token claims
    if not validate_token_claims(payload):
        raise InvalidTokenError("Invalid token claims")

    # Get user ID from token subject
    user_id = payload.get("sub")
    if not user_id:
        raise InvalidTokenError("Token missing user ID")

    # Check if session/revoked
    await _check_session_revoked(db, user_id, token)

    # Retrieve user from database
    user = await db.users.find_one({"_id": user_id})

    if user is None:
        raise UserNotFoundError(user_id)

    return CurrentUser(
        user_id=user["_id"],
        email=user["email"],
        full_name=user["full_name"],
    )


async def _check_session_revoked(
    db: AsyncIOMotorDatabase,
    user_id: str,
    token: str,
) -> None:
    """
    Check if the token's session has been revoked.
    
    Args:
        db: Database instance
        user_id: User ID
        token: JWT token
    """
    # Hash the token to look up in sessions
    from app.core.security import sha256_hash
    token_hash = sha256_hash(token.encode())

    # Check for revoked session
    session = await db.sessions.find_one({
        "user_id": user_id,
        "token_hash": token_hash,
        "revoked_at": {"$ne": None}
    })

    if session:
        raise TokenRevokedError()


async def get_optional_user(
    credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(security)],
    db: Annotated[AsyncIOMotorDatabase, Depends(get_database)],
) -> CurrentUser | None:
    """
    Get the current user if authenticated, otherwise return None.
    
    Useful for endpoints that work for both authenticated and anonymous users.
    
    Args:
        credentials: HTTP Bearer credentials
        db: Database instance
        
    Returns:
        CurrentUser if authenticated, None otherwise
    """
    try:
        return await get_current_user(credentials, db)
    except (AuthenticationError, InvalidTokenError):
        return None


# Type alias for dependency injection
CurrentUserDep = Annotated[CurrentUser, Depends(get_current_user)]
OptionalUserDep = Annotated[CurrentUser | None, Depends(get_optional_user)]


async def verify_user_ownership(
    resource_user_id: str,
    current_user: CurrentUserDep,
) -> bool:
    """
    Verify that the current user owns the specified resource.
    
    Args:
        resource_user_id: User ID associated with the resource
        current_user: Currently authenticated user
        
    Returns:
        True if user owns the resource
        
    Raises:
        AuthorizationError: If user doesn't own the resource
    """
    from app.core.errors import AuthorizationError

    if resource_user_id != current_user.id:
        raise AuthorizationError("You do not have permission to access this resource")

    return True
