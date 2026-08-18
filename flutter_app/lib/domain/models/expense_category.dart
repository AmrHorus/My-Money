/// Expense category enum with localization support
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
  /// Arabic name
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

  /// English name
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

  /// Icon emoji
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

  /// Get localized name
  String getName(String locale) {
    return locale == 'ar' ? nameAr : nameEn;
  }

  /// Parse from string
  static ExpenseCategory fromString(String value) {
    return ExpenseCategory.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => ExpenseCategory.other,
    );
  }
}
