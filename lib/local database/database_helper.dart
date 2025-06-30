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
}
