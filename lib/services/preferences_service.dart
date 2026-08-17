import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static final PreferencesService instance = PreferencesService._init();
  SharedPreferences? _prefs;

  PreferencesService._init();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  bool get isInitialized => _prefs != null;

  // Onboarding status
  Future<bool> isOnboarded() async {
    await _ensureInitialized();
    return _prefs?.getBool('is_onboarded') ?? false;
  }

  Future<void> setOnboarded(bool value) async {
    await _ensureInitialized();
    await _prefs?.setBool('is_onboarded', value);
  }

  // Theme preference
  String getThemeMode() {
    return _prefs?.getString('theme_mode') ?? 'system';
  }

  Future<void> setThemeMode(String mode) async {
    await _ensureInitialized();
    await _prefs?.setString('theme_mode', mode);
  }

  // Language preference
  String getLanguage() {
    return _prefs?.getString('language') ?? 'ar';
  }

  Future<void> setLanguage(String language) async {
    await _ensureInitialized();
    await _prefs?.setString('language', language);
  }

  // Currency preference
  String getCurrency() {
    return _prefs?.getString('currency') ?? 'SAR';
  }

  Future<void> setCurrency(String currency) async {
    await _ensureInitialized();
    await _prefs?.setString('currency', currency);
  }

  // Monthly income (in minor units)
  int getMonthlyIncome() {
    return _prefs?.getInt('monthly_income') ?? 0;
  }

  Future<void> setMonthlyIncome(int amountInMinorUnits) async {
    await _ensureInitialized();
    await _prefs?.setInt('monthly_income', amountInMinorUnits);
  }

  // First launch date
  DateTime? getFirstLaunchDate() {
    final dateString = _prefs?.getString('first_launch_date');
    if (dateString == null) return null;
    return DateTime.parse(dateString);
  }

  Future<void> setFirstLaunchDate() async {
    await _ensureInitialized();
    if (_prefs?.getString('first_launch_date') == null) {
      await _prefs?.setString('first_launch_date', DateTime.now().toIso8601String());
    }
  }

  // Notifications enabled
  bool getNotificationsEnabled() {
    return _prefs?.getBool('notifications_enabled') ?? true;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    await _ensureInitialized();
    await _prefs?.setBool('notifications_enabled', enabled);
  }

  // Clear all data
  Future<void> clearAll() async {
    await _ensureInitialized();
    await _prefs?.clear();
  }

  Future<void> _ensureInitialized() async {
    if (_prefs == null) {
      await init();
    }
  }
}
