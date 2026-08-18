/// Transaction type enum
enum TransactionType {
  income,
  expense,
  transfer,
}

/// Transaction status enum
enum TransactionStatus {
  pending,
  completed,
  cancelled,
  failed,
}

/// Transaction model representing a financial transaction
class Transaction {
  /// Unique identifier (UUID)
  final String id;
  
  /// User ID for ownership
  final String userId;
  
  /// Transaction type
  final TransactionType type;
  
  /// Amount in minor units
  final int amountMinorUnits;
  
  /// Currency code (ISO 4217)
  final String currencyCode;
  
  /// Category ID
  final String? categoryId;
  
  /// Account ID (for transfers)
  final String? accountId;
  
  /// Destination account ID (for transfers)
  final String? destinationAccountId;
  
  /// Transaction date
  final DateTime date;
  
  /// Description/note
  final String? note;
  
  /// Whether this is a recurring transaction
  final bool isRecurring;
  
  /// Reference to recurring rule ID
  final String? recurringRuleId;
  
  /// Sync status
  final TransactionStatus status;
  
  /// Created timestamp
  final DateTime createdAt;
  
  /// Updated timestamp
  final DateTime updatedAt;
  
  /// Deleted timestamp (soft delete)
  final DateTime? deletedAt;

  const Transaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.amountMinorUnits,
    required this.currencyCode,
    this.categoryId,
    this.accountId,
    this.destinationAccountId,
    required this.date,
    this.note,
    this.isRecurring = false,
    this.recurringRuleId,
    this.status = TransactionStatus.completed,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  /// Create a new transaction with updated fields
  Transaction copyWith({
    String? id,
    String? userId,
    TransactionType? type,
    int? amountMinorUnits,
    String? currencyCode,
    String? categoryId,
    String? accountId,
    String? destinationAccountId,
    DateTime? date,
    String? note,
    bool? isRecurring,
    String? recurringRuleId,
    TransactionStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      amountMinorUnits: amountMinorUnits ?? this.amountMinorUnits,
      currencyCode: currencyCode ?? this.currencyCode,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      destinationAccountId: destinationAccountId ?? this.destinationAccountId,
      date: date ?? this.date,
      note: note ?? this.note,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringRuleId: recurringRuleId ?? this.recurringRuleId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  /// Mark as deleted
  Transaction markDeleted() {
    return copyWith(deletedAt: DateTime.now());
  }

  /// Check if deleted
  bool get isDeleted => deletedAt != null;

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type.name,
      'amountMinorUnits': amountMinorUnits,
      'currencyCode': currencyCode,
      'categoryId': categoryId,
      'accountId': accountId,
      'destinationAccountId': destinationAccountId,
      'date': date.toIso8601String(),
      'note': note,
      'isRecurring': isRecurring,
      'recurringRuleId': recurringRuleId,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  /// Create from JSON
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: TransactionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TransactionType.expense,
      ),
      amountMinorUnits: json['amountMinorUnits'] as int,
      currencyCode: json['currencyCode'] as String,
      categoryId: json['categoryId'] as String?,
      accountId: json['accountId'] as String?,
      destinationAccountId: json['destinationAccountId'] as String?,
      date: DateTime.parse(json['date'] as String),
      note: json['note'] as String?,
      isRecurring: json['isRecurring'] as bool? ?? false,
      recurringRuleId: json['recurringRuleId'] as String?,
      status: TransactionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TransactionStatus.completed,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      deletedAt: json['deletedAt'] != null 
          ? DateTime.parse(json['deletedAt'] as String) 
          : null,
    );
  }
}
