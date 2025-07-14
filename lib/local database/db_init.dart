import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseInitializer {
  Future<Database> initDatabase() async {
    final path = join(await getDatabasesPath(), 'tables.db');

    return await openDatabase(
      path,
      version: 8, // ✅ bump version
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
            pin TEXT,
            table_id INTEGER,
            zone_id INTEGER,
            restaurant_id INTEGER
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
            token TEXT NOT NULL,
            restaurant_id TEXT,
            restaurant_name TEXT
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
              token TEXT NOT NULL,
              restaurant_id TEXT,
              restaurant_name TEXT
            )
          ''');
        }
        if (oldVersion < 6) {
          await db.execute('ALTER TABLE areas ADD COLUMN zoneId INTEGER');
        }
        if (oldVersion < 7) {
          await db.execute('ALTER TABLE tables ADD COLUMN table_id INTEGER');
        }
        if (oldVersion < 8) {
          await db.execute('ALTER TABLE tables ADD COLUMN zone_id INTEGER');
          await db.execute('ALTER TABLE tables ADD COLUMN restaurant_id INTEGER');
        }
      },
    );
  }
}