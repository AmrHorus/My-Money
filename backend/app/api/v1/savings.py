"""Savings Goals API endpoints."""

from fastapi import APIRouter

from app.api.deps import CurrentUserDep

router = APIRouter()


@router.get("")
async def list_savings_goals(current_user: CurrentUserDep):
    """List all savings goals for the current user."""
    # TODO: Implement savings goals listing
    return {"items": [], "total": 0}


@router.post("")
async def create_savings_goal(current_user: CurrentUserDep):
    """Create a new savings goal."""
    # TODO: Implement savings goal creation
    pass


@router.get("/{goal_id}")
async def get_savings_goal(current_user: CurrentUserDep, goal_id: str):
    """Get a specific savings goal."""
    # TODO: Implement savings goal retrieval
    pass


@router.put("/{goal_id}")
async def update_savings_goal(current_user: CurrentUserDep, goal_id: str):
    """Update a savings goal."""
    # TODO: Implement savings goal update
    pass


@router.delete("/{goal_id}")
async def delete_savings_goal(current_user: CurrentUserDep, goal_id: str):
    """Delete a savings goal."""
    # TODO: Implement savings goal deletion
    pass
