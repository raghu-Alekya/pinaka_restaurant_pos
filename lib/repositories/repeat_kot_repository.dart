import 'dart:convert';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/constants.dart';
import '../models/order/repeat_kot_model.dart';

class RepeatOrderRepository {

  RepeatOrderRepository();

  /// ✅ Always get token from storage
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

  Future<RepeatKotModel> repeatKotOrder({
    required int orderId,
    required int restaurantId,
    required int zoneId,
    required String token,
  }) async {

    final uri = Uri.parse(
      "${AppConstants.baseApiPath}/orders/repeat-kot-order",
    );

    final cleanToken = await _getToken();

    if (kDebugMode) {
      print("🔐 CLEAN TOKEN => $cleanToken");
      print("🔐 HEADER => Bearer $cleanToken");
      print("➡️ URL => $uri");
    }

    final response = await http.post(
      uri,
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        "Accept": "application/json",
        "Authorization": "Bearer $cleanToken",
      },
      body: jsonEncode({
        "order_id": orderId,
        "restaurant_id": restaurantId,
        "zone_id": zoneId,
      }),
    );

    if (response.statusCode == 200) {
      return RepeatKotModel.fromJson(
        jsonDecode(response.body),
      );
    }

    throw Exception(
      "Repeat KOT failed (${response.statusCode}): ${response.body}",
    );
  }
}