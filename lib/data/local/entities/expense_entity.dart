class ExpenseEntity {
  final int? id;
  final String title;
  final int amountInMinorUnits;
  final String category;
  final DateTime date;
  final String? note;
  final String currencyCode;
  final int isRecurring; // 0 or 1
  final int? recurringExpenseId;

  const ExpenseEntity({
    this.id,
    required this.title,
    required this.amountInMinorUnits,
    required this.category,
    required this.date,
    this.note,
    required this.currencyCode,
    required this.isRecurring,
    this.recurringExpenseId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amountInMinorUnits': amountInMinorUnits,
      'category': category,
      'date': date.toIso8601String(),
      'note': note,
      'currencyCode': currencyCode,
      'isRecurring': isRecurring,
      'recurringExpenseId': recurringExpenseId,
    };
  }

  factory ExpenseEntity.fromMap(Map<String, dynamic> map) {
    return ExpenseEntity(
      id: map['id'] as int?,
      title: map['title'] as String,
      amountInMinorUnits: map['amountInMinorUnits'] as int,
      category: map['category'] as String,
      date: DateTime.parse(map['date'] as String),
      note: map['note'] as String?,
      currencyCode: map['currencyCode'] as String,
      isRecurring: map['isRecurring'] as int,
      recurringExpenseId: map['recurringExpenseId'] as int?,
    );
  }
}
