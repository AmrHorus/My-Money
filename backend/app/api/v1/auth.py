"""Authentication API endpoints."""

from datetime import datetime, timezone
from fastapi import APIRouter, Depends
from slowapi import Limiter
from slowapi.util import get_remote_address

from app.api.deps import CurrentUserDep, get_current_user
from app.core.security import (
    hash_password,
    verify_password,
    create_access_token,
    create_refresh_token,
    decode_token,
    sha256_hash,
)
from app.core.errors import (
    UserAlreadyExistsError,
    AuthenticationError,
    InvalidTokenError,
    SessionExpiredError,
)
from app.db.mongodb import get_database, COLLECTION_USERS, COLLECTION_SESSIONS
from app.schemas import (
    UserCreate,
    UserLogin,
    UserResponse,
    TokenResponse,
    RefreshTokenRequest,
)
from app.core.logging import get_logger

logger = get_logger(__name__)

router = APIRouter()
limiter = Limiter(key_func=get_remote_address)


@router.post("/register", response_model=UserResponse)
@limiter.limit("10 per minute")
async def register(
    request,
    user_data: UserCreate,
):
    """
    Register a new user account.
    
    - **email**: Valid email address (must be unique)
    - **password**: Password (min 8 chars, must include uppercase, lowercase, and digit)
    - **full_name**: User's full name
    """
    db = get_database()
    
    # Check if user already exists
    existing_user = await db.users.find_one({"email": user_data.email})
    if existing_user:
        raise UserAlreadyExistsError(user_data.email)
    
    # Create user document
    now = datetime.now(timezone.utc)
    user_document = {
        "_id": f"user_{sha256_hash(f'{user_data.email}{now.isoformat()}')[:12]}",
        "email": user_data.email,
        "password_hash": hash_password(user_data.password),
        "full_name": user_data.full_name,
        "primary_currency": "SAR",
        "is_active": True,
        "created_at": now,
        "updated_at": now,
    }
    
    # Insert user
    result = await db.users.insert_one(user_document)
    user_document["_id"] = result.inserted_id
    
    # Log audit event
    await _log_audit_event(db, user_document["_id"], "USER_REGISTERED", {"email": user_data.email})
    
    logger.info(f"New user registered: {user_data.email}")
    
    return UserResponse(
        id=str(user_document["_id"]),
        email=user_document["email"],
        full_name=user_document["full_name"],
        primary_currency=user_document["primary_currency"],
        created_at=user_document["created_at"],
        updated_at=user_document["updated_at"],
    )


@router.post("/login", response_model=TokenResponse)
@limiter.limit("5 per minute")
async def login(
    request,
    credentials: UserLogin,
):
    """
    Authenticate user and return access/refresh tokens.
    
    - **email**: User email address
    - **password**: User password
    """
    db = get_database()
    
    # Find user by email
    user = await db.users.find_one({"email": credentials.email})
    
    if not user:
        # Use same error message to prevent user enumeration
        raise AuthenticationError("Invalid email or password")
    
    # Verify password
    if not verify_password(credentials.password, user["password_hash"]):
        # Log failed login attempt
        await _log_audit_event(db, user["_id"], "LOGIN_FAILED", {"email": credentials.email})
        raise AuthenticationError("Invalid email or password")
    
    # Check if user is active
    if not user.get("is_active", True):
        raise AuthenticationError("Account is deactivated")
    
    # Generate tokens
    token_data = {"sub": str(user["_id"]), "email": user["email"]}
    access_token = create_access_token(token_data)
    refresh_token = create_refresh_token(token_data)
    
    # Store session (hash of refresh token)
    from datetime import timedelta
    from app.core.config import settings
    
    expires_at = datetime.now(timezone.utc) + timedelta(days=settings.refresh_token_expire_days)
    
    session_document = {
        "user_id": str(user["_id"]),
        "token_hash": sha256_hash(refresh_token.encode()),
        "created_at": datetime.now(timezone.utc),
        "expires_at": expires_at,
        "revoked_at": None,
        "device_info": None,  # Could extract from request headers
    }
    
    await db.sessions.insert_one(session_document)
    
    # Log successful login
    await _log_audit_event(db, user["_id"], "LOGIN_SUCCESS", {"email": credentials.email})
    
    logger.info(f"User logged in: {credentials.email}")
    
    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        token_type="bearer",
        expires_in=settings.access_token_expire_minutes * 60,
    )


@router.post("/refresh", response_model=TokenResponse)
@limiter.limit("10 per minute")
async def refresh_token(
    request,
    refresh_request: RefreshTokenRequest,
):
    """
    Refresh access token using a valid refresh token.
    
    This implements token rotation - the old refresh token is revoked
    and a new one is issued.
    """
    db = get_database()
    
    # Decode refresh token
    payload = decode_token(refresh_request.refresh_token, refresh=True)
    
    if payload is None:
        raise InvalidTokenError("Invalid or expired refresh token")
    
    user_id = payload.get("sub")
    if not user_id:
        raise InvalidTokenError("Invalid token payload")
    
    # Check if this token has been revoked
    old_token_hash = sha256_hash(refresh_request.refresh_token.encode())
    old_session = await db.sessions.find_one({
        "token_hash": old_token_hash,
        "revoked_at": {"$ne": None}
    })
    
    if old_session:
        # Token was already revoked - possible replay attack
        await _log_audit_event(db, user_id, "TOKEN_REPLAY_ATTEMPT", {})
        raise InvalidTokenError("Token has been revoked")
    
    # Revoke old token
    await db.sessions.update_one(
        {"token_hash": old_token_hash},
        {"$set": {"revoked_at": datetime.now(timezone.utc)}}
    )
    
    # Generate new tokens
    token_data = {"sub": user_id, "email": payload.get("email")}
    new_access_token = create_access_token(token_data)
    new_refresh_token = create_refresh_token(token_data)
    
    # Store new session
    from datetime import timedelta
    from app.core.config import settings
    
    expires_at = datetime.now(timezone.utc) + timedelta(days=settings.refresh_token_expire_days)
    
    session_document = {
        "user_id": user_id,
        "token_hash": sha256_hash(new_refresh_token.encode()),
        "created_at": datetime.now(timezone.utc),
        "expires_at": expires_at,
        "revoked_at": None,
    }
    
    await db.sessions.insert_one(session_document)
    
    logger.info(f"Token refreshed for user: {user_id}")
    
    return TokenResponse(
        access_token=new_access_token,
        refresh_token=new_refresh_token,
        token_type="bearer",
        expires_in=settings.access_token_expire_minutes * 60,
    )


@router.post("/logout")
async def logout(
    current_user: CurrentUserDep,
    refresh_request: RefreshTokenRequest | None = None,
):
    """
    Logout user by revoking their session(s).
    
    If a refresh token is provided, only that session is revoked.
    Otherwise, all sessions for the user are revoked.
    """
    db = get_database()
    
    if refresh_request and refresh_request.refresh_token:
        # Revoke specific session
        token_hash = sha256_hash(refresh_request.refresh_token.encode())
        await db.sessions.update_one(
            {"user_id": current_user.id, "token_hash": token_hash},
            {"$set": {"revoked_at": datetime.now(timezone.utc)}}
        )
    else:
        # Revoke all sessions
        await db.sessions.update_many(
            {"user_id": current_user.id, "revoked_at": None},
            {"$set": {"revoked_at": datetime.now(timezone.utc)}}
        )
    
    # Log audit event
    await _log_audit_event(db, current_user.id, "LOGOUT", {})
    
    logger.info(f"User logged out: {current_user.email}")
    
    return {"success": True, "message": "Logged out successfully"}


@router.get("/me", response_model=UserResponse)
async def get_current_user_info(
    current_user: CurrentUserDep,
):
    """Get current authenticated user information."""
    db = get_database()
    
    user = await db.users.find_one({"_id": current_user.id})
    
    if not user:
        raise AuthenticationError("User not found")
    
    return UserResponse(
        id=str(user["_id"]),
        email=user["email"],
        full_name=user["full_name"],
        primary_currency=user.get("primary_currency", "SAR"),
        created_at=user["created_at"],
        updated_at=user["updated_at"],
    )


async def _log_audit_event(db, user_id: str, event_type: str, details: dict):
    """Log an audit event."""
    audit_document = {
        "user_id": str(user_id),
        "event_type": event_type,
        "details": details,
        "timestamp": datetime.now(timezone.utc),
        "ip_address": None,  # Could extract from request
    }
    await db.audit_logs.insert_one(audit_document)
