import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

class LoginDao {
  /// Insert or update login details
  Future<void> insertLogin(
      String pin,
      String token,
      String restaurantId,
      String restaurantName, {
        required String userId,   // 👈 new field (captain/user ID)
        String? userRole,         // 👈 optional
      }) async {
    final db = await DatabaseHelper().database;
    await db.insert(
      'user_login',
      {
        'pin': pin,
        'token': token,
        'restaurant_id': restaurantId,
        'restaurant_name': restaurantName,
        'user_id': userId,     // 👈 save captain/user ID
        'user_role': userRole, // 👈 save user role (optional)
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    // print("✅ Login saved locally");
  }

  /// Get the first saved login
  Future<Map<String, dynamic>?> getLogin() async {
    final db = await DatabaseHelper().database;
    final result = await db.query('user_login', limit: 1);
    return result.isNotEmpty ? result.first : null;
  }

  /// Clear saved login
  Future<void> clearLogin() async {
    final db = await DatabaseHelper().database;
    await db.delete('user_login');
  }
}
