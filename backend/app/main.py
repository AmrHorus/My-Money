"""My-Money Backend API - Main Application Entry Point."""

from contextlib import asynccontextmanager
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from slowapi import SlowAPI, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded

from app.core.config import settings
from app.core.logging import setup_logging, get_logger
from app.core.errors import (
    AppException,
    AuthenticationError,
    AuthorizationError,
    NotFoundError,
    ValidationError,
)
from app.db.mongodb import connect_to_mongodb, disconnect_from_mongodb, create_indexes
from app.api.v1 import auth, users, transactions, accounts, budgets, savings, recurring, statistics, sync

logger = get_logger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan manager for startup/shutdown events."""
    # Startup
    logger.info("Starting My-Money Backend API...")
    
    # Setup logging
    setup_logging(
        level=settings.log_level,
        json_format=settings.is_production
    )
    
    # Connect to MongoDB
    await connect_to_mongodb()
    
    # Create indexes
    from app.db.mongodb import get_database
    db = get_database()
    await create_indexes(db)
    
    logger.info("My-Money Backend API started successfully")
    
    yield
    
    # Shutdown
    logger.info("Shutting down My-Money Backend API...")
    await disconnect_from_mongodb()
    logger.info("My-Money Backend API shutdown complete")


# Create FastAPI application
app = FastAPI(
    title="My-Money | فلوسي API",
    description="Personal Finance Management System API",
    version="0.1.0",
    docs_url="/docs" if not settings.is_production else None,
    redoc_url="/redoc" if not settings.is_production else None,
    openapi_url="/openapi.json" if not settings.is_production else None,
    lifespan=lifespan,
)

# Setup rate limiter
rate_limiter = SlowAPI(
    key_func=get_remote_address,
    default_limits=[f"{settings.rate_limit_per_minute} per minute"],
)
app.state.limiter = rate_limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)


# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.parsed_cors_origins,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"],
    allow_headers=["*"],
    max_age=3600,
)


# Security headers middleware
@app.middleware("http")
async def add_security_headers(request: Request, call_next):
    """Add security headers to all responses."""
    response = await call_next(request)
    
    # Security headers
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["X-XSS-Protection"] = "1; mode=block"
    response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
    response.headers["Permissions-Policy"] = "geolocation=(), microphone=(), camera=()"
    
    if settings.is_production:
        response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
    
    return response


# Exception handlers
@app.exception_handler(AppException)
async def app_exception_handler(request: Request, exc: AppException):
    """Handle application exceptions."""
    from app.core.errors import APIErrorResponse, APIError
    return APIErrorResponse(
        error=APIError(
            code=exc.code,
            message=exc.message,
            details=exc.details,
        )
    )


@app.exception_handler(AuthenticationError)
async def auth_error_handler(request: Request, exc: AuthenticationError):
    """Handle authentication errors."""
    from app.core.errors import APIErrorResponse, APIError
    return APIErrorResponse(
        error=APIError(
            code=exc.code,
            message=exc.message,
        )
    )


@app.exception_handler(AuthorizationError)
async def authz_error_handler(request: Request, exc: AuthorizationError):
    """Handle authorization errors."""
    from app.core.errors import APIErrorResponse, APIError
    return APIErrorResponse(
        error=APIError(
            code=exc.code,
            message=exc.message,
        )
    )


@app.exception_handler(NotFoundError)
async def not_found_handler(request: Request, exc: NotFoundError):
    """Handle not found errors."""
    from app.core.errors import APIErrorResponse, APIError
    return APIErrorResponse(
        error=APIError(
            code=exc.code,
            message=exc.message,
        )
    )


@app.exception_handler(ValidationError)
async def validation_error_handler(request: Request, exc: ValidationError):
    """Handle validation errors."""
    from app.core.errors import APIErrorResponse, APIError
    return APIErrorResponse(
        error=APIError(
            code=exc.code,
            message=exc.message,
            details=exc.details,
        )
    )


# Include API routers
app.include_router(auth.router, prefix="/api/v1/auth", tags=["Authentication"])
app.include_router(users.router, prefix="/api/v1/users", tags=["Users"])
app.include_router(transactions.router, prefix="/api/v1/transactions", tags=["Transactions"])
app.include_router(accounts.router, prefix="/api/v1/accounts", tags=["Accounts"])
app.include_router(budgets.router, prefix="/api/v1/budgets", tags=["Budgets"])
app.include_router(savings.router, prefix="/api/v1/savings-goals", tags=["Savings Goals"])
app.include_router(recurring.router, prefix="/api/v1/recurring", tags=["Recurring Expenses"])
app.include_router(statistics.router, prefix="/api/v1/statistics", tags=["Statistics"])
app.include_router(sync.router, prefix="/api/v1/sync", tags=["Sync"])


# Health check endpoints
@app.get("/health", tags=["Health"])
async def health_check():
    """Basic health check endpoint."""
    return {"status": "healthy"}


@app.get("/health/ready", tags=["Health"])
async def readiness_check():
    """Readiness check that verifies dependencies."""
    from app.db.mongodb import verify_connection
    
    db_healthy = await verify_connection()
    
    if not db_healthy:
        return {"status": "unhealthy", "details": {"mongodb": "disconnected"}}
    
    return {
        "status": "ready",
        "details": {
            "mongodb": "connected",
        }
    }


# Root endpoint
@app.get("/", tags=["Root"])
async def root():
    """Root endpoint with API information."""
    return {
        "name": "My-Money | فلوسي API",
        "version": "0.1.0",
        "description": "Personal Finance Management System",
        "docs": "/docs" if not settings.is_production else "Disabled in production",
    }
