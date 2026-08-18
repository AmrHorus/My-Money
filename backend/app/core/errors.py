"""Custom error handling and API error responses."""

from typing import Any

from fastapi import HTTPException, status
from pydantic import BaseModel


class APIError(BaseModel):
    """Standardized API error response model."""

    code: str
    message: str
    details: dict[str, Any] | None = None


class APIErrorResponse(BaseModel):
    """Standardized API error response envelope."""

    success: bool = False
    error: APIError


# =============================================================================
# Custom Exception Classes
# =============================================================================


class AppException(Exception):
    """Base application exception."""

    def __init__(
        self,
        message: str,
        code: str = "INTERNAL_ERROR",
        status_code: int = status.HTTP_500_INTERNAL_SERVER_ERROR,
        details: dict[str, Any] | None = None,
    ):
        self.message = message
        self.code = code
        self.status_code = status_code
        self.details = details
        super().__init__(self.message)

    def to_error_response(self) -> APIErrorResponse:
        """Convert exception to standardized error response."""
        return APIErrorResponse(
            error=APIError(
                code=self.code,
                message=self.message,
                details=self.details,
            )
        )


class AuthenticationError(AppException):
    """Authentication-related errors."""

    def __init__(
        self,
        message: str = "Authentication failed",
        code: str = "AUTHENTICATION_FAILED",
    ):
        super().__init__(
            message=message,
            code=code,
            status_code=status.HTTP_401_UNAUTHORIZED,
        )


class AuthorizationError(AppException):
    """Authorization-related errors (user lacks permission)."""

    def __init__(
        self,
        message: str = "You do not have permission to access this resource",
        code: str = "FORBIDDEN",
    ):
        super().__init__(
            message=message,
            code=code,
            status_code=status.HTTP_403_FORBIDDEN,
        )


class NotFoundError(AppException):
    """Resource not found errors."""

    def __init__(
        self,
        message: str = "Resource not found",
        code: str = "NOT_FOUND",
    ):
        super().__init__(
            message=message,
            code=code,
            status_code=status.HTTP_404_NOT_FOUND,
        )


class ValidationError(AppException):
    """Input validation errors."""

    def __init__(
        self,
        message: str = "Validation failed",
        code: str = "VALIDATION_ERROR",
        details: dict[str, Any] | None = None,
    ):
        super().__init__(
            message=message,
            code=code,
            status_code=status.HTTP_400_BAD_REQUEST,
            details=details,
        )


class ConflictError(AppException):
    """Resource conflict errors (e.g., duplicate)."""

    def __init__(
        self,
        message: str = "Resource conflict",
        code: str = "CONFLICT",
    ):
        super().__init__(
            message=message,
            code=code,
            status_code=status.HTTP_409_CONFLICT,
        )


class RateLimitError(AppException):
    """Rate limit exceeded errors."""

    def __init__(
        self,
        message: str = "Rate limit exceeded. Please try again later.",
        code: str = "RATE_LIMIT_EXCEEDED",
    ):
        super().__init__(
            message=message,
            code=code,
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
        )


class FinancialError(AppException):
    """Financial operation errors."""

    def __init__(
        self,
        message: str,
        code: str = "FINANCIAL_ERROR",
    ):
        super().__init__(
            message=message,
            code=code,
            status_code=status.HTTP_400_BAD_REQUEST,
        )


class DatabaseError(AppException):
    """Database operation errors."""

    def __init__(
        self,
        message: str = "Database operation failed",
        code: str = "DATABASE_ERROR",
    ):
        super().__init__(
            message=message,
            code=code,
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        )


# =============================================================================
# Specific Error Exceptions
# =============================================================================


class UserNotFoundError(NotFoundError):
    """User not found."""

    def __init__(self, user_id: str):
        super().__init__(
            message=f"User not found: {user_id}",
            code="USER_NOT_FOUND",
        )


class UserAlreadyExistsError(ConflictError):
    """User already exists."""

    def __init__(self, email: str):
        super().__init__(
            message=f"User with email '{email}' already exists",
            code="USER_ALREADY_EXISTS",
        )


class TransactionNotFoundError(NotFoundError):
    """Transaction not found."""

    def __init__(self, transaction_id: str):
        super().__init__(
            message=f"Transaction not found: {transaction_id}",
            code="TRANSACTION_NOT_FOUND",
        )


class InsufficientFundsError(FinancialError):
    """Insufficient funds for operation."""

    def __init__(self, required: int, available: int, currency: str):
        super().__init__(
            message=f"Insufficient funds. Required: {required}, Available: {available} {currency}",
            code="INSUFFICIENT_FUNDS",
        )


class InvalidAmountError(FinancialError):
    """Invalid amount for financial operation."""

    def __init__(self, message: str = "Invalid amount"):
        super().__init__(
            message=message,
            code="INVALID_AMOUNT",
        )


class InvalidCurrencyError(FinancialError):
    """Invalid or unsupported currency."""

    def __init__(self, currency: str):
        super().__init__(
            message=f"Invalid or unsupported currency: {currency}",
            code="INVALID_CURRENCY",
        )


class SessionExpiredError(AuthenticationError):
    """Session has expired."""

    def __init__(self):
        super().__init__(
            message="Session expired. Please log in again.",
            code="SESSION_EXPIRED",
        )


class InvalidTokenError(AuthenticationError):
    """Token is invalid."""

    def __init__(self):
        super().__init__(
            message="Invalid or malformed token",
            code="INVALID_TOKEN",
        )


class TokenRevokedError(AuthenticationError):
    """Token has been revoked."""

    def __init__(self):
        super().__init__(
            message="Token has been revoked. Please log in again.",
            code="TOKEN_REVOKED",
        )


# =============================================================================
# Exception Handlers for FastAPI
# =============================================================================


async def app_exception_handler(request, exc: AppException):
    """Handle application exceptions."""
    return exc.to_error_response()


async def http_exception_handler(request, exc: HTTPException):
    """Handle FastAPI HTTP exceptions."""
    return APIErrorResponse(
        error=APIError(
            code=f"HTTP_{exc.status_code}",
            message=exc.detail,
        )
    )


async def generic_exception_handler(request, exc: Exception):
    """Handle unexpected exceptions securely."""
    # Log the full exception internally
    from app.core.logging import get_logger
    logger = get_logger(__name__)
    logger.exception(f"Unexpected error: {exc}")

    # Return safe error to client
    return APIErrorResponse(
        error=APIError(
            code="INTERNAL_ERROR",
            message="An unexpected error occurred. Please try again later.",
        )
    )
