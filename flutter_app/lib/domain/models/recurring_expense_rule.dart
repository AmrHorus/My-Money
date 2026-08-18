/// Recurrence frequency enum
enum RecurrenceFrequency {
  daily,
  weekly,
  biweekly,
  monthly,
  quarterly,
  yearly,
}

extension RecurrenceFrequencyExtension on RecurrenceFrequency {
  /// Arabic name
  String get nameAr {
    switch (this) {
      case RecurrenceFrequency.daily: return 'يومي';
      case RecurrenceFrequency.weekly: return 'أسبوعي';
      case RecurrenceFrequency.biweekly: return 'كل أسبوعين';
      case RecurrenceFrequency.monthly: return 'شهري';
      case RecurrenceFrequency.quarterly: return 'ربع سنوي';
      case RecurrenceFrequency.yearly: return 'سنوي';
    }
  }

  /// English name
  String get nameEn {
    switch (this) {
      case RecurrenceFrequency.daily: return 'Daily';
      case RecurrenceFrequency.weekly: return 'Weekly';
      case RecurrenceFrequency.biweekly: return 'Bi-weekly';
      case RecurrenceFrequency.monthly: return 'Monthly';
      case RecurrenceFrequency.quarterly: return 'Quarterly';
      case RecurrenceFrequency.yearly: return 'Yearly';
    }
  }

  /// Get localized name
  String getName(String locale) {
    return locale == 'ar' ? nameAr : nameEn;
  }

  /// Get number of days per recurrence
  int get daysPerRecurrence {
    switch (this) {
      case RecurrenceFrequency.daily: return 1;
      case RecurrenceFrequency.weekly: return 7;
      case RecurrenceFrequency.biweekly: return 14;
      case RecurrenceFrequency.monthly: return 30; // Approximate
      case RecurrenceFrequency.quarterly: return 90; // Approximate
      case RecurrenceFrequency.yearly: return 365;
    }
  }

  /// Parse from string
  static RecurrenceFrequency fromString(String value) {
    return RecurrenceFrequency.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => RecurrenceFrequency.monthly,
    );
  }
}

/// Recurring expense rule model
class RecurringExpenseRule {
  /// Unique identifier
  final String id;

  /// User ID
  final String userId;

  /// Title/description
  final String title;

  /// Amount in minor units
  final int amountMinorUnits;

  /// Currency code
  final String currencyCode;

  /// Category ID
  final String categoryId;

  /// Recurrence frequency
  final RecurrenceFrequency frequency;

  /// Day of month for monthly recurrences (1-31)
  final int? dayOfMonth;

  /// Day of week for weekly recurrences (1-7, Monday-Sunday)
  final int? dayOfWeek;

  /// Start date
  final DateTime startDate;

  /// End date (optional)
  final DateTime? endDate;

  /// Whether the rule is active
  final bool isActive;

  /// Note
  final String? note;

  /// Created timestamp
  final DateTime createdAt;

  /// Updated timestamp
  final DateTime updatedAt;

  const RecurringExpenseRule({
    required this.id,
    required this.userId,
    required this.title,
    required this.amountMinorUnits,
    required this.currencyCode,
    required this.categoryId,
    required this.frequency,
    this.dayOfMonth,
    this.dayOfWeek,
    this.startDate = DateTime.now(),
    this.endDate,
    this.isActive = true,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Calculate next occurrence date
  DateTime? getNextOccurrence(DateTime fromDate) {
    if (!isActive) return null;
    if (endDate != null && fromDate.isAfter(endDate!)) return null;

    switch (frequency) {
      case RecurrenceFrequency.daily:
        return fromDate.add(const Duration(days: 1));
      case RecurrenceFrequency.weekly:
        return fromDate.add(Duration(days: 7 - fromDate.weekday + (dayOfWeek ?? 1)));
      case RecurrenceFrequency.biweekly:
        return fromDate.add(const Duration(days: 14));
      case RecurrenceFrequency.monthly:
        final nextMonth = fromDate.month == 12 ? 1 : fromDate.month + 1;
        final nextYear = fromDate.month == 12 ? fromDate.year + 1 : fromDate.year;
        final day = dayOfMonth ?? fromDate.day;
        // Handle months with fewer days
        final lastDayOfMonth = DateTime(nextYear, nextMonth + 1, 0).day;
        final actualDay = day > lastDayOfMonth ? lastDayOfMonth : day;
        return DateTime(nextYear, nextMonth, actualDay);
      case RecurrenceFrequency.quarterly:
        final nextMonth = fromDate.month + 3;
        final nextYear = fromDate.year + (nextMonth > 12 ? 1 : 0);
        final actualMonth = nextMonth > 12 ? nextMonth - 12 : nextMonth;
        return DateTime(nextYear, actualMonth, fromDate.day);
      case RecurrenceFrequency.yearly:
        return DateTime(fromDate.year + 1, fromDate.month, fromDate.day);
    }
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
      'frequency': frequency.name,
      'dayOfMonth': dayOfMonth,
      'dayOfWeek': dayOfWeek,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'isActive': isActive,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory RecurringExpenseRule.fromJson(Map<String, dynamic> json) {
    return RecurringExpenseRule(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      amountMinorUnits: json['amountMinorUnits'] as int,
      currencyCode: json['currencyCode'] as String,
      categoryId: json['categoryId'] as String,
      frequency: RecurrenceFrequency.values.firstWhere(
        (e) => e.name == json['frequency'],
        orElse: () => RecurrenceFrequency.monthly,
      ),
      dayOfMonth: json['dayOfMonth'] as int?,
      dayOfWeek: json['dayOfWeek'] as int?,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null 
          ? DateTime.parse(json['endDate'] as String) 
          : null,
      isActive: json['isActive'] as bool? ?? true,
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
