import '../../data/local/entities/expense_entity.dart';

enum ExpenseCategory {
  housing,
  electricity,
  water,
  internet,
  phone,
  transportation,
  food,
  shopping,
  education,
  health,
  entertainment,
  subscriptions,
  installments,
  insurance,
  family,
  savings,
  other,
  custom,
}

extension ExpenseCategoryExtension on ExpenseCategory {
  String get nameAr {
    switch (this) {
      case ExpenseCategory.housing: return 'السكن';
      case ExpenseCategory.electricity: return 'الكهرباء';
      case ExpenseCategory.water: return 'المياه';
      case ExpenseCategory.internet: return 'الإنترنت';
      case ExpenseCategory.phone: return 'الهاتف';
      case ExpenseCategory.transportation: return 'المواصلات';
      case ExpenseCategory.food: return 'الطعام';
      case ExpenseCategory.shopping: return 'التسوق';
      case ExpenseCategory.education: return 'التعليم';
      case ExpenseCategory.health: return 'الصحة';
      case ExpenseCategory.entertainment: return 'الترفيه';
      case ExpenseCategory.subscriptions: return 'الاشتراكات';
      case ExpenseCategory.installments: return 'الأقساط';
      case ExpenseCategory.insurance: return 'التأمين';
      case ExpenseCategory.family: return 'العائلة';
      case ExpenseCategory.savings: return 'الادخار';
      case ExpenseCategory.other: return 'أخرى';
      case ExpenseCategory.custom: return 'مخصص';
    }
  }

  String get nameEn {
    switch (this) {
      case ExpenseCategory.housing: return 'Housing';
      case ExpenseCategory.electricity: return 'Electricity';
      case ExpenseCategory.water: return 'Water';
      case ExpenseCategory.internet: return 'Internet';
      case ExpenseCategory.phone: return 'Phone';
      case ExpenseCategory.transportation: return 'Transportation';
      case ExpenseCategory.food: return 'Food';
      case ExpenseCategory.shopping: return 'Shopping';
      case ExpenseCategory.education: return 'Education';
      case ExpenseCategory.health: return 'Health';
      case ExpenseCategory.entertainment: return 'Entertainment';
      case ExpenseCategory.subscriptions: return 'Subscriptions';
      case ExpenseCategory.installments: return 'Installments';
      case ExpenseCategory.insurance: return 'Insurance';
      case ExpenseCategory.family: return 'Family';
      case ExpenseCategory.savings: return 'Savings';
      case ExpenseCategory.other: return 'Other';
      case ExpenseCategory.custom: return 'Custom';
    }
  }

  String get icon {
    switch (this) {
      case ExpenseCategory.housing: return '🏠';
      case ExpenseCategory.electricity: return '💡';
      case ExpenseCategory.water: return '💧';
      case ExpenseCategory.internet: return '📶';
      case ExpenseCategory.phone: return '📱';
      case ExpenseCategory.transportation: return '🚗';
      case ExpenseCategory.food: return '🍽️';
      case ExpenseCategory.shopping: return '🛍️';
      case ExpenseCategory.education: return '📚';
      case ExpenseCategory.health: return '🏥';
      case ExpenseCategory.entertainment: return '🎬';
      case ExpenseCategory.subscriptions: return '📺';
      case ExpenseCategory.installments: return '💳';
      case ExpenseCategory.insurance: return '🛡️';
      case ExpenseCategory.family: return '👨‍👩‍👧‍👦';
      case ExpenseCategory.savings: return '💰';
      case ExpenseCategory.other: return '📦';
      case ExpenseCategory.custom: return '⭐';
    }
  }
}

class Expense {
  final int? id;
  final String title;
  final int amountInMinorUnits;
  final ExpenseCategory category;
  final DateTime date;
  final String? note;
  final String currencyCode;
  final bool isRecurring;
  final int? recurringExpenseId;

  const Expense({
    this.id,
    required this.title,
    required this.amountInMinorUnits,
    required this.category,
    required this.date,
    this.note,
    required this.currencyCode,
    this.isRecurring = false,
    this.recurringExpenseId,
  });

  double get amount => amountInMinorUnits / 100.0;

  Expense copyWith({
    int? id,
    String? title,
    int? amountInMinorUnits,
    ExpenseCategory? category,
    DateTime? date,
    String? note,
    String? currencyCode,
    bool? isRecurring,
    int? recurringExpenseId,
  }) {
    return Expense(
      id: id ?? this.id,
      title: title ?? this.title,
      amountInMinorUnits: amountInMinorUnits ?? this.amountInMinorUnits,
      category: category ?? this.category,
      date: date ?? this.date,
      note: note ?? this.note,
      currencyCode: currencyCode ?? this.currencyCode,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringExpenseId: recurringExpenseId ?? this.recurringExpenseId,
    );
  }

  ExpenseEntity toEntity() {
    return ExpenseEntity(
      id: id,
      title: title,
      amountInMinorUnits: amountInMinorUnits,
      category: category.name,
      date: date,
      note: note,
      currencyCode: currencyCode,
      isRecurring: isRecurring ? 1 : 0,
      recurringExpenseId: recurringExpenseId,
    );
  }

  static Expense fromEntity(ExpenseEntity entity) {
    return Expense(
      id: entity.id,
      title: entity.title,
      amountInMinorUnits: entity.amountInMinorUnits,
      category: ExpenseCategory.values.firstWhere(
        (e) => e.name == entity.category,
        orElse: () => ExpenseCategory.other,
      ),
      date: entity.date,
      note: entity.note,
      currencyCode: entity.currencyCode,
      isRecurring: entity.isRecurring == 1,
      recurringExpenseId: entity.recurringExpenseId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amountInMinorUnits': amountInMinorUnits,
      'category': category.name,
      'date': date.toIso8601String(),
      'note': note,
      'currencyCode': currencyCode,
      'isRecurring': isRecurring,
      'recurringExpenseId': recurringExpenseId,
    };
  }

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as int?,
      title: json['title'] as String,
      amountInMinorUnits: json['amountInMinorUnits'] as int,
      category: ExpenseCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => ExpenseCategory.other,
      ),
      date: DateTime.parse(json['date'] as String),
      note: json['note'] as String?,
      currencyCode: json['currencyCode'] as String,
      isRecurring: json['isRecurring'] as bool? ?? false,
      recurringExpenseId: json['recurringExpenseId'] as int?,
    );
  }
}
