import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';
import '../utils/logger.dart';

class AreaDao {
  /// Exposes the raw database (used for fallback in ZoneRepository)
  Future<Database> getDb() async => await DatabaseHelper().database;

  /// Inserts area if not already existing for the same areaName + pin
  Future<void> insertArea(String areaName, String pin, int zoneId) async {
    final db = await getDb();

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
      AppLogger.info('Inserted area "$areaName" for PIN "$pin" with zoneId $zoneId');
    } else {
      AppLogger.warning('Area "$areaName" with PIN "$pin" already exists. Skipping insert.');
    }
  }

  /// Deletes area by name
  Future<void> deleteArea(String areaName) async {
    final db = await getDb();
    await db.delete('areas', where: 'areaName = ?', whereArgs: [areaName]);
    AppLogger.info('Deleted area "$areaName" from areas table');
  }

  /// Gets all area names by PIN
  Future<List<String>> getAreasByPin(String pin) async {
    final db = await getDb();
    final maps = await db.query('areas', where: 'pin = ?', whereArgs: [pin]);
    return maps.map((e) => e['areaName'] as String).toList();
  }

  /// Updates area name in both areas and tables tables
  Future<void> updateAreaName(String oldName, String newName) async {
    final db = await getDb();
    await db.update('areas', {'areaName': newName}, where: 'areaName = ?', whereArgs: [oldName]);
    await db.update('tables', {'areaName': newName}, where: 'areaName = ?', whereArgs: [oldName]);
    AppLogger.info('Updated area name from "$oldName" to "$newName" in DB');
  }

  /// Optional: Get zoneId by areaName + pin
  Future<int?> getZoneIdByAreaAndPin(String areaName, String pin) async {
    final db = await getDb();
    final result = await db.query(
      'areas',
      where: 'areaName = ? AND pin = ?',
      whereArgs: [areaName, pin],
    );

    if (result.isNotEmpty) {
      return result.first['zoneId'] as int;
    }
    return null;
  }
}