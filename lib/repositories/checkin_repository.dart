import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/constants.dart';
import '../utils/logger.dart';

class CheckInRepository {
  Map<String, dynamic>? currentLogin;

  Future<Map<String, dynamic>> validatePin({
    required String pin,
    required String token,
  }) async {
    final url = Uri.parse(AppConstants.empOrderPinValidationEndpoint);

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final body = jsonEncode({'emp_order_pin': pin});
    final response = await http.post(url, headers: headers, body: body);

    AppLogger.debug('Login API Raw Response: ${response.body}');

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);

      if (result['success'] == true && result['data'] != null) {
        final data = result['data'];

        currentLogin = {
          "token": token,
          "captainId": data['id'] ?? 0,
          "captainName": data['name'] ?? "",
          "restaurantId": data['restaurant_id'] ?? 0,
          "zoneId": data['zone_id'] ?? 0,
          "role": data['role'] ?? "",
          "permissions": data['permissions'] ?? {},
        };

        // ✅ Save to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('login', jsonEncode(currentLogin));

        AppLogger.debug("✅ Parsed login saved: $currentLogin");
        return currentLogin!;
      }

      throw Exception("Invalid PIN or missing data in response");
    } else {
      throw Exception('Server error: ${response.statusCode}');
    }
  }

  /// Helper to get stored login from memory or SharedPreferences
  Future<Map<String, dynamic>?> getSavedLogin() async {
    if (currentLogin != null) return currentLogin;

    final prefs = await SharedPreferences.getInstance();
    final loginString = prefs.getString('login');
    if (loginString == null) return null;

    currentLogin = Map<String, dynamic>.from(jsonDecode(loginString));
    return currentLogin;
  }

  /// Optional: clear login
  Future<void> logout() async {
    currentLogin = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('login');
  }
}
