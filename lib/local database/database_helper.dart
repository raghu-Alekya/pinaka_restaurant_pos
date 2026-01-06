import 'package:sqflite/sqflite.dart';
import 'db_init.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await DatabaseInitializer().initDatabase();
    return _database!;
  }

  // ✅ Get logged-in user
  Future<Map<String, dynamic>?> getLoggedInUser() async {
    final db = await database;
    final result = await db.query(
      'user_login',
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  // ✅ Get current shift
  Future<int?> getCurrentShiftId() async {
    final db = await database;
    final result = await db.query(
      'shifts',
      orderBy: 'shift_id DESC',
      limit: 1,
    );
    return result.isNotEmpty ? result.first['shift_id'] as int : null;
  }

  // (Optional) Clear session
  Future<void> clearSession() async {
    final db = await database;
    await db.delete('user_login');
    await db.delete('shifts');
  }
}
