import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/UserPermissions.dart';

class SessionManager {
  static const _permissionsKey = 'user_permissions';
  static const _userIdKey = 'user_id';
  static const _shiftIdKey = 'shift_id';
  static const String _tokenKey = 'auth_token';

  // -------- TOKEN --------
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    print("✅ TOKEN SAVED: $token");
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    print("🔍 FETCH TOKEN: $token");
    return token;
  }

  // -------- PERMISSIONS --------
  static Future<void> savePermissions(UserPermissions permissions) async {
    final prefs = await SharedPreferences.getInstance();

    // Save full permissions object
    await prefs.setString(_permissionsKey, jsonEncode(permissions.toJson()));

    // ✅ SAVE USER ID EXPLICITLY
    await prefs.setInt(_userIdKey, int.parse(permissions.userId));


    print("✅ Permissions saved");
    print("✅ User ID saved: ${permissions.userId}");
  }


  static Future<UserPermissions?> loadPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_permissionsKey);

    if (jsonStr == null) {
      print("⚠️ No permissions found in storage");
      return null;
    }

    print("✅ Permissions loaded: $jsonStr");
    return UserPermissions.fromJson(jsonDecode(jsonStr));
  }

  static Future<void> clearPermissions() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_permissionsKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_shiftIdKey);

    print("🧹 Permissions cleared");
  }

  // -------- USER ID --------
  static Future<void> saveUserId(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_userIdKey, userId);
    print("✅ USER ID SAVED: $userId");
  }

  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(_userIdKey);
    print("🔍 FETCH USER ID: $id");
    return id;
  }

  // -------- SHIFT ID --------
  static Future<void> saveShiftId(int shiftId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_shiftIdKey, shiftId);
    print("✅ SHIFT ID SAVED: $shiftId");
  }

  static Future<int?> getShiftId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(_shiftIdKey);
    print("🔍 FETCH SHIFT ID: $id");
    return id;
  }

  // -------- CLEAR SESSION --------
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    print("🧹 Session cleared");
  }
}
