import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../constants/constants.dart';
import '../models/payment/create_payment_model.dart';
import '../models/payment/payment_response_model.dart';
import '../services/api_exception.dart';

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

      final response = await ApiExceptionHandler.post(
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

      if (response.statusCode == 200 || response.statusCode == 201) {
        return PaymentResponse.fromJson(
          jsonDecode(response.body),
        );
      }

      throw Exception(
        ApiExceptionHandler.parseError(
          response,
          defaultMessage: "Unable to process payment.",
        ),
      );
    } catch (e, stack) {
      debugPrint("❌ Payment API Error: $e");
      debugPrint("$stack");

      if (e is Exception) rethrow;

      throw Exception("Unable to process payment.");
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
        print("📦 BODY: ${jsonEncode(body)}");
      }

      final response = await ApiExceptionHandler.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (kDebugMode) {
        print("📥 STATUS CODE: ${response.statusCode}");
        print("📥 RESPONSE BODY: ${response.body}");
      }

      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return decoded["message"] ??
            "Payment voided successfully";
      }

      throw Exception(
        ApiExceptionHandler.parseError(
          response,
          defaultMessage: "Unable to void payment.",
        ),
      );
    } catch (e, stack) {
      debugPrint("❌ Void Payment API Error: $e");
      debugPrint("$stack");

      if (e is Exception) rethrow;

      throw Exception("Unable to void payment.");
    }
  }
}