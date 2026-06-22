import 'dart:convert';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/payment/payment_summary_model.dart';

class PaymentRepository {
  final String baseUrl;

  PaymentRepository({required this.baseUrl});

  /// ✅ Always get token from storage
  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      throw Exception("JWT token missing");
    }

    // ✅ remove "Bearer " if already stored
    return token.startsWith('Bearer ')
        ? token.substring(7)
        : token;
  }

  Future<PaymentSummary> fetchOrderPaymentDetails({
    required String restaurantId,
    required int orderId,
    int? zoneId,
    required String orderType,
  }) async {
    final queryParams = <String, String>{
      "order_id": orderId.toString(),
      "restaurant_id": restaurantId.toString(),
      "order_type": "",
    };

    if (zoneId != null) {
      queryParams["zone_id"] = zoneId.toString();
    }

    final uri = Uri.parse(
      "$baseUrl/wp-json/pinaka-restaurant-pos/v1/orders/get-order-items"
          "?${Uri(queryParameters: queryParams).query}",
    );

    final token = await _getToken();

    if (kDebugMode) {
      debugPrint("➡️ PAYMENT API URL: $uri");
      debugPrint("🔐 CLEAN TOKEN => $token");
      debugPrint("🔐 HEADER     => Bearer $token");
    }

    final response = await http.get(
      uri,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json; charset=utf-8",
        "Accept": "application/json",
      },
    );

    if (kDebugMode) {
      debugPrint("⬅️ STATUS CODE: ${response.statusCode}");
      debugPrint("⬅️ RESPONSE BODY: ${response.body}");
    }

    if (response.statusCode == 200) {
      return PaymentSummary.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Payment summary failed (${response.statusCode}): ${response.body}");
    }
  }
}
