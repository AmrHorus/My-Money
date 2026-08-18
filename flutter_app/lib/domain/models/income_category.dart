/// Income category enum
enum IncomeCategory {
  salary,
  freelance,
  business,
  gift,
  bonus,
  investment,
  rental,
  other,
}

extension IncomeCategoryExtension on IncomeCategory {
  /// Arabic name
  String get nameAr {
    switch (this) {
      case IncomeCategory.salary: return 'الراتب';
      case IncomeCategory.freelance: return 'عمل حر';
      case IncomeCategory.business: return 'تجارة';
      case IncomeCategory.gift: return 'هدية';
      case IncomeCategory.bonus: return 'مكافأة';
      case IncomeCategory.investment: return 'استثمار';
      case IncomeCategory.rental: return 'إيجار';
      case IncomeCategory.other: return 'أخرى';
    }
  }

  /// English name
  String get nameEn {
    switch (this) {
      case IncomeCategory.salary: return 'Salary';
      case IncomeCategory.freelance: return 'Freelance';
      case IncomeCategory.business: return 'Business';
      case IncomeCategory.gift: return 'Gift';
      case IncomeCategory.bonus: return 'Bonus';
      case IncomeCategory.investment: return 'Investment';
      case IncomeCategory.rental: return 'Rental';
      case IncomeCategory.other: return 'Other';
    }
  }

  /// Icon emoji
  String get icon {
    switch (this) {
      case IncomeCategory.salary: return '💼';
      case IncomeCategory.freelance: return '💻';
      case IncomeCategory.business: return '🏢';
      case IncomeCategory.gift: return '🎁';
      case IncomeCategory.bonus: return '🎉';
      case IncomeCategory.investment: return '📈';
      case IncomeCategory.rental: return '🏠';
      case IncomeCategory.other: return '📦';
    }
  }

  /// Get localized name
  String getName(String locale) {
    return locale == 'ar' ? nameAr : nameEn;
  }

  /// Parse from string
  static IncomeCategory fromString(String value) {
    return IncomeCategory.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => IncomeCategory.other,
    );
  }
}
