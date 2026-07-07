import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class ApiExceptionHandler {
  static Future<http.Response> get(
      Uri url, {
        required Map<String, String> headers,
      }) async {
    try {
      return await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 30));
    } on SocketException {
      throw Exception(
        "Unable to connect to the server. Please check your internet connection.",
      );
    } on TimeoutException {
      throw Exception(
        "Request timed out. Please try again.",
      );
    } on http.ClientException {
      throw Exception(
        "Unable to connect to the server. Please try again later.",
      );
    }
  }
  static Future<http.StreamedResponse> multipart(
      http.MultipartRequest request,
      ) async {
    try {
      return await request
          .send()
          .timeout(const Duration(seconds: 30));
    } on SocketException {
      throw Exception(
        "Unable to connect to the server. Please check your internet connection.",
      );
    } on TimeoutException {
      throw Exception(
        "Request timed out. Please try again.",
      );
    } on http.ClientException {
      throw Exception(
        "Unable to connect to the server. Please try again later.",
      );
    }
  }

  static Future<http.Response> post(
      Uri url, {
        required Map<String, String> headers,
        Object? body,
      }) async {
    try {
      return await http
          .post(
        url,
        headers: headers,
        body: body,
      )
          .timeout(const Duration(seconds: 30));
    } on SocketException {
      throw Exception(
        "Unable to connect to the server. Please check your internet connection.",
      );
    } on TimeoutException {
      throw Exception(
        "Request timed out. Please try again.",
      );
    } on http.ClientException {
      throw Exception(
        "Unable to connect to the server. Please try again later.",
      );
    }
  }
  static Future<http.Response> put(
      Uri url, {
        required Map<String, String> headers,
        Object? body,
      }) async {
    try {
      return await http
          .put(
        url,
        headers: headers,
        body: body,
      )
          .timeout(const Duration(seconds: 30));
    } on SocketException {
      throw Exception(
        "Unable to connect to the server. Please check your internet connection.",
      );
    } on TimeoutException {
      throw Exception(
        "Request timed out. Please try again.",
      );
    } on http.ClientException {
      throw Exception(
        "Unable to connect to the server. Please try again later.",
      );
    }
  }

  static String parseError(http.Response response,
      {String defaultMessage = "Something went wrong."}) {
    try {
      final error = jsonDecode(response.body);

      switch (error["code"]) {
        case "internal_server_error":
          return "Server error occurred. Please try again later.";

        case "jwt_auth_invalid_token":
          return "Your session has expired. Please login again.";

        case "woocommerce_rest_stock_error":
          return "This item is out of stock. Please check.";

        case "cannot_cancel_with_children":
          return "This order has active KOTs. Please cancel all KOTs before cancelling the order.";

        case "payment_failed":
          return "Payment could not be completed.";

        case "payment_already_voided":
          return "This payment has already been voided.";

        case "payment_not_found":
          return "Payment record not found.";
      // Coupon errors
        case "woocommerce_rest_invalid_coupon":
          return "The coupon code is invalid.";

        case "woocommerce_rest_coupon_expired":
          return "This coupon has expired.";

        case "woocommerce_rest_coupon_usage_limit":
          return "This coupon has reached its usage limit.";


        default:
          final message = (error["message"] ?? "").toString().toLowerCase();

          if (message.contains("invalid coupon")) {
            return "The coupon code you entered is invalid.";
          }

          if (message.contains("already applied")) {
            return "This coupon has already been applied.";
          }

          if (message.contains("expired")) {
            return "This coupon has expired.";
          }

          if (message.contains("not applicable")) {
            return "This coupon is not applicable to this order.";
          }

          if (message.contains("minimum spend")) {
            return "The minimum order amount required for this coupon has not been met.";
          }

          if (message.contains("maximum spend")) {
            return "This coupon cannot be applied because the order exceeds the allowed amount.";
          }

          if (message.contains("usage limit")) {
            return "This coupon has reached its usage limit.";
          }

          return defaultMessage;
      }
    } catch (_) {
      return defaultMessage;
    }
  }
}