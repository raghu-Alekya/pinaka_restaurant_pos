import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/UserPermissions.dart';

class SessionManager {
  static const _permissionsKey = 'user_permissions';
  static const _userIdKey = 'user_id';
  static const _shiftIdKey = 'shift_id';
  static const String _tokenKey = 'auth_token';
  static const _restaurantIdKey = 'restaurant_id';
  static const _currencySymbolKey = 'currency_symbol';

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
  // take away order flow orderId and restore it when the Take Away screen opens.
  static const String _activeTakeAwayOrderIdKey = 'active_takeaway_order_id';

  static Future<void> saveActiveTakeAwayOrderId(int orderId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_activeTakeAwayOrderIdKey, orderId);
  }

  static Future<int?> getActiveTakeAwayOrderId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_activeTakeAwayOrderIdKey);
  }

  static Future<void> clearActiveTakeAwayOrderId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeTakeAwayOrderIdKey);
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
  static Future<void> saveRestaurantId(
      String restaurantId,
      ) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _restaurantIdKey,
      restaurantId,
    );

    print(
      "✅ RESTAURANT ID SAVED: $restaurantId",
    );
  }

  static Future<String?> getRestaurantId() async {
    final prefs = await SharedPreferences.getInstance();

    final id = prefs.getString(
      _restaurantIdKey,
    );

    print(
      "🔍 FETCH RESTAURANT ID: $id",
    );

    return id;
  }

  // -------- CLEAR SESSION --------
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    print("🧹 Session cleared");
  }
  static Future<void> saveCurrencySymbol(String symbol) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencySymbolKey, symbol);

    print("✅ Currency Symbol Saved: $symbol");
  }
  static Future<String> getCurrencySymbol() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(_currencySymbolKey) ?? "₹";
  }
}
