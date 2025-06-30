import 'dart:convert';
import 'package:http/http.dart' as http;

import '../constants/constants.dart';
import '../utils/logger.dart';

class TableRepository {
  Future<Map<String, dynamic>?> createTable({
    required String token,
    required Map<String, dynamic> requestBody,
  }) async {
    final response = await http.post(
      Uri.parse(AppConstants.createTableEndpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(requestBody),
    );

    AppLogger.info('Create Table API Request Body: $requestBody');
    AppLogger.info('Create Table API Status: ${response.statusCode}');
    AppLogger.info('Create Table API Response: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Table creation failed: ${response.body}');
    }
  }
}


