import '../models/transaction.dart';

/// Abstract repository interface for transactions
abstract class TransactionRepository {
  /// Get all transactions for a user
  Future<List<Transaction>> getAllTransactions({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    TransactionType? type,
    int limit = 100,
    int offset = 0,
  });

  /// Get transaction by ID
  Future<Transaction?> getTransactionById(String id);

  /// Create a new transaction
  Future<Transaction> createTransaction(Transaction transaction);

  /// Update an existing transaction
  Future<Transaction?> updateTransaction(Transaction transaction);

  /// Delete a transaction (soft delete)
  Future<bool> deleteTransaction(String id);

  /// Get transactions by category
  Future<List<Transaction>> getTransactionsByCategory({
    required String categoryId,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Get total income for a period
  Future<int> getTotalIncome({
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Get total expenses for a period
  Future<int> getTotalExpenses({
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Get transactions pending sync
  Future<List<Transaction>> getPendingSyncTransactions();

  /// Mark transaction as synced
  Future<void> markAsSynced(String id);

  /// Clear all local transactions
  Future<void> clearAll();
}
