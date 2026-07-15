import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/constants.dart';
import '../models/payment/payment_summary_model.dart';
import '../services/api_exception.dart';

class PaymentRepository {
  PaymentRepository();

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      throw Exception("Session expired. Please login again.");
    }

    return token.startsWith("Bearer ")
        ? token.substring(7)
        : token;
  }

  Future<PaymentSummary> fetchOrderPaymentDetails({
    required String restaurantId,
    required int orderId,
    int? zoneId,
    required String orderType,
  }) async {
    const int maxRetries = 3;

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final String apiOrderType = orderType.toLowerCase().contains("take") ? "takeaway" : "Dine In";
        final queryParams = <String, String>{
          "order_id": orderId.toString(),
          "restaurant_id": restaurantId,
          "order_type": apiOrderType,
        };

        if (zoneId != null) {
          queryParams["zone_id"] = zoneId.toString();
        }

        final uri = Uri.parse(
          "${AppConstants.baseApiPath}/orders/get-order-items"
              "?${Uri(queryParameters: queryParams).query}",
        );

        final token = await _getToken();

        final response = await ApiExceptionHandler.get(
          uri,
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        );

        if (response.statusCode == 200) {
          debugPrint("PAYMENT SUMMARY RESPONSE:");
          debugPrint(response.body);

          return PaymentSummary.fromJson(
            jsonDecode(response.body),
          );
        }

        // Retry only for 5xx server errors
        if (response.statusCode >= 500 &&
            attempt < maxRetries) {
          await Future.delayed(const Duration(seconds: 2));
          continue;
        }

        throw Exception(
          ApiExceptionHandler.parseError(
            response,
            defaultMessage:
            "Unable to load payment summary.",
          ),
        );
      } catch (e) {
        // Retry for network errors
        if (attempt < maxRetries &&
            (e.toString().contains("Unable to connect") ||
                e.toString().contains("Request timed out"))) {
          await Future.delayed(const Duration(seconds: 2));
          continue;
        }

        if (e is Exception) {
          rethrow;
        }

        throw Exception(
          "Unable to load payment summary. Please try again later.",
        );
      }
    }

    throw Exception(
      "Unable to load payment summary. Please try again later.",
    );
  }
}