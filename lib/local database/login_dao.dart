import 'package:sqflite/sqflite.dart';

import 'database_helper.dart';

class LoginDao {
  Future<void> insertLogin(String pin, String token, String restaurantId, String restaurantName) async {
    final db = await DatabaseHelper().database;
    await db.insert(
      'user_login',
      {
        'pin': pin,
        'token': token,
        'restaurant_id': restaurantId,
        'restaurant_name': restaurantName,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getLogin() async {
    final db = await DatabaseHelper().database;
    final result = await db.query('user_login', limit: 1);
    return result.isNotEmpty ? result.first : null;
  }

  Future<void> clearLogin() async {
    final db = await DatabaseHelper().database;
    await db.delete('user_login');
  }
}
