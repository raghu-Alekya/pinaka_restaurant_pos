import 'database_helper.dart';

class AreaDao {
  Future<void> insertArea(String areaName, String pin, int zoneId) async {
    final db = await DatabaseHelper().database;

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
      print('Area "$areaName" with PIN "$pin" already exists. Skipping insert.');
    }
  }

  Future<void> deleteArea(String areaName) async {
    final db = await DatabaseHelper().database;
    await db.delete('areas', where: 'areaName = ?', whereArgs: [areaName]);
  }

  Future<List<String>> getAreasByPin(String pin) async {
    final db = await DatabaseHelper().database;
    final maps = await db.query('areas', where: 'pin = ?', whereArgs: [pin]);
    return maps.map((e) => e['areaName'] as String).toList();
  }

  Future<void> updateAreaName(String oldName, String newName) async {
    final db = await DatabaseHelper().database;
    await db.update('areas', {'areaName': newName}, where: 'areaName = ?', whereArgs: [oldName]);
    await db.update('tables', {'areaName': newName}, where: 'areaName = ?', whereArgs: [oldName]);
  }
}
