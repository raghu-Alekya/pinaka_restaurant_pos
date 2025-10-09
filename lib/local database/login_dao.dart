import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

class LoginDao {
  /// Insert or update login details
  Future<void> insertLogin(
      String pin,
      String token,
      String restaurantId,
      String restaurantName, {
        required String userId,
        String? userRole,
        required String displayName,
        required String role,
      }) async {
    final db = await DatabaseHelper().database;
    await db.insert(
      'user_login',
      {
        'pin': pin,
        'token': token,
        'restaurant_id': restaurantId,
        'restaurant_name': restaurantName,
        'user_id': userId,
        'user_role': userRole,
        'display_name': displayName,
        'role': role,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// ✅ Get the latest login (most recent check-in)
  Future<Map<String, dynamic>?> getLatestLogin() async {
    final db = await DatabaseHelper().database;
    final result = await db.query(
      'user_login',
      orderBy: 'rowid DESC', // latest inserted first
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  /// Clear saved login
  Future<void> clearLogin() async {
    final db = await DatabaseHelper().database;
    await db.delete('user_login');
  }
}
