import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("token", token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  static Future<void> saveRestaurantId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("restaurant_id", id);
  }

  static Future<int> getRestaurantId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt("restaurant_id") ?? 0;
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}