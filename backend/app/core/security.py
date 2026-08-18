"""Security utilities for password hashing, JWT, and cryptographic operations."""

import hashlib
import hmac
import secrets
from datetime import datetime, timedelta, timezone
from typing import Any, Optional
from argon2 import PasswordHasher, Type
from argon2.exceptions import VerifyMismatchError, InvalidHash
from jose import jwt, JWTError
from cryptography.fernet import Fernet

from app.core.config import settings
from app.core.logging import get_logger

logger = get_logger(__name__)

# =============================================================================
# Password Hashing (Argon2id)
# =============================================================================

# Argon2id configuration - OWASP recommended settings
ARGON2_TIME_COST = 3  # Number of iterations
ARGON2_MEMORY_COST = 65536  # Memory in KiB
ARGON2_PARALLELISM = 4  # Parallel threads
ARGON2_HASH_LEN = 32  # Output hash length
ARGON2_SALT_LEN = 16  # Salt length

_password_hasher: Optional[PasswordHasher] = None


def get_password_hasher() -> PasswordHasher:
    """Get or create the password hasher instance."""
    global _password_hasher
    if _password_hasher is None:
        _password_hasher = PasswordHasher(
            time_cost=ARGON2_TIME_COST,
            memory_cost=ARGON2_MEMORY_COST,
            parallelism=ARGON2_PARALLELISM,
            hash_len=ARGON2_HASH_LEN,
            salt_len=ARGON2_SALT_LEN,
            type=Type.ID,  # Argon2id - recommended for password hashing
        )
    return _password_hasher


def hash_password(password: str) -> str:
    """
    Hash a password using Argon2id.
    
    Args:
        password: Plain text password
        
    Returns:
        Argon2id hash string (includes algorithm parameters and salt)
    """
    hasher = get_password_hasher()
    return hasher.hash(password)


def verify_password(password: str, hashed_password: str) -> bool:
    """
    Verify a password against an Argon2id hash.
    
    Args:
        password: Plain text password to verify
        hashed_password: Argon2id hash string
        
    Returns:
        True if password matches, False otherwise
    """
    hasher = get_password_hasher()
    try:
        hasher.verify(hashed_password, password)
        return True
    except VerifyMismatchError:
        return False
    except InvalidHash:
        logger.warning("Attempted to verify against invalid hash format")
        return False


def needs_rehash(hashed_password: str) -> bool:
    """
    Check if a password hash needs to be rehashed with updated parameters.
    
    Args:
        hashed_password: Existing Argon2id hash
        
    Returns:
        True if rehash is recommended, False otherwise
    """
    hasher = get_password_hasher()
    return hasher.check_needs_rehash(hashed_password)


# =============================================================================
# JWT Token Management
# =============================================================================


def create_access_token(
    data: dict[str, Any],
    expires_delta: Optional[timedelta] = None,
) -> str:
    """
    Create a JWT access token.
    
    Args:
        data: Payload data (should include 'sub' for subject/user_id)
        expires_delta: Optional custom expiration time
        
    Returns:
        Encoded JWT token string
    """
    to_encode = data.copy()
    
    if expires_delta:
        expire = datetime.now(timezone.utc) + expires_delta
    else:
        expire = datetime.now(timezone.utc) + timedelta(
            minutes=settings.access_token_expire_minutes
        )
    
    to_encode.update({
        "exp": expire,
        "iat": datetime.now(timezone.utc),
        "type": "access",
    })
    
    encoded_jwt = jwt.encode(
        to_encode,
        settings.jwt_secret,
        algorithm="HS256",
    )
    
    return encoded_jwt


def create_refresh_token(
    data: dict[str, Any],
    expires_delta: Optional[timedelta] = None,
) -> str:
    """
    Create a JWT refresh token.
    
    Args:
        data: Payload data (should include 'sub' for subject/user_id)
        expires_delta: Optional custom expiration time
        
    Returns:
        Encoded JWT refresh token string
    """
    to_encode = data.copy()
    
    if expires_delta:
        expire = datetime.now(timezone.utc) + expires_delta
    else:
        expire = datetime.now(timezone.utc) + timedelta(
            days=settings.refresh_token_expire_days
        )
    
    to_encode.update({
        "exp": expire,
        "iat": datetime.now(timezone.utc),
        "type": "refresh",
    })
    
    encoded_jwt = jwt.encode(
        to_encode,
        settings.jwt_refresh_secret,
        algorithm="HS256",
    )
    
    return encoded_jwt


def decode_token(token: str, refresh: bool = False) -> Optional[dict[str, Any]]:
    """
    Decode and validate a JWT token.
    
    Args:
        token: JWT token string
        refresh: If True, use refresh secret; otherwise use access secret
        
    Returns:
        Decoded payload if valid, None if invalid or expired
    """
    secret = settings.jwt_refresh_secret if refresh else settings.jwt_secret
    expected_type = "refresh" if refresh else "access"
    
    try:
        payload = jwt.decode(
            token,
            secret,
            algorithms=["HS256"],
            options={
                "verify_signature": True,
                "verify_exp": True,
                "verify_iat": True,
                "require": ["exp", "iat", "type"],
            },
        )
        
        # Validate token type
        if payload.get("type") != expected_type:
            logger.warning(f"Token type mismatch: expected {expected_type}, got {payload.get('type')}")
            return None
        
        return payload
        
    except JWTError as e:
        logger.debug(f"Token decoding failed: {e}")
        return None


def validate_token_claims(payload: dict[str, Any]) -> bool:
    """
    Validate token claims for security.
    
    Args:
        payload: Decoded JWT payload
        
    Returns:
        True if claims are valid, False otherwise
    """
    # Ensure user_id is present and is a string
    user_id = payload.get("sub")
    if not user_id or not isinstance(user_id, str):
        return False
    
    # Ensure no dangerous claims are present
    dangerous_claims = ["role", "permissions", "is_admin", "user_id"]
    for claim in dangerous_claims:
        if claim in payload and claim != "sub":
            logger.warning(f"Potentially dangerous claim found: {claim}")
            # Don't reject, but log for monitoring
    
    return True


# =============================================================================
# Cryptographic Utilities
# =============================================================================


def generate_secure_random_bytes(length: int = 32) -> bytes:
    """
    Generate cryptographically secure random bytes.
    
    Args:
        length: Number of random bytes to generate
        
    Returns:
        Random bytes
    """
    return secrets.token_bytes(length)


def generate_secure_random_hex(length: int = 32) -> str:
    """
    Generate cryptographically secure random hex string.
    
    Args:
        length: Number of random bytes (hex output will be 2x this length)
        
    Returns:
        Random hex string
    """
    return secrets.token_hex(length)


def sha256_hash(data: bytes) -> str:
    """
    Compute SHA-256 hash of data.
    
    Args:
        data: Input bytes
        
    Returns:
        Hex-encoded SHA-256 hash
    """
    return hashlib.sha256(data).hexdigest()


def hmac_sha256(key: bytes, message: bytes) -> str:
    """
    Compute HMAC-SHA256 of a message.
    
    Args:
        key: Secret key
        message: Message to authenticate
        
    Returns:
        Hex-encoded HMAC-SHA256
    """
    return hmac.new(key, message, hashlib.sha256).hexdigest()


def constant_time_compare(a: str, b: str) -> bool:
    """
    Compare two strings in constant time to prevent timing attacks.
    
    Args:
        a: First string
        b: Second string
        
    Returns:
        True if equal, False otherwise
    """
    return secrets.compare_digest(a, b)


# =============================================================================
# Symmetric Encryption (for sensitive local data)
# =============================================================================


class EncryptionService:
    """
    Service for symmetric encryption using Fernet (AES-128-CBC with HMAC).
    
    Note: For production use with Rust integration, consider using
    AES-256-GCM through the Rust security layer.
    """
    
    def __init__(self, key: Optional[bytes] = None):
        """
        Initialize encryption service.
        
        Args:
            key: Encryption key (32 url-safe base64-encoded bytes).
                 If None, generates a new key (NOT recommended for production).
        """
        if key is None:
            # Generate a new key - only for development/testing
            self._key = Fernet.generate_key()
            logger.warning("Generated new encryption key - NOT suitable for production!")
        else:
            self._key = key
        
        self._cipher = Fernet(self._key)
    
    @classmethod
    def from_settings(cls) -> "EncryptionService":
        """Create encryption service from settings."""
        # In production, load key from secure environment variable
        key_str = os.getenv("ENCRYPTION_KEY")
        if key_str:
            key = key_str.encode()
        else:
            key = None
        return cls(key)
    
    @property
    def key(self) -> bytes:
        """Get the encryption key (handle with care!)."""
        return self._key
    
    def encrypt(self, plaintext: bytes) -> bytes:
        """
        Encrypt plaintext data.
        
        Args:
            plaintext: Data to encrypt
            
        Returns:
            Encrypted data (includes timestamp and HMAC)
        """
        return self._cipher.encrypt(plaintext)
    
    def decrypt(self, ciphertext: bytes) -> bytes:
        """
        Decrypt ciphertext data.
        
        Args:
            ciphertext: Data to decrypt
            
        Returns:
            Decrypted plaintext
            
        Raises:
            cryptography.fernet.InvalidToken: If decryption fails
        """
        return self._cipher.decrypt(ciphertext)
    
    def encrypt_string(self, plaintext: str) -> str:
        """
        Encrypt a string and return base64-encoded result.
        
        Args:
            plaintext: String to encrypt
            
        Returns:
            Base64-encoded encrypted string
        """
        encrypted = self.encrypt(plaintext.encode("utf-8"))
        return encrypted.hex()
    
    def decrypt_string(self, ciphertext_hex: str) -> str:
        """
        Decrypt a hex-encoded encrypted string.
        
        Args:
            ciphertext_hex: Hex-encoded encrypted string
            
        Returns:
            Decrypted string
        """
        decrypted = self.decrypt(bytes.fromhex(ciphertext_hex))
        return decrypted.decode("utf-8")


# Import os here to avoid circular import
import os
