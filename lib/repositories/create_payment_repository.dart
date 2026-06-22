import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../constants/constants.dart';
import '../models/payment/create_payment_model.dart';
import '../models/payment/payment_response_model.dart';

class CreatePaymentRepository {

  Future<PaymentResponse> createPayment({
    required String token,
    required CreatePaymentRequest request,
  }) async {

    final url = Uri.parse(
      '${AppConstants.baseApiPath}/payments/create-payment',
    );

    try {
      if (kDebugMode) {
        print("📤 PAYMENT REQUEST → $url");
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
        print("📥 RESPONSE BODY: ${response.body}");
      }

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        final decoded = jsonDecode(response.body);
        return PaymentResponse.fromJson(decoded);
      }

      throw Exception(
        "Payment failed (${response.statusCode}): ${response.body}",
      );
    } catch (e, stack) {
      debugPrint("❌ Payment API Error: $e");
      debugPrint("📍 StackTrace: $stack");
      rethrow;
    }
  }

  Future<String> voidPayment({
    required String token,
    required int paymentId,
    required int orderId,
  }) async {

    final url = Uri.parse(
      '${AppConstants.baseApiPath}/payments/void-payment',
    );

    try {
      final body = {
        "payment_id": paymentId,
        "order_id": orderId,
      };

      if (kDebugMode) {
        print("📤 VOID PAYMENT REQUEST → $url");
        print("🔐 TOKEN: $token");
        print("📦 BODY: ${jsonEncode(body)}");
      }

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (kDebugMode) {
        print("📥 VOID STATUS CODE: ${response.statusCode}");
        print("📥 VOID RESPONSE BODY: ${response.body}");
      }

      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        return (decoded["message"] ??
            "Payment voided successfully")
            .toString();
      }

      throw Exception(
        "Void payment failed (${response.statusCode}): ${decoded["message"] ?? response.body}",
      );
    } catch (e, stack) {
      debugPrint("❌ Void Payment API Error: $e");
      debugPrint("📍 StackTrace: $stack");
      rethrow;
    }
  }
}