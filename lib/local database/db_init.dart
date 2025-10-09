import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseInitializer {
  Future<Database> initDatabase() async {
    final path = join(await getDatabasesPath(), 'tables.db');

    return await openDatabase(
      path,
      version: 11, // ✅ bump version for new columns
      onCreate: (db, version) async {
        // ✅ Tables table
        await db.execute('''
          CREATE TABLE tables(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            tableName TEXT,
            capacity INTEGER,
            shape TEXT,
            areaName TEXT,
            posX REAL,
            posY REAL,
            rotation REAL DEFAULT 0.0,
            pin TEXT,
            table_id INTEGER,
            zone_id INTEGER,
            restaurant_id INTEGER
          )
        ''');

        // ✅ Areas table
        await db.execute('''
          CREATE TABLE areas(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            zoneId INTEGER,
            areaName TEXT,
            pin TEXT,
            UNIQUE(areaName, pin)
          )
        ''');

        // ✅ User login table (latest structure)
        await db.execute('''
          CREATE TABLE user_login (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            pin TEXT NOT NULL,
            token TEXT NOT NULL,
            restaurant_id TEXT,
            restaurant_name TEXT,
            user_id TEXT,
            user_role TEXT,
            display_name TEXT,
            role TEXT
          )
        ''');

        // ✅ Shifts table
        await db.execute('''
          CREATE TABLE shifts (
            shift_id INTEGER PRIMARY KEY,
            shift_date TEXT UNIQUE
          )
        ''');
      },

      // ✅ Migration logic for existing users
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
        if (oldVersion < 9) {
          await db.execute('''
            CREATE TABLE shifts (
              shift_id INTEGER PRIMARY KEY,
              shift_date TEXT UNIQUE
            )
          ''');
        }
        if (oldVersion < 10) {
          await db.execute('ALTER TABLE user_login ADD COLUMN user_id TEXT');
        }
        if (oldVersion < 11) {
          // ✅ add missing columns for display_name, user_role, and role
          await db.execute('ALTER TABLE user_login ADD COLUMN user_role TEXT');
          await db.execute('ALTER TABLE user_login ADD COLUMN display_name TEXT');
          await db.execute('ALTER TABLE user_login ADD COLUMN role TEXT');
        }
      },
    );
  }
}
