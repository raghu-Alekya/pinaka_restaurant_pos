import 'dart:convert';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/order/repeat_kot_model.dart';

class RepeatOrderRepository {
  final String baseUrl;

  RepeatOrderRepository({required this.baseUrl});

  /// ✅ Always get token from storage
  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      throw Exception("JWT token missing");
    }

    // ✅ Safety cleanup (handles old stored Bearer tokens)
    return token.startsWith('Bearer ')
        ? token.substring(7)
        : token;
  }

  Future<RepeatKotModel> repeatKotOrder({
    required int orderId,
    required int restaurantId,
    required int zoneId,
    required String token,
  }) async {
    final uri = Uri.parse(
      "$baseUrl/wp-json/pinaka-restaurant-pos/v1/orders/repeat-kot-order",
    );

    final token = await _getToken(); // 🔥 CORRECT

    if (kDebugMode) {
      print("🔐 CLEAN TOKEN => $token");
      print("🔐 HEADER     => Bearer $token");
    }

    final response = await http.post(
      uri,
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "order_id": orderId,
        "restaurant_id": restaurantId,
        "zone_id": zoneId,
      }),
    );

    if (response.statusCode == 200) {
      return RepeatKotModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(
        "Repeat KOT failed (${response.statusCode}): ${response.body}",
      );
    }
  }
}
