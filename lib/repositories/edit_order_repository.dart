import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/order_list/order_list_model.dart';

class EditOrderlistRepository {
  final String baseUrl;
  final String token;

  EditOrderlistRepository({required this.baseUrl, required this.token});

  /// Update an order or a KOT
  Future<bool> updateOrderRaw({
    required int orderId,
    int? kotOrderId,
    required Map<String, dynamic> payload,
  }) async {
    try {
      // Use KOT ID if provided, otherwise main order ID
      final targetId = kotOrderId;
      final url = "$baseUrl/orders/$targetId";

      print("UPDATE ORDER RAW URL => $url");
      print("UPDATE ORDER RAW BODY => ${jsonEncode(payload)}");

      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      print("STATUS => ${response.statusCode}");
      print("RESPONSE => ${response.body}");

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Update order raw error => $e');
      return false;
    }
  }

  /// Fetch order details
  Future<OrderlistModel> fetchOrder(int orderId) async {
    try {
      final url = "$baseUrl/orders/$orderId";

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print("FETCH ORDER STATUS => ${response.statusCode}");
      print("FETCH ORDER RESPONSE => ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return OrderlistModel.fromJson(data);
      } else {
        throw Exception(
            'Failed to fetch order $orderId, status: ${response.statusCode}');
      }
    } catch (e) {
      print('Fetch order error => $e');
      rethrow;
    }
  }
}