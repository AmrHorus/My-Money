import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('flousi.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Users table (for settings/preferences)
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        currency_code TEXT NOT NULL DEFAULT 'EGP',
        monthly_income_in_minor_units INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // Recurring expenses table - now includes icon and color for bills
    await db.execute('''
      CREATE TABLE recurring_expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount_in_minor_units INTEGER NOT NULL,
        category TEXT NOT NULL,
        frequency TEXT NOT NULL,
        due_day INTEGER NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT,
        note TEXT,
        reminder_enabled INTEGER DEFAULT 0,
        is_active INTEGER DEFAULT 1,
        currency_code TEXT NOT NULL,
        icon_code TEXT NOT NULL DEFAULT 'receipt_long',
        color_hex TEXT NOT NULL DEFAULT 'FF60AD5E',
        created_at TEXT NOT NULL
      )
    ''');

    // Expenses table
    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount_in_minor_units INTEGER NOT NULL,
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        note TEXT,
        currency_code TEXT NOT NULL,
        is_recurring INTEGER DEFAULT 0,
        recurring_expense_id INTEGER,
        created_at TEXT NOT NULL,
        FOREIGN KEY (recurring_expense_id) REFERENCES recurring_expenses(id)
      )
    ''');

    // Income table
    await db.execute('''
      CREATE TABLE income_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount_in_minor_units INTEGER NOT NULL,
        date TEXT NOT NULL,
        note TEXT,
        currency_code TEXT NOT NULL,
        is_recurring INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // Savings goals table
    await db.execute('''
      CREATE TABLE savings_goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        target_amount_in_minor_units INTEGER NOT NULL,
        current_amount_in_minor_units INTEGER DEFAULT 0,
        currency_code TEXT NOT NULL,
        deadline TEXT,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');

    // Create default user
    await db.insert('users', {
      'currency_code': 'EGP',
      'monthly_income_in_minor_units': 0,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> init() async {
    await database;
  }

  // Create recurring expense (bill)
  Future<int> createRecurringExpense({
    required String title,
    required int amountInMinorUnits,
    required String category,
    String iconCode = 'receipt_long',
    String colorHex = 'FF60AD5E',
    String currencyCode = 'EGP',
    String frequency = 'monthly',
    int dueDay = 1,
  }) async {
    final db = await database;
    return await db.insert('recurring_expenses', {
      'title': title,
      'amount_in_minor_units': amountInMinorUnits,
      'category': category,
      'frequency': frequency,
      'due_day': dueDay,
      'start_date': DateTime.now().toIso8601String(),
      'is_active': 1,
      'currency_code': currencyCode,
      'icon_code': iconCode,
      'color_hex': colorHex,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
