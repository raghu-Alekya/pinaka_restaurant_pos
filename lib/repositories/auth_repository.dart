import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/constants.dart';
import '../local database/login_dao.dart';
import '../utils/SessionManager.dart';
import '../utils/logger.dart';

class AuthRepository {
  final String baseUrl = AppConstants.authTokenEndpoint;
  final loginDao = LoginDao();

  Future<Map<String, dynamic>> login(String pin) async {
    final url = Uri.parse(baseUrl);
    AppLogger.info('Sending login request for PIN: $pin');

    var request = http.MultipartRequest('POST', url);
    request.fields['emp_login_pin'] = pin.trim();

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200 && responseData['success'] == true) {
      final data = responseData['data'];

      final String token = data['token'];
      final String restaurantId = data['restaurant_id'].toString();
      final String restaurantName = data['restaurant_name'].toString();
      final Map<String, dynamic> permissions =
      Map<String, dynamic>.from(data['permissions'] ?? {});

      // 🔥🔥🔥 THIS IS MANDATORY 🔥🔥🔥
      await SessionManager.saveToken(token);

      // Optional (SQLite)
      await loginDao.insertLogin(pin, token, restaurantId, restaurantName);

      AppLogger.info('Login successful. Token saved.');

      return {
        'success': true,
        'token': token,
        'restaurant_id': restaurantId,
        'restaurant_name': restaurantName,
        'permissions': permissions,
      };
    } else {
      return {
        'success': false,
        'message': responseData['message'] ?? "Login failed",
      };
    }
  }

  Future<bool> logout(String token) async {
    final url = Uri.parse(AppConstants.logoutEndpoint);

    try {
      final response = await http.post(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        await loginDao.clearLogin();

        final prefs = await SharedPreferences.getInstance();

        // ✅ REMOVE ONLY WHAT YOU NEED
        await prefs.remove('auth_token');
        await prefs.remove('user_permissions');
        await prefs.remove('user_id');
        await prefs.remove('shift_id');

        AppLogger.info('Logout successful. Session cleared safely.');
        return true;
      } else {
        return false;
      }
    } catch (e) {
      AppLogger.error("Logout exception: $e");
      return false;
    }
  }

  Future<Map<String, dynamic>?> getSavedLogin() async {
    return await loginDao.getLogin();
  }
}
