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

  // Arabic strings
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
    'add_recurring': 'إضافة مصروف ثابت',
    'title': 'العنوان',
    'amount': 'المبلغ',
    'category': 'التصنيف',
    'date': 'التاريخ',
    'note': 'ملاحظة',
    'save': 'حفظ',
    'cancel': 'إلغاء',
    'delete': 'حذف',
    'edit': 'تعديل',
    'confirm': 'تأكيد',
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
    'onboarding_welcome': 'مرحباً بك في فلوسي',
    'onboarding_subtitle': 'نظم مصاريفك الشهرية بسهولة',
    'get_started': 'ابدأ الآن',
    'whats_your_currency': 'ما هي عملتك؟',
    'whats_your_monthly_income': 'كم مرتبك الشهري؟',
    'do_you_have_recurring_expenses': 'هل لديك مصاريف شهرية ثابتة؟',
    'next': 'التالي',
    'skip': 'تخطي',
    'finish': 'إنهاء',
    'upcoming_payments': 'المدفوعات القادمة',
    'recent_expenses': 'آخر المصاريف',
    'daily_budget': 'الميزانية اليومية المقترحة',
    'monthly_report': 'التقرير الشهري',
    'export_data': 'تصدير البيانات',
    'privacy': 'الخصوصية',
    'about': 'عن التطبيق',
    'version': 'الإصدار',
    'no_expenses_yet': 'لا توجد مصاريف بعد',
    'add_first_expense': 'أضف أول مصروف',
    'are_you_sure': 'هل أنت متأكد؟',
    'this_action_cannot_be_undone': 'لا يمكن التراجع عن هذا الإجراء',
    'success': 'تم بنجاح',
    'error': 'خطأ',
    'please_enter_valid_amount': 'من فضلك أدخل مبلغًا صحيحًا',
    'please_enter_amount_greater_than_zero': 'من فضلك أدخل مبلغًا أكبر من صفر',
    'welcome_to_flousi': 'أهلاً وسهلاً بك في برنامج فلوسي!!',
    'enter_info_for_best_experience': 'عايزك تحط كام حاجة هنا علشان ناخد أفضل تجربة ممكنة وإنت بتستخدم البرنامج',
    'full_name': 'الاسم الكريم',
    'enter_your_name': 'ادخل اسمك الكريم',
    'name_required': 'الاسم مطلوب',
    'monthly_salary': 'الراتب الشهري',
    'example': 'مثال',
    'enter_valid_amount_greater_than_zero': 'أدخل مبلغ صحيح أكبر من صفر',
    'enter_amount_below': 'ضع المبلغ لكل شيء في الأسفل',
    'water_bill': 'فاتورة الماء',
    'electricity_bill': 'فاتورة الكهرباء',
    'have_important_bills': 'هل عندك فواتير مهمة عايز تحطها؟',
    'important_to_add_bills': 'من المهم إنك تحطها علشان نعرف نحسب الفلوس صح',
    'add_new_bill': 'إضافة فاتورة جديدة',
    'added_bills': 'الفواتير المضافة',
    'bill_name': 'اسم الفاتورة',
    'amount': 'المبلغ',
    'choose_icon': 'اختر أيقونة',
    'choose_color': 'اختر لون',
    'add': 'إضافة',
    'cancel': 'إلغاء',
    'edit': 'تعديل',
    'delete': 'حذف',
    'edit_bill': 'تعديل الفاتورة',
    'save': 'حفظ',
    'confirm_delete_bill': 'هل أنت متأكد إنك عايز تحذف الفاتورة؟',
    'congratulations': 'مبروك!',
    'onboarding_complete': 'كدا خلصت كل حاجة.... إستمتع ببرنامج فلوسي',
    'launch': 'إنطلاق',
    'back': 'السابق',
    'next': 'التالي',
  };

  // English strings
  static final Map<String, String> _enStrings = {
    'app_name': 'فلوسي | My Money',
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
    'add_recurring': 'Add Recurring',
    'title': 'Title',
    'amount': 'Amount',
    'category': 'Category',
    'date': 'Date',
    'note': 'Note',
    'save': 'Save',
    'cancel': 'Cancel',
    'delete': 'Delete',
    'edit': 'Edit',
    'confirm': 'Confirm',
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
    'onboarding_welcome': 'Welcome to Flousi',
    'onboarding_subtitle': 'Organize your monthly expenses easily',
    'get_started': 'Get Started',
    'whats_your_currency': "What's your currency?",
    'whats_your_monthly_income': "What's your monthly income?",
    'do_you_have_recurring_expenses': 'Do you have recurring monthly expenses?',
    'next': 'Next',
    'skip': 'Skip',
    'finish': 'Finish',
    'upcoming_payments': 'Upcoming Payments',
    'recent_expenses': 'Recent Expenses',
    'daily_budget': 'Suggested Daily Budget',
    'monthly_report': 'Monthly Report',
    'export_data': 'Export Data',
    'privacy': 'Privacy',
    'about': 'About',
    'version': 'Version',
    'no_expenses_yet': 'No expenses yet',
    'add_first_expense': 'Add first expense',
    'are_you_sure': 'Are you sure?',
    'this_action_cannot_be_undone': 'This action cannot be undone',
    'success': 'Success',
    'error': 'Error',
    'please_enter_valid_amount': 'Please enter a valid amount',
    'please_enter_amount_greater_than_zero': 'Please enter an amount greater than zero',
    'welcome_to_flousi': 'Welcome to Flousi Program!!',
    'enter_info_for_best_experience': 'We need you to enter a few things here so we can give you the best experience while using the app',
    'full_name': 'Full Name',
    'enter_your_name': 'Enter your name',
    'name_required': 'Name is required',
    'monthly_salary': 'Monthly Salary',
    'example': 'Example',
    'enter_valid_amount_greater_than_zero': 'Enter a valid amount greater than zero',
    'enter_amount_below': 'Enter the amount for each item below',
    'water_bill': 'Water Bill',
    'electricity_bill': 'Electricity Bill',
    'have_important_bills': 'Do you have important bills to add?',
    'important_to_add_bills': 'It\'s important to add them so we can calculate your money correctly',
    'add_new_bill': 'Add New Bill',
    'added_bills': 'Added Bills',
    'bill_name': 'Bill Name',
    'amount': 'Amount',
    'choose_icon': 'Choose Icon',
    'choose_color': 'Choose Color',
    'add': 'Add',
    'cancel': 'Cancel',
    'edit': 'Edit',
    'delete': 'Delete',
    'edit_bill': 'Edit Bill',
    'save': 'Save',
    'confirm_delete_bill': 'Are you sure you want to delete this bill?',
    'congratulations': 'Congratulations!',
    'onboarding_complete': 'You\'re all set.... Enjoy Flousi Program',
    'launch': 'Launch',
    'back': 'Back',
    'next': 'Next',
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
