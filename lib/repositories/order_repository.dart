import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/order/KOT_model.dart';
import '../models/order/order_items.dart';
import '../models/order/order_model.dart';
import '../models/order/guest_details.dart';
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
    String? reservationId,
    required String zoneName,
    required String restaurantName,
    required List<Guestcount> guests,
    required String tableName,
  }) async {
    final url = Uri.parse('$baseUrl/wp-json/pinaka-restaurant-pos/v1/orders');

    final body = {
      "flag_type": "parent_order",
      "table_id": tableId,
      "table_name": tableName,
      "zone_id": zoneId,
      "zone_name": zoneName,
      "restaurant_id": int.tryParse(restaurantId) ?? 0,
      "restaurant_name": restaurantName,
      "guest_count": guestCount,
      "guest_details": guests.map((g) => g.toJson()).toList(),
    };

    if (reservationId != null) body["reservation_id"] = reservationId;

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
      return OrderModel.fromJson(data);
    } else {
      throw Exception('Failed to create order: ${response.body}');
    }
  }
  Future<Map<String, dynamic>> cancelOrder({
    required int parentOrderId,
    required String token,
    required  restaurantId,
    required int zoneId,
  }) async {
    final url = Uri.parse('$baseUrl/wp-json/pinaka-restaurant-pos/v1/orders/$parentOrderId');

    final body = {
      "flag_type": "cancel_parent_order",
      "order_id": parentOrderId,
      "restaurant_id": restaurantId,
      "zone_id": zoneId,
    };

    // 🔹 Debug logs before request
    AppLogger.debug(" CancelOrder Request URL: $url");
    AppLogger.debug(" CancelOrder Headers: ${{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    }}");
    AppLogger.debug(" CancelOrder Body: ${jsonEncode(body)}");

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    AppLogger.info(' Cancel order response: ${response.statusCode}');
    AppLogger.info(' Cancel order body: ${response.body}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(' Failed to cancel order: ${response.body}');
    }
  }

  Future<KotModel?> createKOT({
    required int parentOrderId,
    required String kotId,
    required List<OrderItems> items,
    required String token,
    required  restaurantId,   // fixed type
    required int zoneId,
    required int captainId,
  }) async {
    final url = Uri.parse('$baseUrl/wp-json/pinaka-restaurant-pos/v1/orders');

    final lineItems = items
        .map((item) => _orderItemToLineItem(item))
        .whereType<Map<String, dynamic>>()
        .toList();

    final body = {
      "flag_type": "kot_order",
      "parent_order_id": parentOrderId,
      "restaurant_id": restaurantId,
      "zone_id": zoneId,
      "captain_id": captainId,
      "line_items": lineItems,
    };

    AppLogger.debug("Creating KOT request");
    AppLogger.debug("URL: $url");
    AppLogger.debug("Token: $token"); // check if token already has "Bearer "
    AppLogger.debug("Body: ${jsonEncode(body)}");

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token.startsWith("Bearer ")
              ? token
              : "Bearer $token",   // ✅ fix double-bearer issue
        },
        body: jsonEncode(body),
      );

      AppLogger.debug("🔹 KOT API Response Code: ${response.statusCode}");
      AppLogger.debug("🔹 KOT API Response Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        final kot = KotModel(
          kotId: data['kot_id'] ?? 0,
          kotNumber: data['kot_number'] ?? '',
          time: DateTime.now(),
          status: 'created',
          items: items,
        );

        AppLogger.info("KOT created successfully: ${jsonEncode(kot.toJson())}");
        return kot;
      } else {
        AppLogger.error("❌ Failed to create KOT: ${response.statusCode} ${response.body}");
        return null;
      }
    } catch (e, stackTrace) {
      AppLogger.error("🔥 Error creating KOT: $e");
      AppLogger.error(stackTrace.toString());
      return null;
    }
  }

// Helper to convert OrderItems → backend line_items
  Map<String, dynamic>? _orderItemToLineItem(OrderItems item) {
    final List<Map<String, dynamic>> metaData = [];

    // Add-ons
    if (item.addOns.isNotEmpty) {
      metaData.add({
        "key": "_addons",
        "value": item.addOns.entries.map((entry) {
          return {
            "name": entry.key,
            "quantity": entry.value['quantity'],
            "price": entry.value['price'],
          };
        }).toList(),
      });
    }

    // Modifiers
    if (item.modifiers.isNotEmpty) {
      metaData.add({
        "key": "_modifiers",
        "value": item.modifiers.map((name) {
          return {"name": name, "quantity": 1};
        }).toList(),
      });
    }

    // Notes
    if (item.note.isNotEmpty) {
      metaData.add({"key": "_modifier_notes", "value": item.note});
    }

    // Extra modifier amount
    double extraAmount = 0.0;
    item.addOns.forEach((_, value) {
      extraAmount += (value['quantity'] as int) * (value['price'] as double);
    });
    if (extraAmount > 0) {
      metaData.add({"key": "_extra_modifier_amount", "value": extraAmount.toString()});
    }

    // Build line_item
    final Map<String, dynamic> lineItem = {
      "quantity": item.quantity,
      "meta_data": metaData,
    };

    // ✅ Ensure either product_id OR variation_id
    if (item.variationId != null && item.variationId! > 0) {
      lineItem["variation_id"] = item.variationId;
    } else if (item.productId != null && item.productId! > 0) {
      lineItem["product_id"] = item.productId;
    } else {
      // Skip this item, don’t send invalid payload
      AppLogger.error(" Skipping invalid line_item: missing productId/variationId");
      return null;
    }

    AppLogger.debug("🔹 Line item payload: $lineItem");
    return lineItem;
  }

}




