import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

import '../models/tip_model.dart';

class TipRepository {
  final String baseUrl =
      'https://merchantrestaurant.alektasolutions.com/wp-json/pinaka-restaurant-pos/v1/orders';

  Future<bool> addTip({
    required String token,
    required int orderId,
    required double amount,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/add-tip'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'order_id': orderId,
          'amount': amount,
        }),
      );

      print('Add Tip Status Code: ${response.statusCode}');
      print('Add Tip Response: ${response.body}');

      if (response.statusCode == 200) {
        return true;
      }

      return false;
    } catch (e) {
      print('Add Tip Error: $e');
      return false;
    }
  }
  Future<bool> removeTip({
    required String token,
    required int orderId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/remove-tip'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'order_id': orderId,
        }),
      );

      debugPrint('Remove Tip Status: ${response.statusCode}');
      debugPrint('Remove Tip Response: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Remove Tip Error: $e');
      return false;
    }
  }
}
// import 'dart:convert';
// import 'package:http/http.dart' as http;
//
// import '../../models/tips/tips_screen_model.dart';


class TipssummaryRepository {
  Future<TipsScreenModel?> getTips({
    required String token,
    required String tipDate,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://merchantrestaurant.alektasolutions.com/wp-json/pinaka-restaurant-pos/v1/kot/get-all-tip-orders?tip_date=$tipDate',
        ),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        return TipsScreenModel.fromJson(jsonData);
      }

      return null;
    } catch (e) {
      throw Exception('Failed to fetch tips: $e');
    }
  }
}