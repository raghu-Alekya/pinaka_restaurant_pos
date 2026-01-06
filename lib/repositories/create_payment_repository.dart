import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/payment/create_payment_model.dart';
import '../models/payment/payment_response_model.dart';

class CreatePaymentRepository {
  final String _baseUrl =
      'https://merchantrestaurant.alektasolutions.com/wp-json/pinaka-restaurant-pos/v1';

  Future<PaymentResponse> createPayment({
    required String token,
    required CreatePaymentRequest request,
  }) async {
    final url = Uri.parse('$_baseUrl/payments/create-payment');

    try {
      if (kDebugMode) {
        print("📤 PAYMENT REQUEST → ${url.toString()}");
        print("🔐 TOKEN: $token");
        print("📦 BODY: ${jsonEncode(request.toJson())}");
      }

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );

      if (kDebugMode) {
        print("📥 STATUS CODE: ${response.statusCode}");
        print("📥 RESPONSE BODY OF PAYMENT: ${response.body}");
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);
        return PaymentResponse.fromJson(decoded);
      } else {
        throw Exception(
          "Payment failed (${response.statusCode}): ${response.body}",
        );
      }
    } catch (e, stack) {
      debugPrint("❌ Payment API Error: $e");
      debugPrint("📍 StackTrace: $stack");
      rethrow;
    }
  }
}
