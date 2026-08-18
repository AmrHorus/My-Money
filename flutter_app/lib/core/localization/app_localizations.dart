import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  Map<String, String> get _localizedStrings {
    if (locale.languageCode == 'ar') {
      return _arStrings;
    }
    return _enStrings;
  }

  static final Map<String, String> _arStrings = {
    'app_name': 'فلوسي | My Money',
    'tagline': 'فلوسك تحت سيطرتك',
    'monthly_income': 'الدخل الشهري',
    'recurring_expenses': 'المصاريف الثابتة',
    'variable_expenses': 'المصاريف المتغيرة',
    'savings': 'الادخار',
    'remaining': 'المتبقي',
    'income': 'الدخل',
    'expenses': 'المصاريف',
    'obligations': 'الالتزامات',
    'add_expense': 'إضافة مصروف',
    'add_income': 'إضافة دخل',
    'home': 'الرئيسية',
    'budget': 'الميزانية',
    'statistics': 'الإحصائيات',
    'settings': 'الإعدادات',
    'currency': 'العملة',
    'language': 'اللغة',
    'theme': 'السمة',
    'light_mode': 'فاتح',
    'dark_mode': 'داكن',
    'system_mode': 'النظام',
    'housing': 'السكن',
    'electricity': 'الكهرباء',
    'water': 'المياه',
    'internet': 'الإنترنت',
    'phone': 'الهاتف',
    'transportation': 'المواصلات',
    'food': 'الطعام',
    'shopping': 'التسوق',
    'education': 'التعليم',
    'health': 'الصحة',
    'entertainment': 'الترفيه',
    'subscriptions': 'الاشتراكات',
    'installments': 'الأقساط',
    'insurance': 'التأمين',
    'family': 'العائلة',
    'fixed_expenses': 'المصاريف الثابتة',
    'disposable_money': 'المتاح للصرف',
    'current_balance': 'الرصيد الحالي',
    'upcoming_payments': 'المدفوعات القادمة',
    'recent_expenses': 'آخر المصاريف',
    'no_data_available': 'لا تتوفر بيانات',
    'success': 'تم بنجاح',
    'error': 'خطأ',
    'save': 'حفظ',
    'cancel': 'إلغاء',
    'delete': 'حذف',
    'edit': 'تعديل',
    'active': 'نشط',
    'inactive': 'غير نشط',
    'goal': 'هدف',
    'goals': 'أهداف',
    'target_amount': 'المبلغ المستهدف',
    'current_amount': 'المبلغ الحالي',
    'progress': 'التقدم',
    'achieved': 'تحقق',
  };

  static final Map<String, String> _enStrings = {
    'app_name': 'My Money',
    'tagline': 'Your Money Under Control',
    'monthly_income': 'Monthly Income',
    'recurring_expenses': 'Recurring Expenses',
    'variable_expenses': 'Variable Expenses',
    'savings': 'Savings',
    'remaining': 'Remaining',
    'income': 'Income',
    'expenses': 'Expenses',
    'obligations': 'Obligations',
    'add_expense': 'Add Expense',
    'add_income': 'Add Income',
    'home': 'Home',
    'budget': 'Budget',
    'statistics': 'Statistics',
    'settings': 'Settings',
    'currency': 'Currency',
    'language': 'Language',
    'theme': 'Theme',
    'light_mode': 'Light',
    'dark_mode': 'Dark',
    'system_mode': 'System',
    'housing': 'Housing',
    'electricity': 'Electricity',
    'water': 'Water',
    'internet': 'Internet',
    'phone': 'Phone',
    'transportation': 'Transportation',
    'food': 'Food',
    'shopping': 'Shopping',
    'education': 'Education',
    'health': 'Health',
    'entertainment': 'Entertainment',
    'subscriptions': 'Subscriptions',
    'installments': 'Installments',
    'insurance': 'Insurance',
    'family': 'Family',
    'fixed_expenses': 'Fixed Expenses',
    'disposable_money': 'Disposable Money',
    'current_balance': 'Current Balance',
    'upcoming_payments': 'Upcoming Payments',
    'recent_expenses': 'Recent Expenses',
    'no_data_available': 'No data available',
    'success': 'Success',
    'error': 'Error',
    'save': 'Save',
    'cancel': 'Cancel',
    'delete': 'Delete',
    'edit': 'Edit',
    'active': 'Active',
    'inactive': 'Inactive',
    'goal': 'Goal',
    'goals': 'Goals',
    'target_amount': 'Target Amount',
    'current_amount': 'Current Amount',
    'progress': 'Progress',
    'achieved': 'Achieved',
  };

  String tr(String key) => _localizedStrings[key] ?? key;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ar'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('ar');

  Locale get locale => _locale;

  void setLocale(Locale locale) {
    _locale = locale;
    notifyListeners();
  }

  bool get isArabic => _locale.languageCode == 'ar';
  bool get isEnglish => _locale.languageCode == 'en';
}
