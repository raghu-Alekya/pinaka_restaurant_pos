// lib/repositories/auth_repository.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../constants/constants.dart';
import '../helpers/DatabaseHelper.dart';
import '../utils/logger.dart';

class AuthRepository {
  final String baseUrl = AppConstants.authTokenEndpoint;

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
      String token = responseData['data']['token'];
      await DatabaseHelper().insertLogin(pin, token);
      AppLogger.info('Login successful. Token saved.');
      return {'success': true, 'token': token};
    } else {
      // Even if the status is not 200, try to show the error message from API response
      String errorMessage = responseData['message'] ?? "Login failed";
      AppLogger.warning('Login failed: $errorMessage');
      return {'success': false, 'message': errorMessage};
    }
  }


  Future<Map<String, dynamic>?> getSavedLogin() async {
    return await DatabaseHelper().getLogin();
  }

  Future<void> logout() async {
    await DatabaseHelper().clearLogin();
    AppLogger.info('User logged out. Local login cleared.');
  }
}
