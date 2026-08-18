"""Transactions API endpoints."""

from datetime import UTC, date, datetime

from fastapi import APIRouter, Query

from app.api.deps import CurrentUserDep
from app.core.errors import TransactionNotFoundError
from app.core.logging import get_logger
from app.db.mongodb import get_database
from app.schemas import (
    TransactionCreate,
    TransactionResponse,
    TransactionUpdate,
)

logger = get_logger(__name__)

router = APIRouter()


@router.get("", response_model=list[TransactionResponse])
async def list_transactions(
    current_user: CurrentUserDep,
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
    start_date: date | None = None,
    end_date: date | None = None,
    transaction_type: str | None = None,
    category_id: str | None = None,
):
    """
    List transactions for the current user.
    
    Results are paginated and filtered by ownership.
    """
    db = get_database()

    # Build query with mandatory user ownership
    query = {"user_id": current_user.id, "deleted_at": None}

    if start_date:
        query["date"] = {"$gte": start_date.isoformat()}
    if end_date:
        query.setdefault("date", {})["$lte"] = end_date.isoformat()
    if transaction_type:
        query["type"] = transaction_type
    if category_id:
        query["category_id"] = category_id

    # Calculate skip for pagination
    skip = (page - 1) * page_size

    # Execute query
    cursor = db.transactions.find(query).sort("date", -1).skip(skip).limit(page_size)
    transactions = await cursor.to_list(length=page_size)

    # Get total count
    total = await db.transactions.count_documents(query)

    logger.info(f"User {current_user.id} listed {len(transactions)} transactions")

    return [
        TransactionResponse(
            id=str(tx["_id"]),
            user_id=tx["user_id"],
            type=tx["type"],
            amount_minor_units=tx["amount_minor_units"],
            currency_code=tx["currency_code"],
            category_id=tx.get("category_id"),
            account_id=tx.get("account_id"),
            destination_account_id=tx.get("destination_account_id"),
            date=tx["date"],
            note=tx.get("note"),
            is_recurring=tx.get("is_recurring", False),
            recurring_rule_id=tx.get("recurring_rule_id"),
            status=tx.get("status", "completed"),
            created_at=tx["created_at"],
            updated_at=tx["updated_at"],
            deleted_at=tx.get("deleted_at"),
        )
        for tx in transactions
    ]


@router.post("", response_model=TransactionResponse, status_code=201)
async def create_transaction(
    current_user: CurrentUserDep,
    transaction_data: TransactionCreate,
):
    """
    Create a new transaction.
    
    The transaction is automatically associated with the authenticated user.
    Transfers must have both source and destination account IDs.
    """
    db = get_database()

    # Validate transfer requirements
    if transaction_data.type == "transfer":
        if not transaction_data.account_id or not transaction_data.destination_account_id:
            from app.core.errors import ValidationError
            raise ValidationError(
                message="Transfers require both source and destination accounts",
                code="TRANSFER_MISSING_ACCOUNTS"
            )

    # Create transaction document
    now = datetime.now(UTC)
    transaction_document = {
        "user_id": current_user.id,
        "type": transaction_data.type.value,
        "amount_minor_units": transaction_data.amount_minor_units,
        "currency_code": transaction_data.currency_code,
        "category_id": transaction_data.category_id,
        "account_id": transaction_data.account_id,
        "destination_account_id": transaction_data.destination_account_id,
        "date": transaction_data.date.isoformat(),
        "note": transaction_data.note,
        "is_recurring": False,
        "recurring_rule_id": None,
        "status": "completed",
        "created_at": now,
        "updated_at": now,
        "deleted_at": None,
    }

    result = await db.transactions.insert_one(transaction_document)
    transaction_document["_id"] = result.inserted_id

    logger.info(f"User {current_user.id} created transaction: {transaction_document['_id']}")

    return TransactionResponse(
        id=str(transaction_document["_id"]),
        user_id=transaction_document["user_id"],
        type=transaction_document["type"],
        amount_minor_units=transaction_document["amount_minor_units"],
        currency_code=transaction_document["currency_code"],
        category_id=transaction_document["category_id"],
        account_id=transaction_document["account_id"],
        destination_account_id=transaction_document["destination_account_id"],
        date=transaction_document["date"],
        note=transaction_document["note"],
        is_recurring=transaction_document["is_recurring"],
        recurring_rule_id=transaction_document["recurring_rule_id"],
        status=transaction_document["status"],
        created_at=transaction_document["created_at"],
        updated_at=transaction_document["updated_at"],
        deleted_at=transaction_document["deleted_at"],
    )


@router.get("/{transaction_id}", response_model=TransactionResponse)
async def get_transaction(
    current_user: CurrentUserDep,
    transaction_id: str,
):
    """Get a specific transaction by ID."""
    db = get_database()

    # Query with mandatory user ownership check
    transaction = await db.transactions.find_one({
        "_id": transaction_id,
        "user_id": current_user.id,
        "deleted_at": None,
    })

    if not transaction:
        raise TransactionNotFoundError(transaction_id)

    return TransactionResponse(
        id=str(transaction["_id"]),
        user_id=transaction["user_id"],
        type=transaction["type"],
        amount_minor_units=transaction["amount_minor_units"],
        currency_code=transaction["currency_code"],
        category_id=transaction.get("category_id"),
        account_id=transaction.get("account_id"),
        destination_account_id=transaction.get("destination_account_id"),
        date=transaction["date"],
        note=transaction.get("note"),
        is_recurring=transaction.get("is_recurring", False),
        recurring_rule_id=transaction.get("recurring_rule_id"),
        status=transaction.get("status", "completed"),
        created_at=transaction["created_at"],
        updated_at=transaction["updated_at"],
        deleted_at=transaction.get("deleted_at"),
    )


@router.put("/{transaction_id}", response_model=TransactionResponse)
async def update_transaction(
    current_user: CurrentUserDep,
    transaction_id: str,
    transaction_data: TransactionUpdate,
):
    """Update an existing transaction."""
    db = get_database()

    # Build update document (only non-None fields)
    update_fields = {}
    if transaction_data.amount_minor_units is not None:
        update_fields["amount_minor_units"] = transaction_data.amount_minor_units
    if transaction_data.category_id is not None:
        update_fields["category_id"] = transaction_data.category_id
    if transaction_data.account_id is not None:
        update_fields["account_id"] = transaction_data.account_id
    if transaction_data.destination_account_id is not None:
        update_fields["destination_account_id"] = transaction_data.destination_account_id
    if transaction_data.date is not None:
        update_fields["date"] = transaction_data.date.isoformat()
    if transaction_data.note is not None:
        update_fields["note"] = transaction_data.note

    update_fields["updated_at"] = datetime.now(UTC)

    # Update with ownership check
    result = await db.transactions.update_one(
        {"_id": transaction_id, "user_id": current_user.id, "deleted_at": None},
        {"$set": update_fields}
    )

    if result.matched_count == 0:
        raise TransactionNotFoundError(transaction_id)

    # Fetch updated transaction
    transaction = await db.transactions.find_one({"_id": transaction_id})

    logger.info(f"User {current_user.id} updated transaction: {transaction_id}")

    return TransactionResponse(
        id=str(transaction["_id"]),
        user_id=transaction["user_id"],
        type=transaction["type"],
        amount_minor_units=transaction["amount_minor_units"],
        currency_code=transaction["currency_code"],
        category_id=transaction.get("category_id"),
        account_id=transaction.get("account_id"),
        destination_account_id=transaction.get("destination_account_id"),
        date=transaction["date"],
        note=transaction.get("note"),
        is_recurring=transaction.get("is_recurring", False),
        recurring_rule_id=transaction.get("recurring_rule_id"),
        status=transaction.get("status", "completed"),
        created_at=transaction["created_at"],
        updated_at=transaction["updated_at"],
        deleted_at=transaction.get("deleted_at"),
    )


@router.delete("/{transaction_id}")
async def delete_transaction(
    current_user: CurrentUserDep,
    transaction_id: str,
):
    """
    Soft-delete a transaction.
    
    The transaction is marked as deleted but retained in the database
    for audit purposes.
    """
    db = get_database()

    # Soft delete with ownership check
    result = await db.transactions.update_one(
        {"_id": transaction_id, "user_id": current_user.id, "deleted_at": None},
        {"$set": {"deleted_at": datetime.now(UTC)}}
    )

    if result.matched_count == 0:
        raise TransactionNotFoundError(transaction_id)

    logger.info(f"User {current_user.id} deleted transaction: {transaction_id}")

    return {"success": True, "message": "Transaction deleted successfully"}
