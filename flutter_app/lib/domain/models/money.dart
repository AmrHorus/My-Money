import 'package:flutter/foundation.dart';

/// A value object representing money in minor units to avoid floating-point precision issues.
/// 
/// Example: 250.50 SAR is represented as 25050 minor units.
@immutable
class Money implements Comparable<Money> {
  /// The amount in minor units (e.g., cents, halalas)
  final int amountMinorUnits;
  
  /// ISO 4217 currency code (e.g., 'SAR', 'USD', 'EGP')
  final String currencyCode;

  const Money({
    required this.amountMinorUnits,
    required this.currencyCode,
  });

  /// Creates a Money object from major units (e.g., dollars, riyals)
  /// Be aware that this may introduce floating-point precision issues.
  /// Prefer using [fromMinorUnits] or the constructor directly.
  factory Money.fromMajorUnits(double amount, String currencyCode) {
    return Money(
      amountMinorUnits: (amount * 100).round(),
      currencyCode: currencyCode,
    );
  }

  /// Creates a Money object from minor units
  factory Money.fromMinorUnits(int amountMinorUnits, String currencyCode) {
    return Money(
      amountMinorUnits: amountMinorUnits,
      currencyCode: currencyCode,
    );
  }

  /// Zero money for a given currency
  factory Money.zero(String currencyCode) {
    return Money(amountMinorUnits: 0, currencyCode: currencyCode);
  }

  /// The amount in major units (e.g., dollars, riyals) as a double
  /// Use this only for display purposes.
  double get amountMajorUnits => amountMinorUnits / 100.0;

  /// Returns true if the amount is zero
  bool get isZero => amountMinorUnits == 0;

  /// Returns true if the amount is positive
  bool get isPositive => amountMinorUnits > 0;

  /// Returns true if the amount is negative
  bool get isNegative => amountMinorUnits < 0;

  /// Add another Money object with the same currency
  Money operator +(Money other) {
    _checkCurrency(other);
    return Money(
      amountMinorUnits: amountMinorUnits + other.amountMinorUnits,
      currencyCode: currencyCode,
    );
  }

  /// Subtract another Money object with the same currency
  Money operator -(Money other) {
    _checkCurrency(other);
    return Money(
      amountMinorUnits: amountMinorUnits - other.amountMinorUnits,
      currencyCode: currencyCode,
    );
  }

  /// Multiply by a scalar
  Money operator *(int scalar) {
    return Money(
      amountMinorUnits: amountMinorUnits * scalar,
      currencyCode: currencyCode,
    );
  }

  /// Divide by a scalar
  Money operator /(int divisor) {
    return Money(
      amountMinorUnits: amountMinorUnits ~/ divisor,
      currencyCode: currencyCode,
    );
  }

  /// Negate the amount
  Money operator -() {
    return Money(
      amountMinorUnits: -amountMinorUnits,
      currencyCode: currencyCode,
    );
  }

  /// Compare with another Money object
  @override
  int compareTo(Money other) {
    _checkCurrency(other);
    return amountMinorUnits.compareTo(other.amountMinorUnits);
  }

  /// Equality check
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Money &&
        other.amountMinorUnits == amountMinorUnits &&
        other.currencyCode == currencyCode;
  }

  @override
  int get hashCode => Object.hash(amountMinorUnits, currencyCode);

  /// Format the money for display
  String format({String? locale}) {
    // Simple formatting - can be enhanced with intl package
    final symbols = _getCurrencySymbols(currencyCode);
    final formattedAmount = (amountMajorUnits).toStringAsFixed(2);
    
    if (locale == 'ar' || currencyCode == 'SAR' || currencyCode == 'EGP' || currencyCode == 'AED' || currencyCode == 'KWD') {
      return '$formattedAmount $currencyCode';
    } else {
      return '$symbols$formattedAmount';
    }
  }

  /// Format with Arabic locale
  String formatArabic() => format(locale: 'ar');

  /// Format with English locale
  String formatEnglish() => format(locale: 'en');

  void _checkCurrency(Money other) {
    if (currencyCode != other.currencyCode) {
      throw ArgumentError(
        'Cannot perform operation on different currencies: $currencyCode vs ${other.currencyCode}',
      );
    }
  }

  String _getCurrencySymbols(String currencyCode) {
    switch (currencyCode) {
      case 'USD': return '\$';
      case 'EUR': return '€';
      case 'GBP': return '£';
      case 'SAR': return 'ر.س ';
      case 'EGP': return 'ج.م ';
      case 'AED': return 'د.إ ';
      case 'KWD': return 'د.ك ';
      default: return '$currencyCode ';
    }
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'amountMinorUnits': amountMinorUnits,
      'currencyCode': currencyCode,
    };
  }

  /// Create from JSON
  factory Money.fromJson(Map<String, dynamic> json) {
    return Money(
      amountMinorUnits: json['amountMinorUnits'] as int,
      currencyCode: json['currencyCode'] as String,
    );
  }

  @override
  String toString() => 'Money(${amountMinorUnits} $currencyCode)';
}
