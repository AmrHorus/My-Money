"""Users API endpoints."""

from fastapi import APIRouter

from app.api.deps import CurrentUserDep
from app.schemas import UserResponse

router = APIRouter()


@router.get("/me", response_model=UserResponse)
async def get_user_profile(current_user: CurrentUserDep):
    """Get current user profile."""
    # Implementation delegated to auth.py /me endpoint
    # This is a placeholder for additional user management endpoints
    pass


@router.put("/me")
async def update_user_profile(current_user: CurrentUserDep):
    """Update current user profile."""
    # TODO: Implement user profile update
    pass
