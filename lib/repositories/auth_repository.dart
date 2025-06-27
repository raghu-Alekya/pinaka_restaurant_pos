// lib/repositories/auth_repository.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

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

      await loginDao.insertLogin(pin, token, restaurantId, restaurantName);

      AppLogger.info('Login successful. Token and restaurant data saved.');
      AppLogger.info('Restaurant ID: $restaurantId');
      AppLogger.info('Restaurant Name: $restaurantName');

      return {
        'success': true,
        'token': token,
        'restaurant_id': restaurantId,
        'restaurant_name': restaurantName
      };
    } else {
      String errorMessage = responseData['message'] ?? "Login failed";
      AppLogger.warning('Login failed: $errorMessage');
      return {'success': false, 'message': errorMessage};
    }
  }

  Future<Map<String, dynamic>?> getSavedLogin() async {
    return await loginDao.getLogin();
  }

  Future<void> logout() async {
    await loginDao.clearLogin();
    AppLogger.info('User logged out. Local login cleared.');
  }
}
