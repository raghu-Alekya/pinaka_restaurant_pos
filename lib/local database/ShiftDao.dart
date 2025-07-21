import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

class ShiftDao {
  Future<Database> get _db async => await DatabaseHelper().database;

  Future<void> saveShift(int shiftId, String shiftDate) async {
    final db = await _db;
    await db.insert('shifts', {
      'shift_id': shiftId,
      'shift_date': shiftDate,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<bool> isShiftCreatedForToday(String shiftDate) async {
    final db = await _db;
    final result = await db.query(
      'shifts',
      where: 'shift_date = ?',
      whereArgs: [shiftDate],
      limit: 1,
    );
    return result.isNotEmpty;
  }
}
