import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/constants.dart';
import '../models/Product_Status_model.dart';

class ProductStatusRepository {
  final String token;

  ProductStatusRepository({
    required this.token,
  });

  Future<Map<String, dynamic>> updateProductStatus(
      ProductStatusRequest request,
      ) async {
    final url = Uri.parse(
      AppConstants.updateProductStatusEndpoint,
    );

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      if (response.body.isEmpty) {
        return {
          'success': true,
        };
      }

      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      return {
        'success': true,
        'data': decoded,
      };
    }

    String message = 'Failed to update product status';

    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map &&
          decoded['message'] != null) {
        message = decoded['message'].toString();
      }
    } catch (_) {
      // Ignore JSON parsing error
    }

    throw Exception(
      '$message (${response.statusCode})',
    );
  }
}