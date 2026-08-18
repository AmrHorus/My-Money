import 'package:flutter/foundation.dart';

/// Financial summary model for dashboard calculations
class FinancialSummary {
  /// Total income in minor units
  final int totalIncomeMinorUnits;

  /// Total expenses in minor units
  final int totalExpensesMinorUnits;

  /// Fixed expenses in minor units
  final int fixedExpensesMinorUnits;

  /// Variable expenses in minor units
  final int variableExpensesMinorUnits;

  /// Total savings in minor units
  final int totalSavingsMinorUnits;

  /// Remaining balance in minor units
  final int remainingBalanceMinorUnits;

  /// Currency code
  final String currencyCode;

  /// Budget usage percentage (0-100)
  final double budgetUsagePercentage;

  /// Number of upcoming payments
  final int upcomingPaymentsCount;

  const FinancialSummary({
    required this.totalIncomeMinorUnits,
    required this.totalExpensesMinorUnits,
    required this.fixedExpensesMinorUnits,
    required this.variableExpensesMinorUnits,
    required this.totalSavingsMinorUnits,
    required this.remainingBalanceMinorUnits,
    required this.currencyCode,
    this.budgetUsagePercentage = 0.0,
    this.upcomingPaymentsCount = 0,
  });

  /// Create a copy with updated fields
  FinancialSummary copyWith({
    int? totalIncomeMinorUnits,
    int? totalExpensesMinorUnits,
    int? fixedExpensesMinorUnits,
    int? variableExpensesMinorUnits,
    int? totalSavingsMinorUnits,
    int? remainingBalanceMinorUnits,
    String? currencyCode,
    double? budgetUsagePercentage,
    int? upcomingPaymentsCount,
  }) {
    return FinancialSummary(
      totalIncomeMinorUnits: totalIncomeMinorUnits ?? this.totalIncomeMinorUnits,
      totalExpensesMinorUnits: totalExpensesMinorUnits ?? this.totalExpensesMinorUnits,
      fixedExpensesMinorUnits: fixedExpensesMinorUnits ?? this.fixedExpensesMinorUnits,
      variableExpensesMinorUnits: variableExpensesMinorUnits ?? this.variableExpensesMinorUnits,
      totalSavingsMinorUnits: totalSavingsMinorUnits ?? this.totalSavingsMinorUnits,
      remainingBalanceMinorUnits: remainingBalanceMinorUnits ?? this.remainingBalanceMinorUnits,
      currencyCode: currencyCode ?? this.currencyCode,
      budgetUsagePercentage: budgetUsagePercentage ?? this.budgetUsagePercentage,
      upcomingPaymentsCount: upcomingPaymentsCount ?? this.upcomingPaymentsCount,
    );
  }

  /// Check if summary is empty (no data)
  bool get isEmpty => totalIncomeMinorUnits == 0 && totalExpensesMinorUnits == 0;

  /// Check if summary has data
  bool get isNotEmpty => !isEmpty;

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'totalIncomeMinorUnits': totalIncomeMinorUnits,
      'totalExpensesMinorUnits': totalExpensesMinorUnits,
      'fixedExpensesMinorUnits': fixedExpensesMinorUnits,
      'variableExpensesMinorUnits': variableExpensesMinorUnits,
      'totalSavingsMinorUnits': totalSavingsMinorUnits,
      'remainingBalanceMinorUnits': remainingBalanceMinorUnits,
      'currencyCode': currencyCode,
      'budgetUsagePercentage': budgetUsagePercentage,
      'upcomingPaymentsCount': upcomingPaymentsCount,
    };
  }

  /// Create from JSON
  factory FinancialSummary.fromJson(Map<String, dynamic> json) {
    return FinancialSummary(
      totalIncomeMinorUnits: json['totalIncomeMinorUnits'] as int? ?? 0,
      totalExpensesMinorUnits: json['totalExpensesMinorUnits'] as int? ?? 0,
      fixedExpensesMinorUnits: json['fixedExpensesMinorUnits'] as int? ?? 0,
      variableExpensesMinorUnits: json['variableExpensesMinorUnits'] as int? ?? 0,
      totalSavingsMinorUnits: json['totalSavingsMinorUnits'] as int? ?? 0,
      remainingBalanceMinorUnits: json['remainingBalanceMinorUnits'] as int? ?? 0,
      currencyCode: json['currencyCode'] as String? ?? 'SAR',
      budgetUsagePercentage: json['budgetUsagePercentage'] as double? ?? 0.0,
      upcomingPaymentsCount: json['upcomingPaymentsCount'] as int? ?? 0,
    );
  }
}

/// Category spending model
class CategorySpending {
  /// Category ID
  final String categoryId;

  /// Category name
  final String categoryName;

  /// Amount spent in minor units
  final int amountMinorUnits;

  /// Percentage of total spending
  final double percentage;

  /// Icon for the category
  final String icon;

  const CategorySpending({
    required this.categoryId,
    required this.categoryName,
    required this.amountMinorUnits,
    required this.percentage,
    required this.icon,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'categoryName': categoryName,
      'amountMinorUnits': amountMinorUnits,
      'percentage': percentage,
      'icon': icon,
    };
  }

  /// Create from JSON
  factory CategorySpending.fromJson(Map<String, dynamic> json) {
    return CategorySpending(
      categoryId: json['categoryId'] as String,
      categoryName: json['categoryName'] as String,
      amountMinorUnits: json['amountMinorUnits'] as int,
      percentage: json['percentage'] as double,
      icon: json['icon'] as String,
    );
  }
}

/// Monthly statistics model
class MonthlyStatistics {
  /// Month (1-12)
  final int month;

  /// Year
  final int year;

  /// Total income
  final int totalIncomeMinorUnits;

  /// Total expenses
  final int totalExpensesMinorUnits;

  /// Average daily spending
  final int averageDailySpendingMinorUnits;

  /// Highest spending category
  final String highestSpendingCategory;

  /// Number of transactions
  final int transactionCount;

  const MonthlyStatistics({
    required this.month,
    required this.year,
    required this.totalIncomeMinorUnits,
    required this.totalExpensesMinorUnits,
    required this.averageDailySpendingMinorUnits,
    required this.highestSpendingCategory,
    required this.transactionCount,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'month': month,
      'year': year,
      'totalIncomeMinorUnits': totalIncomeMinorUnits,
      'totalExpensesMinorUnits': totalExpensesMinorUnits,
      'averageDailySpendingMinorUnits': averageDailySpendingMinorUnits,
      'highestSpendingCategory': highestSpendingCategory,
      'transactionCount': transactionCount,
    };
  }

  /// Create from JSON
  factory MonthlyStatistics.fromJson(Map<String, dynamic> json) {
    return MonthlyStatistics(
      month: json['month'] as int,
      year: json['year'] as int,
      totalIncomeMinorUnits: json['totalIncomeMinorUnits'] as int,
      totalExpensesMinorUnits: json['totalExpensesMinorUnits'] as int,
      averageDailySpendingMinorUnits: json['averageDailySpendingMinorUnits'] as int,
      highestSpendingCategory: json['highestSpendingCategory'] as String,
      transactionCount: json['transactionCount'] as int,
    );
  }
}
