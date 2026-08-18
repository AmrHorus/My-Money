"""Recurring Expenses API endpoints."""

from fastapi import APIRouter

from app.api.deps import CurrentUserDep

router = APIRouter()


@router.get("")
async def list_recurring_expenses(current_user: CurrentUserDep):
    """List all recurring expenses for the current user."""
    # TODO: Implement recurring expenses listing
    return {"items": [], "total": 0}


@router.post("")
async def create_recurring_expense(current_user: CurrentUserDep):
    """Create a new recurring expense."""
    # TODO: Implement recurring expense creation
    pass


@router.get("/{expense_id}")
async def get_recurring_expense(current_user: CurrentUserDep, expense_id: str):
    """Get a specific recurring expense."""
    # TODO: Implement recurring expense retrieval
    pass


@router.put("/{expense_id}")
async def update_recurring_expense(current_user: CurrentUserDep, expense_id: str):
    """Update a recurring expense."""
    # TODO: Implement recurring expense update
    pass


@router.delete("/{expense_id}")
async def delete_recurring_expense(current_user: CurrentUserDep, expense_id: str):
    """Delete a recurring expense."""
    # TODO: Implement recurring expense deletion
    pass
