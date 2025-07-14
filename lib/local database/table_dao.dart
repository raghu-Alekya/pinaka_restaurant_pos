import 'database_helper.dart';

class TableDao {
  Future<int> insertTable(Map<String, dynamic> table) async {
    final db = await DatabaseHelper().database;
    final tableToInsert = {
      ...table,
      'zone_id': table['zone_id'],
      'restaurant_id': table['restaurant_id'],
    };
    return await db.insert('tables', tableToInsert);
  }

  Future<void> updateTable(int idOrServerId, Map<String, dynamic> table) async {
    final db = await DatabaseHelper().database;

    final updateData = {
      ...table,
      'zone_id': table['zone_id'],           // ✅ important
      'restaurant_id': table['restaurant_id'] // ✅ important
    };

    await db.update(
      'tables',
      updateData,
      where: 'id = ? OR table_id = ?',
      whereArgs: [idOrServerId, idOrServerId],
    );
  }


  Future<List<Map<String, dynamic>>> getTablesByTableId(int tableId) async {
    final db = await DatabaseHelper().database;
    return await db.query('tables', where: 'table_id = ?', whereArgs: [tableId]);
  }

  Future<Map<String, dynamic>?> getTableByServerId(int tableId) async {
    final db = await DatabaseHelper().database;
    final result = await db.query('tables', where: 'table_id = ?', whereArgs: [tableId]);
    return result.isNotEmpty ? result.first : null;
  }

  Future<void> deleteTableByServerId(int tableId) async {
    final db = await DatabaseHelper().database;
    await db.delete('tables', where: 'table_id = ?', whereArgs: [tableId]);
  }

  Future<void> deleteTableByLocalIdOrServerId(int idOrServerId) async {
    final db = await DatabaseHelper().database;
    await db.delete('tables', where: 'id = ? OR table_id = ?', whereArgs: [idOrServerId, idOrServerId]);
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
