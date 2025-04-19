import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:simpelbudget/models/transaction.dart' as mt;
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final databaseName = "budget.db";
  static final _databaseVersion = 1;

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    String path = join(await getDatabasesPath(), databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        type TEXT NOT NULL,
        receiptPath TEXT
      )
    ''');
  }

  Future<int> insertTransaction(mt.Transaction txn) async {
    Database db = await instance.database;
    return await db.insert('transactions', txn.toMap());
  }

  Future<List<mt.Transaction>> getTransactions() async {
    Database db = await instance.database;
    var transactions = await db.query('transactions', orderBy: 'date DESC, id DESC');
    return transactions.map((t) => mt.Transaction.fromMap(t)).toList();
  }

  Future<List<mt.Transaction>> getTransactionsByType(String type) async {
    Database db = await instance.database;
    var transactions = await db.query(
      'transactions',
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'date DESC, id DESC',
    );
    return transactions.map((t) => mt.Transaction.fromMap(t)).toList();
  }

  Future<double> getTotalByType(String type) async {
    Database db = await instance.database;
    var result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transactions WHERE type = ?',
      [type],
    );
    return result.first['total'] == null
        ? 0.0
        : result.first['total'] as double;
  }

  Future<int> deleteTransaction(int id) async {
    Database db = await instance.database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> saveSettings(Map<String, dynamic> settings) async {
    Database db = await instance.database;

    await db.execute('''
      CREATE TABLE IF NOT EXISTS settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    for (var entry in settings.entries) {
      await db.insert('settings', {
        'key': entry.key,
        'value': entry.value.toString(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> updateSetting(String key, String value) async {
    Database db = await instance.database;
    await db.update(
      'settings',
      {'value': value},
      where: 'key = ?',
      whereArgs: [key],
    );
  }

  Future<Map<String, dynamic>> getSettings() async {
    Database db = await instance.database;

    await db.execute('''
      CREATE TABLE IF NOT EXISTS settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    final List<Map<String, dynamic>> maps = await db.query('settings');

    final result = <String, dynamic>{};
    for (var map in maps) {
      result[map['key']] = map['value'];
    }
    return result;
  }

  Future<List<mt.Transaction>> getTransactionsByCutoffDate(
    DateTime cutoffDate,
    int month,
    int year,
  ) async {
    Database db = await instance.database;

    final DateTime startDate;
    final DateTime endDate;

    final currentDate = DateTime(year, month, cutoffDate.day);

    if (cutoffDate.day > DateTime(year, month + 1, 0).day) {
      startDate = DateTime(year, month - 1, cutoffDate.day);
      endDate = DateTime(year, month, DateTime(year, month + 1, 0).day);
    } else {
      startDate = DateTime(year, month - 1, cutoffDate.day);
      endDate = DateTime(year, month, cutoffDate.day - 1);
    }

    final formattedStartDate = DateFormat('yyyy-MM-dd').format(startDate);
    final formattedEndDate = DateFormat('yyyy-MM-dd').format(endDate);

    final transactions = await db.query(
      'transactions',
      where: 'date >= ? AND date <= ?',
      whereArgs: [formattedStartDate, formattedEndDate],
      orderBy: 'date DESC',
    );

    return transactions.map((t) => mt.Transaction.fromMap(t)).toList();
  }

  Future<Map<String, double>> getStatsByPeriod(
    DateTime startDate,
    DateTime endDate,
  ) async {
    Database db = await instance.database;

    final formattedStartDate = DateFormat('yyyy-MM-dd').format(startDate);
    final formattedEndDate = DateFormat('yyyy-MM-dd').format(endDate);

    var result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transactions WHERE type = ? AND date >= ? AND date <= ?',
      ['income', formattedStartDate, formattedEndDate],
    );
    final income =
        result.first['total'] == null ? 0.0 : result.first['total'] as double;

    result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transactions WHERE type = ? AND date >= ? AND date <= ?',
      ['expense', formattedStartDate, formattedEndDate],
    );
    final expense =
        result.first['total'] == null ? 0.0 : result.first['total'] as double;

    return {'income': income, 'expense': expense, 'balance': income - expense};
  }
}
