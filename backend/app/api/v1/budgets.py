"""Budgets API endpoints."""

from fastapi import APIRouter

from app.api.deps import CurrentUserDep

router = APIRouter()


@router.get("")
async def list_budgets(current_user: CurrentUserDep):
    """List all budgets for the current user."""
    # TODO: Implement budget listing
    return {"items": [], "total": 0}


@router.post("")
async def create_budget(current_user: CurrentUserDep):
    """Create a new budget."""
    # TODO: Implement budget creation
    pass


@router.get("/{budget_id}")
async def get_budget(current_user: CurrentUserDep, budget_id: str):
    """Get a specific budget."""
    # TODO: Implement budget retrieval
    pass


@router.put("/{budget_id}")
async def update_budget(current_user: CurrentUserDep, budget_id: str):
    """Update a budget."""
    # TODO: Implement budget update
    pass


@router.delete("/{budget_id}")
async def delete_budget(current_user: CurrentUserDep, budget_id: str):
    """Delete a budget."""
    # TODO: Implement budget deletion
    pass
