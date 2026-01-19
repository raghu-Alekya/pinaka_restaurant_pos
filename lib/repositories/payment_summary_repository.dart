import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import '../models/payment/payment_summary_model.dart';
// import '../models/payment_summary_model.dart';

class PaymentRepository {
  final String baseUrl;
  final String token;

  PaymentRepository({
    required this.baseUrl,
    required this.token,
  });

  Future<PaymentSummary> fetchOrderPaymentDetails({
    required String restaurantId,
    required int orderId,
    int? zoneId,
    required String orderType,
  }) async {
    final queryParams = <String, String>{
      "order_id": orderId.toString(),
      "restaurant_id": restaurantId.toString(),
      "order_type": orderType, // ✅ use dynamic
    };

    // ✅ only add zone_id if not null
    if (zoneId != null) {
      queryParams["zone_id"] = zoneId.toString();
    }

    final uri = Uri.https(
      "merchantrestaurant.alektasolutions.com",
      "/wp-json/pinaka-restaurant-pos/v1/orders/get-order-items",
      queryParams,
    );

    debugPrint("➡️ PAYMENT API URL: $uri");
    debugPrint("➡️ TOKEN: $token");
    debugPrint("➡️ ORDER ID: $orderId");

    final response = await http.get(
      uri,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    debugPrint("⬅️ STATUS CODE: ${response.statusCode}");
    debugPrint("⬅️ RESPONSE BODY: ${response.body}");

    if (response.statusCode == 200) {
      return PaymentSummary.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Payment summary failed: ${response.body}");
    }
  }
}

