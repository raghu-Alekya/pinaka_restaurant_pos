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

  // ==========================================================
  // STORE ID
  // ==========================================================

  static Future<void> saveStoreId(String storeId) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      "store_id",
      storeId,
    );

    print("✅ Store ID saved: $storeId");
  }

  static Future<String> getStoreId() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString("store_id") ?? '';
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}