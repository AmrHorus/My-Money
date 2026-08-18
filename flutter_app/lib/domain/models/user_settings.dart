/// User settings model
class UserSettings {
  /// Unique identifier
  final String id;

  /// Primary currency code
  final String primaryCurrency;

  /// Language code ('ar' or 'en')
  final String languageCode;

  /// Theme mode ('light', 'dark', 'system')
  final String themeMode;

  /// Monthly income in minor units
  final int monthlyIncomeMinorUnits;

  /// Notifications enabled
  final bool notificationsEnabled;

  /// Created timestamp
  final DateTime createdAt;

  /// Updated timestamp
  final DateTime updatedAt;

  const UserSettings({
    required this.id,
    this.primaryCurrency = 'SAR',
    this.languageCode = 'ar',
    this.themeMode = 'system',
    this.monthlyIncomeMinorUnits = 0,
    this.notificationsEnabled = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a copy with updated fields
  UserSettings copyWith({
    String? id,
    String? primaryCurrency,
    String? languageCode,
    String? themeMode,
    int? monthlyIncomeMinorUnits,
    bool? notificationsEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserSettings(
      id: id ?? this.id,
      primaryCurrency: primaryCurrency ?? this.primaryCurrency,
      languageCode: languageCode ?? this.languageCode,
      themeMode: themeMode ?? this.themeMode,
      monthlyIncomeMinorUnits: monthlyIncomeMinorUnits ?? this.monthlyIncomeMinorUnits,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'primaryCurrency': primaryCurrency,
      'languageCode': languageCode,
      'themeMode': themeMode,
      'monthlyIncomeMinorUnits': monthlyIncomeMinorUnits,
      'notificationsEnabled': notificationsEnabled,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      id: json['id'] as String,
      primaryCurrency: json['primaryCurrency'] as String? ?? 'SAR',
      languageCode: json['languageCode'] as String? ?? 'ar',
      themeMode: json['themeMode'] as String? ?? 'system',
      monthlyIncomeMinorUnits: json['monthlyIncomeMinorUnits'] as int? ?? 0,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

/// Account model for tracking different money accounts
class Account {
  /// Unique identifier
  final String id;

  /// User ID
  final String userId;

  /// Account name
  final String name;

  /// Account type: 'cash', 'bank', 'wallet', 'credit_card', 'savings'
  final String type;

  /// Current balance in minor units
  final int balanceMinorUnits;

  /// Currency code
  final String currencyCode;

  /// Whether the account is active
  final bool isActive;

  /// Optional note
  final String? note;

  /// Created timestamp
  final DateTime createdAt;

  /// Updated timestamp
  final DateTime updatedAt;

  const Account({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    this.balanceMinorUnits = 0,
    required this.currencyCode,
    this.isActive = true,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Check if this is a credit account (negative balance possible)
  bool get isCreditAccount => type == 'credit_card';

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'type': type,
      'balanceMinorUnits': balanceMinorUnits,
      'currencyCode': currencyCode,
      'isActive': isActive,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      balanceMinorUnits: json['balanceMinorUnits'] as int? ?? 0,
      currencyCode: json['currencyCode'] as String,
      isActive: json['isActive'] as bool? ?? true,
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
