"""MongoDB index creation for optimal query performance."""

from motor.motor_asyncio import AsyncIOMotorDatabase

from app.core.logging import get_logger

logger = get_logger(__name__)


async def create_indexes(db: AsyncIOMotorDatabase) -> None:
    """
    Create all necessary indexes for the application collections.
    
    Indexes are created based on common query patterns to optimize performance.
    """
    logger.info("Creating MongoDB indexes...")

    # Users collection indexes
    await db.users.create_index([("email", 1)], unique=True, name="idx_users_email_unique")
    await db.users.create_index([("created_at", -1)], name="idx_users_created_at")

    # Transactions collection indexes
    await db.transactions.create_index(
        [("user_id", 1), ("date", -1)],
        name="idx_transactions_user_date"
    )
    await db.transactions.create_index(
        [("user_id", 1), ("type", 1), ("date", -1)],
        name="idx_transactions_user_type_date"
    )
    await db.transactions.create_index(
        [("user_id", 1), ("category_id", 1), ("date", -1)],
        name="idx_transactions_user_category_date"
    )
    await db.transactions.create_index(
        [("user_id", 1), ("account_id", 1), ("date", -1)],
        name="idx_transactions_user_account_date"
    )
    await db.transactions.create_index([("updated_at", -1)], name="idx_transactions_updated_at")
    await db.transactions.create_index([("deleted_at", 1)], name="idx_transactions_deleted_at")

    # Accounts collection indexes
    await db.accounts.create_index(
        [("user_id", 1), ("name", 1)],
        unique=True,
        name="idx_accounts_user_name_unique"
    )
    await db.accounts.create_index([("updated_at", -1)], name="idx_accounts_updated_at")

    # Budgets collection indexes
    await db.budgets.create_index(
        [("user_id", 1), ("period_start", -1)],
        name="idx_budgets_user_period"
    )
    await db.budgets.create_index(
        [("user_id", 1), ("category_id", 1)],
        name="idx_budgets_user_category"
    )
    await db.budgets.create_index([("updated_at", -1)], name="idx_budgets_updated_at")

    # Savings goals collection indexes
    await db.savings_goals.create_index(
        [("user_id", 1), ("created_at", -1)],
        name="idx_savings_goals_user_created"
    )
    await db.savings_goals.create_index([("updated_at", -1)], name="idx_savings_goals_updated_at")

    # Recurring expenses collection indexes
    await db.recurring_expenses.create_index(
        [("user_id", 1), ("next_due_date", 1)],
        name="idx_recurring_user_next_due"
    )
    await db.recurring_expenses.create_index(
        [("user_id", 1), ("frequency", 1)],
        name="idx_recurring_user_frequency"
    )
    await db.recurring_expenses.create_index([("updated_at", -1)], name="idx_recurring_updated_at")

    # Sessions collection indexes
    await db.sessions.create_index([("user_id", 1)], name="idx_sessions_user_id")
    await db.sessions.create_index(
        [("token_hash", 1)],
        unique=True,
        name="idx_sessions_token_hash_unique"
    )
    await db.sessions.create_index([("expires_at", 1)], name="idx_sessions_expires_at")
    await db.sessions.create_index([("revoked_at", 1)], name="idx_sessions_revoked_at")

    # Audit logs collection indexes
    await db.audit_logs.create_index(
        [("user_id", 1), ("timestamp", -1)],
        name="idx_audit_logs_user_timestamp"
    )
    await db.audit_logs.create_index(
        [("event_type", 1), ("timestamp", -1)],
        name="idx_audit_logs_event_timestamp"
    )
    # TTL index for audit logs (auto-delete after 1 year)
    await db.audit_logs.create_index(
        [("timestamp", 1)],
        expireAfterSeconds=31536000,  # 1 year in seconds
        name="idx_audit_logs_ttl"
    )

    # Sync events collection indexes
    await db.sync_events.create_index(
        [("user_id", 1), ("timestamp", -1)],
        name="idx_sync_events_user_timestamp"
    )
    await db.sync_events.create_index([("status", 1)], name="idx_sync_events_status")

    # Idempotency keys collection indexes
    await db.idempotency_keys.create_index(
        [("user_id", 1), ("idempotency_key", 1)],
        unique=True,
        name="idx_idempotency_user_key_unique"
    )
    await db.idempotency_keys.create_index(
        [("expires_at", 1)],
        expireAfterSeconds=0,
        name="idx_idempotency_ttl"
    )
    await db.idempotency_keys.create_index([("status", 1)], name="idx_idempotency_status")

    logger.info("MongoDB indexes created successfully")


async def verify_indexes(db: AsyncIOMotorDatabase) -> bool:
    """
    Verify that critical indexes exist.
    
    Returns:
        True if all critical indexes exist, False otherwise
    """
    try:
        # Check users email index
        user_indexes = await db.users.index_information()
        if "idx_users_email_unique" not in user_indexes:
            logger.warning("Missing critical index: idx_users_email_unique")
            return False

        # Check transactions user_id index
        tx_indexes = await db.transactions.index_information()
        if "idx_transactions_user_date" not in tx_indexes:
            logger.warning("Missing critical index: idx_transactions_user_date")
            return False

        return True

    except Exception as e:
        logger.error(f"Error verifying indexes: {e}")
        return False
