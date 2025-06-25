// lib/database/database_helper.dart
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
      version: 6, // ⬅️ Updated version
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
            zoneId INTEGER,
            areaName TEXT,
            pin TEXT,
            UNIQUE(areaName, pin)
          )
        ''');

        await db.execute('''
          CREATE TABLE user_login (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            pin TEXT NOT NULL,
            token TEXT NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE tables ADD COLUMN pin TEXT');
        }
        if (oldVersion < 4) {
          await db.execute('DROP TABLE IF EXISTS areas');
          await db.execute('''
            CREATE TABLE areas(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              zoneId INTEGER,
              areaName TEXT,
              pin TEXT,
              UNIQUE(areaName, pin)
            )
          ''');
        }
        if (oldVersion < 5) {
          await db.execute('''
            CREATE TABLE user_login (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              pin TEXT NOT NULL,
              token TEXT NOT NULL
            )
          ''');
        }
        if (oldVersion < 6) {
          await db.execute('ALTER TABLE areas ADD COLUMN zoneId INTEGER');
        }
      },
    );
  }

  // ================= Login Table Functions =================

  Future<void> insertLogin(String pin, String token) async {
    final db = await database;
    await db.insert(
      'user_login',
      {'pin': pin, 'token': token},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getLogin() async {
    final db = await database;
    final result = await db.query('user_login', limit: 1);
    return result.isNotEmpty ? result.first : null;
  }

  Future<void> clearLogin() async {
    final db = await database;
    await db.delete('user_login');
  }

  Future<void> updateAreaNameById(int zoneId, String newAreaName) async {
    final db = await database;
    await db.update(
      'areas',
      {'area_name': newAreaName},
      where: 'zone_id = ?',
      whereArgs: [zoneId],
    );
  }


  // ================= Area Table Functions =================

  Future<void> insertArea(String areaName, String pin) async {
    final db = await database;
    await db.insert('areas', {'areaName': areaName, 'pin': pin});
  }

  Future<void> insertAreaWithZoneIdIfNotExists(String areaName, String pin, int zoneId) async {
    final db = await database;

    final existing = await db.query(
      'areas',
      where: 'areaName = ? AND pin = ?',
      whereArgs: [areaName, pin],
    );

    if (existing.isEmpty) {
      await db.insert('areas', {
        'areaName': areaName,
        'pin': pin,
        'zoneId': zoneId,
      });
    } else {
      // Optionally log or handle duplicate gracefully
      print('Area "$areaName" with PIN "$pin" already exists in DB. Skipping insert.');
    }
  }


  Future<void> deleteArea(String areaName) async {
    final db = await database;
    await db.delete('areas', where: 'areaName = ?', whereArgs: [areaName]);
  }

  Future<List<String>> getAllAreas() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('areas');
    return maps.map((map) => map['areaName'] as String).toList();
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

  Future<int?> getZoneIdByAreaName(String areaName) async {
    final db = await database;
    final result = await db.query(
      'areas',
      columns: ['zoneId'],
      where: 'areaName = ?',
      whereArgs: [areaName],
      limit: 1,
    );
    if (result.isNotEmpty) {
      return result.first['zoneId'] as int?;
    }
    return null;
  }

  Future<void> updateAreaName(String oldName, String newName) async {
    final db = await database;

    await db.update(
      'areas',
      {'areaName': newName},
      where: 'areaName = ?',
      whereArgs: [oldName],
    );

    await db.update(
      'tables',
      {'areaName': newName},
      where: 'areaName = ?',
      whereArgs: [oldName],
    );
  }

  // ================= Table Functions =================

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

  Future<void> deleteTablesByArea(String areaName) async {
    final db = await database;
    await db.delete('tables', where: 'areaName = ?', whereArgs: [areaName]);
  }

  Future<void> deleteTableByNameAndArea(String tableName, String areaName) async {
    final db = await database;
    await db.delete('tables', where: 'tableName = ? AND areaName = ?', whereArgs: [tableName, areaName]);
  }

  Future<List<Map<String, dynamic>>> getAllTables() async {
    final db = await database;
    return await db.query('tables');
  }

  Future<List<Map<String, dynamic>>> getTablesByManagerPin(String managerPin) async {
    final db = await database;
    return await db.query('tables', where: 'pin = ?', whereArgs: [managerPin]);
  }
}