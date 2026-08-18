"""Sync API endpoints for offline-first synchronization."""

from fastapi import APIRouter

from app.api.deps import CurrentUserDep

router = APIRouter()


@router.post("/push")
async def sync_push(current_user: CurrentUserDep):
    """Push local changes to the server."""
    # TODO: Implement sync push logic
    return {"success": True, "synced_count": 0}


@router.get("/pull")
async def sync_pull(current_user: CurrentUserDep):
    """Pull remote changes from the server."""
    # TODO: Implement sync pull logic
    return {"success": True, "changes": []}


@router.post("/full")
async def full_sync(current_user: CurrentUserDep):
    """Perform a full synchronization."""
    # TODO: Implement full sync logic
    return {"success": True, "pushed": 0, "pulled": 0}
