import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/constants.dart';
import '../local database/login_dao.dart';
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

    AppLogger.debug('Login API Response: ${response.body}');

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200 && responseData['success'] == true) {
      final data = responseData['data'];

      String token = data['token'];
      String restaurantId = data['restaurant_id'].toString();
      String restaurantName = data['restaurant_name'].toString();
      Map<String, dynamic> permissions = Map<String, dynamic>.from(data['permissions'] ?? {});

      await loginDao.insertLogin(pin, token, restaurantId, restaurantName);

      AppLogger.info('Login successful. Token and restaurant data saved.');
      AppLogger.info('Restaurant ID: $restaurantId');
      AppLogger.info('Restaurant Name: $restaurantName');

      return {
        'success': true,
        'token': token,
        'restaurant_id': restaurantId,
        'restaurant_name': restaurantName,
        'permissions': permissions,
      };
    } else {
      String errorMessage = responseData['message'] ?? "Login failed";
      AppLogger.warning('Login failed: $errorMessage');
      return {'success': false, 'message': errorMessage};
    }
  }
  Future<bool> logout(String token) async {
    final url = Uri.parse(AppConstants.logoutEndpoint);

    try {
      final response = await http.post(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      AppLogger.debug("Logout API Response: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200) {
        await loginDao.clearLogin();

        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();

        AppLogger.info('Logout successful. Local data cleared.');
        return true;
      } else {
        AppLogger.warning('Logout failed with status: ${response.statusCode}');
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
