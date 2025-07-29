import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/UserPermissions.dart';

class SessionManager {
  static const _permissionsKey = 'user_permissions';

  static Future<void> savePermissions(UserPermissions permissions) async {
    final prefs = await SharedPreferences.getInstance();
    String jsonStr = jsonEncode(permissions.toJson());
    await prefs.setString(_permissionsKey, jsonStr);
  }

  static Future<UserPermissions?> loadPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_permissionsKey);
    if (jsonStr == null) return null;

    final jsonMap = jsonDecode(jsonStr);
    return UserPermissions.fromJson(jsonMap);
  }

  static Future<void> clearPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_permissionsKey);
  }
}
