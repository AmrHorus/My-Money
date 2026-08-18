"""Statistics and Dashboard API endpoints."""

from fastapi import APIRouter

from app.api.deps import CurrentUserDep

router = APIRouter()


@router.get("/summary")
async def get_financial_summary(current_user: CurrentUserDep):
    """Get financial summary for dashboard."""
    # TODO: Implement financial summary calculation
    return {
        "total_income_minor_units": 0,
        "total_expenses_minor_units": 0,
        "fixed_expenses_minor_units": 0,
        "variable_expenses_minor_units": 0,
        "savings_minor_units": 0,
        "remaining_balance_minor_units": 0,
        "budget_usage_percentage": 0.0,
        "currency_code": "SAR",
    }


@router.get("/monthly-trend")
async def get_monthly_trend(current_user: CurrentUserDep):
    """Get monthly income/expense trends."""
    # TODO: Implement monthly trend calculation
    return {"trends": []}


@router.get("/category-breakdown")
async def get_category_breakdown(current_user: CurrentUserDep):
    """Get spending breakdown by category."""
    # TODO: Implement category breakdown calculation
    return {"categories": []}
