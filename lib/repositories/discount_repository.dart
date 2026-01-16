import 'dart:convert';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/payment/discount_model.dart';

class DiscountReasonRepository {
  final String baseUrl =
      'https://merchantrestaurant.alektasolutions.com/wp-json/pinaka-restaurant-pos/v1/orders/discount-reasons';

  /// ✅ Single source of truth
  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      throw Exception("JWT token missing");
    }

    return token.startsWith('Bearer ')
        ? token.substring(7)
        : token;
  }

  Future<DiscountReasonResponse> fetchDiscountReasons() async {
    if (kDebugMode) {
      print('📤 [DiscountReasonRepository] API CALL STARTED');
      print('➡️ URL: $baseUrl');
    }

    final token = await _getToken();

    if (kDebugMode) {
      print("🔐 CLEAN TOKEN => $token");
      print("🔐 HEADER     => Bearer $token");
    }

    final response = await http.get(
      Uri.parse(baseUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    if (kDebugMode) {
      print('⬅️ STATUS CODE: ${response.statusCode}');
      print('⬅️ RESPONSE BODY: ${response.body}');
    }

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      return DiscountReasonResponse.fromJson(decoded);
    } else {
      throw Exception(
        'Failed to load discount reasons (${response.statusCode})',
      );
    }
  }
}
// repositories/discount_repository.dart



class AddDiscountRepository {
  final String baseUrl =
      "https://merchantrestaurant.alektasolutions.com/wp-json/pinaka-restaurant-pos/v1";

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      throw Exception("JWT token missing");
    }

    return token.startsWith('Bearer ')
        ? token.substring(7)
        : token;
  }

  Future<AddDiscountResponse> addDiscount({
    required AddDiscountRequest request,
  }) async {
    final token = await _getToken(); // ✅ SINGLE SOURCE

    final url = "$baseUrl/orders/add-discount";

    print('➡️ [ADD DISCOUNT API]');
    print('➡️ URL: $url');
    print('➡️ REQUEST BODY: ${jsonEncode(request.toJson())}');

    final response = await http.post(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(request.toJson()),
    );

    print('⬅️ STATUS CODE: ${response.statusCode}');
    print('⬅️ RESPONSE BODY: ${response.body}');

    if (response.statusCode == 200) {
      return AddDiscountResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Failed to apply discount: ${response.body}");
    }
  }
}
