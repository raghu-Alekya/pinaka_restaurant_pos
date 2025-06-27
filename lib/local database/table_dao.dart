import 'database_helper.dart';

class TableDao {
  Future<int> insertTable(Map<String, dynamic> table) async {
    final db = await DatabaseHelper().database;
    return await db.insert('tables', table);
  }

  Future<void> updateTable(int id, Map<String, dynamic> table) async {
    final db = await DatabaseHelper().database;
    await db.update('tables', table, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteTablesByArea(String areaName) async {
    final db = await DatabaseHelper().database;
    await db.delete('tables', where: 'areaName = ?', whereArgs: [areaName]);
  }

  Future<void> deleteTableByNameAndArea(String tableName, String areaName) async {
    final db = await DatabaseHelper().database;
    await db.delete('tables', where: 'tableName = ? AND areaName = ?', whereArgs: [tableName, areaName]);
  }

  Future<List<Map<String, dynamic>>> getTablesByManagerPin(String managerPin) async {
    final db = await DatabaseHelper().database;
    return await db.query('tables', where: 'pin = ?', whereArgs: [managerPin]);
  }
}
