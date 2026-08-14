import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../../utils/api_exception_handler.dart';
import 'create_order_model.dart';

abstract class CreateOrderRemoteDataSource {
  Future<CreateOrderResponse> createOrder({
    required String baseUrl,
    required String token,
    required CreateOrderRequest request,
  });

  // ✅ ADDED cancelOrder method signature
  Future<Map<String, dynamic>> cancelOrder({
    required String baseUrl,
    required String token,
    required int parentOrderId,
    required dynamic restaurantId,
    required int zoneId,
  });
}

class CreateOrderRemoteDataSourceImpl implements CreateOrderRemoteDataSource {
  @override
  Future<CreateOrderResponse> createOrder({
    required String baseUrl,
    required String token,
    required CreateOrderRequest request,
  }) async {
    try {
      print('========== CREATE ORDER START ==========');
      final url = '$baseUrl/wp-json/pinaka-restaurant-pos/v1/orders';
      print('URL: $url');
      print('Method: POST');

      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };
      print('Headers: $headers');

      final body = jsonEncode(request.toJson());
      print('Request Body: $body');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      print('--- Response ---');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Order created successfully.');
        try {
          final jsonResponse = jsonDecode(response.body);
          print('Parsed JSON: $jsonResponse');
          final result = CreateOrderResponse.fromJson(jsonResponse);
          print('Order ID: ${result.orderId}');
          print('========== CREATE ORDER END ==========');
          return result;
        } catch (e, stackTrace) {
          print('ERROR parsing order response: $e');
          print('Stack Trace: $stackTrace');
          rethrow;
        }
      } else {
        print('========== CREATE ORDER FAILED ==========');
        print('HTTP Error: ${response.statusCode}');
        final errorMsg = ApiExceptionHandler.parseError(
          response,
          defaultMessage: 'Failed to create order.',
        );
        print('Error message: $errorMsg');
        throw Exception(errorMsg);
      }
    } catch (e, stackTrace) {
      print('========== CREATE ORDER EXCEPTION ==========');
      print('Exception: $e');
      print('Stack Trace: $stackTrace');
      print('============================================');
      if (e is Exception) rethrow;
      throw Exception('Failed to create order. Please try again.');
    }
  }

  // ============================================================
  // CANCEL ORDER
  // ============================================================

  @override
  Future<Map<String, dynamic>> cancelOrder({
    required String baseUrl,
    required String token,
    required int parentOrderId,
    required dynamic restaurantId,
    required int zoneId,
  }) async {
    try {
      print('========== CANCEL ORDER START ==========');

      // ✅ Correct URL: include the order ID in the path
      final url = '$baseUrl/wp-json/pinaka-restaurant-pos/v1/orders/$parentOrderId';
      print('URL: $url');
      print('Method: POST');

      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };
      print('Headers: $headers');

      // ✅ restaurant_id as string to match the working cURL
      final body = {
        'flag_type': 'cancel_parent_order',
        'order_id': parentOrderId,
        'restaurant_id': restaurantId.toString(), // <-- convert to string
        'zone_id': zoneId,
      };

      print('Request Body: ${jsonEncode(body)}');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );

      print('--- CANCEL ORDER RESPONSE ---');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        print('Order cancelled successfully.');
        final jsonResponse = jsonDecode(response.body);
        print('Parsed Response: $jsonResponse');
        print('========== CANCEL ORDER END ==========');
        return jsonResponse as Map<String, dynamic>;
      } else {
        print('========== CANCEL ORDER FAILED ==========');
        print('HTTP Error: ${response.statusCode}');
        final errorMsg = ApiExceptionHandler.parseError(
          response,
          defaultMessage: 'Failed to cancel order.',
        );
        print('Cancel Order Error: $errorMsg');
        throw Exception(errorMsg);
      }
    } catch (e, stackTrace) {
      print('========== CANCEL ORDER EXCEPTION ==========');
      print('Exception: $e');
      print('Stack Trace: $stackTrace');
      print('============================================');
      if (e is Exception) rethrow;
      throw Exception('Something went wrong while cancelling the order.');
    }
  }
}