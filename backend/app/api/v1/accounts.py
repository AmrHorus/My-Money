"""Accounts API endpoints."""

from fastapi import APIRouter

from app.api.deps import CurrentUserDep

router = APIRouter()


@router.get("")
async def list_accounts(current_user: CurrentUserDep):
    """List all accounts for the current user."""
    # TODO: Implement account listing
    return {"items": [], "total": 0}


@router.post("")
async def create_account(current_user: CurrentUserDep):
    """Create a new account."""
    # TODO: Implement account creation
    pass


@router.get("/{account_id}")
async def get_account(current_user: CurrentUserDep, account_id: str):
    """Get a specific account."""
    # TODO: Implement account retrieval
    pass


@router.put("/{account_id}")
async def update_account(current_user: CurrentUserDep, account_id: str):
    """Update an account."""
    # TODO: Implement account update
    pass


@router.delete("/{account_id}")
async def delete_account(current_user: CurrentUserDep, account_id: str):
    """Delete an account."""
    # TODO: Implement account deletion
    pass
