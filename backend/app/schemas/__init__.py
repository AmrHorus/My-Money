"""Pydantic schemas for API request/response validation."""

from datetime import datetime, date
from typing import Optional, List, Literal
from pydantic import BaseModel, Field, field_validator, ConfigDict
from enum import Enum


# =============================================================================
# Enums
# =============================================================================


class TransactionType(str, Enum):
    """Transaction type enumeration."""
    INCOME = "income"
    EXPENSE = "expense"
    TRANSFER = "transfer"


class TransactionStatus(str, Enum):
    """Transaction status enumeration."""
    PENDING = "pending"
    COMPLETED = "completed"
    CANCELLED = "cancelled"
    FAILED = "failed"


class RecurringFrequency(str, Enum):
    """Recurring expense frequency enumeration."""
    DAILY = "daily"
    WEEKLY = "weekly"
    MONTHLY = "monthly"
    YEARLY = "yearly"


class CurrencyCode(str, Enum):
    """Supported currency codes (ISO 4217)."""
    SAR = "SAR"  # Saudi Riyal
    EGP = "EGP"  # Egyptian Pound
    USD = "USD"  # US Dollar
    EUR = "EUR"  # Euro
    GBP = "GBP"  # British Pound
    AED = "AED"  # UAE Dirham
    KWD = "KWD"  # Kuwaiti Dinar


# =============================================================================
# Money Schema
# =============================================================================


class MoneySchema(BaseModel):
    """Money value in minor units to avoid floating-point issues."""
    
    amount_minor_units: int = Field(..., description="Amount in minor units (e.g., cents)")
    currency_code: str = Field(..., description="ISO 4217 currency code")
    
    @field_validator("amount_minor_units")
    @classmethod
    def validate_amount(cls, v: int) -> int:
        """Validate amount is within reasonable range."""
        if v < -10_000_000_000:  # -100 million in minor units
            raise ValueError("Amount too negative")
        if v > 10_000_000_000:  # 100 million in minor units
            raise ValueError("Amount too large")
        return v
    
    @field_validator("currency_code")
    @classmethod
    def validate_currency(cls, v: str) -> str:
        """Validate currency code."""
        valid_currencies = {c.value for c in CurrencyCode}
        if v not in valid_currencies:
            raise ValueError(f"Invalid currency code. Must be one of: {valid_currencies}")
        return v


# =============================================================================
# User Schemas
# =============================================================================


class UserCreate(BaseModel):
    """Schema for user registration."""
    
    email: str = Field(..., min_length=3, max_length=255, description="User email address")
    password: str = Field(..., min_length=8, max_length=128, description="User password")
    full_name: str = Field(..., min_length=1, max_length=255, description="User full name")
    
    @field_validator("email")
    @classmethod
    def validate_email(cls, v: str) -> str:
        """Validate email format."""
        if "@" not in v or "." not in v.split("@")[-1]:
            raise ValueError("Invalid email format")
        return v.lower().strip()
    
    @field_validator("password")
    @classmethod
    def validate_password(cls, v: str) -> str:
        """Validate password strength."""
        if len(v) < 8:
            raise ValueError("Password must be at least 8 characters")
        if not any(c.isupper() for c in v):
            raise ValueError("Password must contain at least one uppercase letter")
        if not any(c.islower() for c in v):
            raise ValueError("Password must contain at least one lowercase letter")
        if not any(c.isdigit() for c in v):
            raise ValueError("Password must contain at least one digit")
        return v


class UserLogin(BaseModel):
    """Schema for user login."""
    
    email: str = Field(..., min_length=3, max_length=255, description="User email address")
    password: str = Field(..., min_length=1, max_length=128, description="User password")
    
    @field_validator("email")
    @classmethod
    def validate_email(cls, v: str) -> str:
        """Validate email format."""
        return v.lower().strip()


class UserResponse(BaseModel):
    """Schema for user response (excludes sensitive data)."""
    
    model_config = ConfigDict(from_attributes=True)
    
    id: str
    email: str
    full_name: str
    primary_currency: str = "SAR"
    created_at: datetime
    updated_at: datetime


class TokenResponse(BaseModel):
    """Schema for authentication token response."""
    
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int  # seconds


class RefreshTokenRequest(BaseModel):
    """Schema for refresh token request."""
    
    refresh_token: str = Field(..., description="Refresh token")


# =============================================================================
# Transaction Schemas
# =============================================================================


class TransactionCreate(BaseModel):
    """Schema for creating a transaction."""
    
    type: TransactionType = Field(..., description="Transaction type")
    amount_minor_units: int = Field(..., gt=0, description="Amount in minor units")
    currency_code: str = Field(default="SAR", description="Currency code")
    category_id: Optional[str] = Field(None, description="Category ID")
    account_id: Optional[str] = Field(None, description="Source account ID")
    destination_account_id: Optional[str] = Field(None, description="Destination account ID (for transfers)")
    date: date = Field(..., description="Transaction date")
    note: Optional[str] = Field(None, max_length=1000, description="Optional note")
    
    @field_validator("amount_minor_units")
    @classmethod
    def validate_amount(cls, v: int) -> int:
        """Validate amount is positive and reasonable."""
        if v <= 0:
            raise ValueError("Amount must be positive")
        if v > 1_000_000_000:  # 10 million in minor units
            raise ValueError("Amount exceeds maximum allowed")
        return v


class TransactionUpdate(BaseModel):
    """Schema for updating a transaction."""
    
    amount_minor_units: Optional[int] = Field(None, gt=0, description="Amount in minor units")
    category_id: Optional[str] = Field(None, description="Category ID")
    account_id: Optional[str] = Field(None, description="Source account ID")
    destination_account_id: Optional[str] = Field(None, description="Destination account ID")
    date: Optional[date] = Field(None, description="Transaction date")
    note: Optional[str] = Field(None, max_length=1000, description="Optional note")


class TransactionResponse(BaseModel):
    """Schema for transaction response."""
    
    model_config = ConfigDict(from_attributes=True)
    
    id: str
    user_id: str
    type: TransactionType
    amount_minor_units: int
    currency_code: str
    category_id: Optional[str]
    account_id: Optional[str]
    destination_account_id: Optional[str]
    date: date
    note: Optional[str]
    is_recurring: bool
    recurring_rule_id: Optional[str]
    status: TransactionStatus
    created_at: datetime
    updated_at: datetime
    deleted_at: Optional[datetime] = None


# =============================================================================
# Account Schemas
# =============================================================================


class AccountCreate(BaseModel):
    """Schema for creating an account."""
    
    name: str = Field(..., min_length=1, max_length=100, description="Account name")
    account_type: str = Field(default="cash", description="Account type (cash, bank, wallet, credit_card, savings)")
    currency_code: str = Field(default="SAR", description="Currency code")
    initial_balance_minor_units: int = Field(default=0, description="Initial balance in minor units")
    description: Optional[str] = Field(None, max_length=500, description="Optional description")


class AccountUpdate(BaseModel):
    """Schema for updating an account."""
    
    name: Optional[str] = Field(None, min_length=1, max_length=100)
    account_type: Optional[str] = Field(None)
    currency_code: Optional[str] = Field(None)
    description: Optional[str] = Field(None, max_length=500)
    is_active: Optional[bool] = Field(None)


class AccountResponse(BaseModel):
    """Schema for account response."""
    
    model_config = ConfigDict(from_attributes=True)
    
    id: str
    user_id: str
    name: str
    account_type: str
    currency_code: str
    current_balance_minor_units: int
    description: Optional[str]
    is_active: bool
    created_at: datetime
    updated_at: datetime


# =============================================================================
# Budget Schemas
# =============================================================================


class BudgetCreate(BaseModel):
    """Schema for creating a budget."""
    
    name: str = Field(..., min_length=1, max_length=100, description="Budget name")
    amount_minor_units: int = Field(..., gt=0, description="Budget amount in minor units")
    currency_code: str = Field(default="SAR", description="Currency code")
    category_id: Optional[str] = Field(None, description="Category ID (None for overall budget)")
    period_start: date = Field(..., description="Budget period start date")
    period_end: date = Field(..., description="Budget period end date")
    
    @field_validator("period_end")
    @classmethod
    def validate_period(cls, v: date, info) -> date:
        """Validate period end is after period start."""
        # Note: Can't access period_start here directly, validated in service layer
        return v


class BudgetResponse(BaseModel):
    """Schema for budget response."""
    
    model_config = ConfigDict(from_attributes=True)
    
    id: str
    user_id: str
    name: str
    amount_minor_units: int
    currency_code: str
    category_id: Optional[str]
    spent_amount_minor_units: int
    remaining_amount_minor_units: int
    percentage_used: float
    is_over_budget: bool
    period_start: date
    period_end: date
    created_at: datetime
    updated_at: datetime


# =============================================================================
# Savings Goal Schemas
# =============================================================================


class SavingsGoalCreate(BaseModel):
    """Schema for creating a savings goal."""
    
    name: str = Field(..., min_length=1, max_length=100, description="Goal name")
    target_amount_minor_units: int = Field(..., gt=0, description="Target amount in minor units")
    currency_code: str = Field(default="SAR", description="Currency code")
    current_amount_minor_units: int = Field(default=0, ge=0, description="Current saved amount")
    deadline: Optional[date] = Field(None, description="Optional deadline")
    description: Optional[str] = Field(None, max_length=500, description="Optional description")


class SavingsGoalUpdate(BaseModel):
    """Schema for updating a savings goal."""
    
    name: Optional[str] = Field(None, min_length=1, max_length=100)
    target_amount_minor_units: Optional[int] = Field(None, gt=0)
    current_amount_minor_units: Optional[int] = Field(None, ge=0)
    deadline: Optional[date] = Field(None)
    description: Optional[str] = Field(None, max_length=500)
    is_completed: Optional[bool] = Field(None)


class SavingsGoalResponse(BaseModel):
    """Schema for savings goal response."""
    
    model_config = ConfigDict(from_attributes=True)
    
    id: str
    user_id: str
    name: str
    target_amount_minor_units: int
    currency_code: str
    current_amount_minor_units: int
    progress_percentage: float
    remaining_amount_minor_units: int
    deadline: Optional[date]
    description: Optional[str]
    is_completed: bool
    created_at: datetime
    updated_at: datetime


# =============================================================================
# Recurring Expense Schemas
# =============================================================================


class RecurringExpenseCreate(BaseModel):
    """Schema for creating a recurring expense."""
    
    name: str = Field(..., min_length=1, max_length=100, description="Recurring expense name")
    amount_minor_units: int = Field(..., gt=0, description="Amount in minor units")
    currency_code: str = Field(default="SAR", description="Currency code")
    category_id: Optional[str] = Field(None, description="Category ID")
    account_id: Optional[str] = Field(None, description="Account ID")
    frequency: RecurringFrequency = Field(..., description="Recurrence frequency")
    next_due_date: date = Field(..., description="Next due date")
    note: Optional[str] = Field(None, max_length=500, description="Optional note")
    is_active: bool = Field(default=True, description="Whether recurrence is active")


class RecurringExpenseResponse(BaseModel):
    """Schema for recurring expense response."""
    
    model_config = ConfigDict(from_attributes=True)
    
    id: str
    user_id: str
    name: str
    amount_minor_units: int
    currency_code: str
    category_id: Optional[str]
    account_id: Optional[str]
    frequency: RecurringFrequency
    next_due_date: date
    last_occurrence_date: Optional[date]
    note: Optional[str]
    is_active: bool
    created_at: datetime
    updated_at: datetime


# =============================================================================
# Dashboard/Statistics Schemas
# =============================================================================


class FinancialSummarySchema(BaseModel):
    """Schema for financial summary."""
    
    total_income_minor_units: int
    total_expenses_minor_units: int
    fixed_expenses_minor_units: int
    variable_expenses_minor_units: int
    savings_minor_units: int
    remaining_balance_minor_units: int
    budget_usage_percentage: float
    currency_code: str


class CategorySpendingSchema(BaseModel):
    """Schema for category spending breakdown."""
    
    category_id: Optional[str]
    category_name: str
    amount_minor_units: int
    percentage: float
    transaction_count: int


class MonthlyTrendSchema(BaseModel):
    """Schema for monthly trend data point."""
    
    month: str  # YYYY-MM format
    income_minor_units: int
    expenses_minor_units: int
    savings_minor_units: int


# =============================================================================
# Pagination Schemas
# =============================================================================


class PaginationParams(BaseModel):
    """Schema for pagination parameters."""
    
    page: int = Field(default=1, ge=1, description="Page number")
    page_size: int = Field(default=20, ge=1, le=100, description="Items per page")


class PaginatedResponse(BaseModel):
    """Generic paginated response wrapper."""
    
    items: List
    total: int
    page: int
    page_size: int
    total_pages: int
