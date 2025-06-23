import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'tables.db');
    return await openDatabase(
      path,
      version: 4,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE tables(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            tableName TEXT,
            capacity INTEGER,
            shape TEXT,
            areaName TEXT,
            posX REAL,
            posY REAL,
            guestCount INTEGER,
            rotation REAL DEFAULT 0.0,
            pin TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE areas(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            areaName TEXT,
            pin TEXT,
            UNIQUE(areaName, pin)
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 4) {
          await db.execute('DROP TABLE IF EXISTS areas');
          await db.execute('''
            CREATE TABLE areas(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              areaName TEXT,
              pin TEXT,
              UNIQUE(areaName, pin)
            )
          ''');
        }

        if (oldVersion < 3) {
          await db.execute('ALTER TABLE tables ADD COLUMN pin TEXT');
        }
      },
    );
  }

  Future<void> insertArea(String areaName, String pin) async {
    final db = await database;
    await db.insert('areas', {'areaName': areaName, 'pin': pin});
  }

  Future<void> deleteTablesByArea(String areaName) async {
    final db = await database;
    await db.delete('tables', where: 'areaName = ?', whereArgs: [areaName]);
  }

  Future<void> deleteTableByNameAndArea(String tableName, String areaName) async {
    final db = await database;
    await db.delete('tables', where: 'tableName = ? AND areaName = ?', whereArgs: [tableName, areaName]);
  }

  Future<List<String>> getAllAreas() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('areas');
    return maps.map((map) => map['areaName'] as String).toList();
  }

  Future<void> deleteArea(String areaName) async {
    final db = await database;
    await db.delete('areas', where: 'areaName = ?', whereArgs: [areaName]);
  }

  Future<int> insertTable(Map<String, dynamic> table) async {
    final db = await database;
    return await db.insert('tables', table);
  }

  Future<void> updateTable(int id, Map<String, dynamic> table) async {
    final db = await database;
    await db.update('tables', table, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteTable(int id) async {
    final db = await database;
    await db.delete('tables', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getAllTables() async {
    final db = await database;
    return await db.query('tables');
  }

  Future<List<Map<String, dynamic>>> getTablesByManagerPin(String managerPin) async {
    final db = await database;
    return await db.query('tables', where: 'pin = ?', whereArgs: [managerPin]);
  }

  Future<List<String>> getAreasByPin(String pin) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'areas',
      where: 'pin = ?',
      whereArgs: [pin],
    );
    return maps.map((map) => map['areaName'] as String).toList();
  }
}