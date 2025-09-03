import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pinaka_restaurant_pos/models/order/guest_details.dart';
import '../models/order/order_model.dart';
import '../utils/logger.dart';

class OrderRepository {
  final String baseUrl;

  OrderRepository({required this.baseUrl});

  Future<OrderModel> createOrder({
    required int tableId,
    required int zoneId,
    required String restaurantId,
    required int guestCount,
    required String token,
    String? reservationId, required zoneName, required String restaurantName, required List<Guestcount> guests, required String tableName,
  }) async {
    final url = Uri.parse('$baseUrl/wp-json/pinaka-restaurant-pos/v1/orders');

    final body = {
      "flag_type": "parent_order",
      "table_id": tableId,
      "table_name": tableName,          // ✅ Add this
      "zone_id": zoneId,
      "zone_name": zoneName,
      "restaurant_id": int.tryParse(restaurantId) ?? 0,
      "restaurant_name": restaurantName,
      "guest_count": guestCount,
      "guest_details": guests.map((g) => g.toJson()).toList(),
    };



    if (reservationId != null) {
      body["reservation_id"] = reservationId;
    }

    AppLogger.info('Creating order with body: ${jsonEncode(body)}');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    AppLogger.info('Order API response: ${response.statusCode} ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return OrderModel.fromJson(data); // Make sure your OrderModel parses correctly
    } else {
      throw Exception('Failed to create order: ${response.body}');
    }
  }
}
