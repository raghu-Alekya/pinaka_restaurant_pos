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
    print("AUTH URL => $url");
    AppLogger.info('Sending login request for PIN: $pin');


    var request = http.MultipartRequest('POST', url);
    request.fields['emp_login_pin'] = pin.trim();

    print("REQUEST FIELDS => ${request.fields}");

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    print("EMPLOYEE LOGIN STATUS => ${response.statusCode}");
    print("EMPLOYEE LOGIN RESPONSE => ${response.body}");


    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200 && responseData['success'] == true) {
      final data = responseData['data'];
      print("FULL DATA => $data");

      final String token = data['token'];
      final String restaurantId = data['restaurant_id'].toString();
      final String restaurantName = data['restaurant_name'].toString();
      print("RESTAURANT ID FROM API => $restaurantId");
      final Map<String, dynamic> permissions =
      Map<String, dynamic>.from(data['permissions'] ?? {});
      final prefs = await SharedPreferences.getInstance();
      print(
        "USING RESTAURANT ID => ${prefs.getString('restaurant_id')}",
      );

      print(
        "USING BASE URL => ${AppConstants.baseDomain}",
      );

      await prefs.setString('token', token);
      await prefs.setString('restaurant_id', restaurantId);
      await prefs.setString('restaurant_name', restaurantName);
      print(
        "Saved Restaurant ID => ${prefs.getString('restaurant_id')}",
      );

      print(
        "Base URL => ${AppConstants.baseDomain}",
      );

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
