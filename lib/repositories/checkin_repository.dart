// lib/repository/checkin_repository.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../constants/constants.dart';
import '../utils/logger.dart';

class CheckInRepository {
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
      return jsonDecode(response.body);
    } else {
      throw Exception('Server error: ${response.statusCode}');
    }
  }
}
