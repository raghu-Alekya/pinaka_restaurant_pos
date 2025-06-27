import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseInitializer {
  Future<Database> initDatabase() async {
    final path = join(await getDatabasesPath(), 'tables.db');

    return await openDatabase(
      path,
      version: 6,
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
      },
    );
  }
}
