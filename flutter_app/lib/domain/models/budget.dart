/// Budget model for tracking spending limits
class Budget {
  /// Unique identifier
  final String id;

  /// User ID
  final String userId;

  /// Budget title
  final String title;

  /// Amount limit in minor units
  final int amountMinorUnits;

  /// Currency code
  final String currencyCode;

  /// Category ID (null for overall budget)
  final String? categoryId;

  /// Budget period: 'daily', 'weekly', 'monthly', 'yearly'
  final String period;

  /// Start date of the budget period
  final DateTime startDate;

  /// End date of the budget period
  final DateTime endDate;

  /// Whether the budget is active
  final bool isActive;

  /// Created timestamp
  final DateTime createdAt;

  /// Updated timestamp
  final DateTime updatedAt;

  const Budget({
    required this.id,
    required this.userId,
    required this.title,
    required this.amountMinorUnits,
    required this.currencyCode,
    this.categoryId,
    this.period = 'monthly',
    required this.startDate,
    required this.endDate,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Calculate spent amount from transactions
  int calculateSpent(List<int> transactionAmounts) {
    return transactionAmounts.fold(0, (sum, amount) => sum + amount);
  }

  /// Calculate remaining amount
  int calculateRemaining(int spentAmount) {
    return amountMinorUnits - spentAmount;
  }

  /// Calculate percentage used
  double calculatePercentageUsed(int spentAmount) {
    if (amountMinorUnits == 0) return 0.0;
    return (spentAmount / amountMinorUnits) * 100;
  }

  /// Check if over budget
  bool isOverBudget(int spentAmount) {
    return spentAmount > amountMinorUnits;
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'amountMinorUnits': amountMinorUnits,
      'currencyCode': currencyCode,
      'categoryId': categoryId,
      'period': period,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      amountMinorUnits: json['amountMinorUnits'] as int,
      currencyCode: json['currencyCode'] as String,
      categoryId: json['categoryId'] as String?,
      period: json['period'] as String? ?? 'monthly',
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

/// Savings goal model
class SavingsGoal {
  /// Unique identifier
  final String id;

  /// User ID
  final String userId;

  /// Goal name
  final String name;

  /// Target amount in minor units
  final int targetAmountMinorUnits;

  /// Current saved amount in minor units
  final int currentAmountMinorUnits;

  /// Currency code
  final String currencyCode;

  /// Deadline (optional)
  final DateTime? deadline;

  /// Description
  final String? description;

  /// Whether the goal is active
  final bool isActive;

  /// Created timestamp
  final DateTime createdAt;

  /// Updated timestamp
  final DateTime updatedAt;

  const SavingsGoal({
    required this.id,
    required this.userId,
    required this.name,
    required this.targetAmountMinorUnits,
    this.currentAmountMinorUnits = 0,
    required this.currencyCode,
    this.deadline,
    this.description,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Calculate progress percentage
  double get progressPercentage {
    if (targetAmountMinorUnits == 0) return 0.0;
    return ((currentAmountMinorUnits / targetAmountMinorUnits) * 100).clamp(0.0, 100.0);
  }

  /// Calculate remaining amount
  int get remainingAmount {
    return targetAmountMinorUnits - currentAmountMinorUnits;
  }

  /// Check if goal is achieved
  bool get isAchieved => currentAmountMinorUnits >= targetAmountMinorUnits;

  /// Add to savings
  SavingsGoal addSavings(int amountMinorUnits) {
    return copyWith(
      currentAmountMinorUnits: currentAmountMinorUnits + amountMinorUnits,
      updatedAt: DateTime.now(),
    );
  }

  /// Create a copy with updated fields
  SavingsGoal copyWith({
    String? id,
    String? userId,
    String? name,
    int? targetAmountMinorUnits,
    int? currentAmountMinorUnits,
    String? currencyCode,
    DateTime? deadline,
    String? description,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SavingsGoal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      targetAmountMinorUnits: targetAmountMinorUnits ?? this.targetAmountMinorUnits,
      currentAmountMinorUnits: currentAmountMinorUnits ?? this.currentAmountMinorUnits,
      currencyCode: currencyCode ?? this.currencyCode,
      deadline: deadline ?? this.deadline,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'targetAmountMinorUnits': targetAmountMinorUnits,
      'currentAmountMinorUnits': currentAmountMinorUnits,
      'currencyCode': currencyCode,
      'deadline': deadline?.toIso8601String(),
      'description': description,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory SavingsGoal.fromJson(Map<String, dynamic> json) {
    return SavingsGoal(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      targetAmountMinorUnits: json['targetAmountMinorUnits'] as int,
      currentAmountMinorUnits: json['currentAmountMinorUnits'] as int? ?? 0,
      currencyCode: json['currencyCode'] as String,
      deadline: json['deadline'] != null 
          ? DateTime.parse(json['deadline'] as String) 
          : null,
      description: json['description'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
