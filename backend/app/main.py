"""My-Money Backend API - Main Application Entry Point."""

from contextlib import asynccontextmanager

from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from slowapi.util import get_remote_address

from app.api.v1 import (
    accounts,
    auth,
    budgets,
    recurring,
    savings,
    statistics,
    sync,
    transactions,
    users,
)
from app.core.config import settings
from app.core.errors import (
    APIError,
    APIErrorResponse,
    AppException,
    AuthenticationError,
    AuthorizationError,
    NotFoundError,
    ValidationError,
)
from app.core.logging import get_logger, setup_logging
from app.db.mongodb import (
    connect_to_mongodb,
    create_indexes,
    disconnect_from_mongodb,
    get_database,
    verify_connection,
)

logger = get_logger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan manager for startup/shutdown events."""
    setup_logging(level=settings.log_level, json_format=settings.is_production)
    logger.info("Starting My-Money Backend API...")

    try:
        await connect_to_mongodb()
        db = get_database()
        await create_indexes(db)
    except Exception:
        logger.exception("Startup failed while initializing MongoDB")
        raise

    logger.info("My-Money Backend API started successfully")

    yield

    logger.info("Shutting down My-Money Backend API...")
    await disconnect_from_mongodb()
    logger.info("My-Money Backend API shutdown complete")


app = FastAPI(
    title="My-Money | فلوسي API",
    description="Personal Finance Management System API",
    version="0.1.0",
    docs_url="/docs" if not settings.is_production else None,
    redoc_url="/redoc" if not settings.is_production else None,
    openapi_url="/openapi.json" if not settings.is_production else None,
    lifespan=lifespan,
)

# --- Rate limiting ---
# NOTE: slowapi's rate limiter class is `Limiter`, not `SlowAPI`.
# Using the wrong class here would fail at import/runtime.
limiter = Limiter(
    key_func=get_remote_address,
    default_limits=[f"{settings.rate_limit_per_minute} per minute"],
)
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# --- CORS ---
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.parsed_cors_origins,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"],
    allow_headers=["*"],
    max_age=3600,
)


@app.middleware("http")
async def add_security_headers(request: Request, call_next):
    """Add security headers to all responses."""
    response = await call_next(request)
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["X-XSS-Protection"] = "1; mode=block"
    response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
    response.headers["Permissions-Policy"] = "geolocation=(), microphone=(), camera=()"
    if settings.is_production:
        response.headers["Strict-Transport-Security"] = (
            "max-age=31536000; includeSubDomains"
        )
    return response


# --- Exception handlers ---
# Consolidated into one handler per status code to avoid repeating the
# `from app.core.errors import ...` import inside every function and to
# keep status codes explicit (the original never set an HTTP status,
# so every error was returned as 200 OK).

def _error_response(exc: AppException, http_status: int) -> JSONResponse:
    payload = APIErrorResponse(
        error=APIError(
            code=exc.code,
            message=exc.message,
            details=getattr(exc, "details", None),
        )
    )
    return JSONResponse(status_code=http_status, content=payload.model_dump())


@app.exception_handler(AuthenticationError)
async def auth_error_handler(request: Request, exc: AuthenticationError):
    return _error_response(exc, status.HTTP_401_UNAUTHORIZED)


@app.exception_handler(AuthorizationError)
async def authz_error_handler(request: Request, exc: AuthorizationError):
    return _error_response(exc, status.HTTP_403_FORBIDDEN)


@app.exception_handler(NotFoundError)
async def not_found_handler(request: Request, exc: NotFoundError):
    return _error_response(exc, status.HTTP_404_NOT_FOUND)


@app.exception_handler(ValidationError)
async def validation_error_handler(request: Request, exc: ValidationError):
    return _error_response(exc, status.HTTP_422_UNPROCESSABLE_ENTITY)


# Generic AppException handler last, since the more specific subclasses
# above are matched first by FastAPI's exception handler resolution.
@app.exception_handler(AppException)
async def app_exception_handler(request: Request, exc: AppException):
    return _error_response(exc, status.HTTP_400_BAD_REQUEST)


# --- Routers ---
app.include_router(auth.router, prefix="/api/v1/auth", tags=["Authentication"])
app.include_router(users.router, prefix="/api/v1/users", tags=["Users"])
app.include_router(transactions.router, prefix="/api/v1/transactions", tags=["Transactions"])
app.include_router(accounts.router, prefix="/api/v1/accounts", tags=["Accounts"])
app.include_router(budgets.router, prefix="/api/v1/budgets", tags=["Budgets"])
app.include_router(savings.router, prefix="/api/v1/savings-goals", tags=["Savings Goals"])
app.include_router(recurring.router, prefix="/api/v1/recurring", tags=["Recurring Expenses"])
app.include_router(statistics.router, prefix="/api/v1/statistics", tags=["Statistics"])
app.include_router(sync.router, prefix="/api/v1/sync", tags=["Sync"])


# --- Health checks ---
@app.get("/health", tags=["Health"])
async def health_check():
    """Basic health check endpoint (liveness)."""
    return {"status": "healthy"}


@app.get("/health/ready", tags=["Health"])
async def readiness_check(response: Response):
    """Readiness check that verifies dependencies."""
    db_healthy = await verify_connection()

    if not db_healthy:
        response.status_code = status.HTTP_503_SERVICE_UNAVAILABLE
        return {"status": "unhealthy", "details": {"mongodb": "disconnected"}}

    return {"status": "ready", "details": {"mongodb": "connected"}}


@app.get("/", tags=["Root"])
async def root():
    """Root endpoint with API information."""
    return {
        "name": "My-Money | فلوسي API",
        "version": "0.1.0",
        "description": "Personal Finance Management System",
        "docs": "/docs" if not settings.is_production else "Disabled in production",
    }
