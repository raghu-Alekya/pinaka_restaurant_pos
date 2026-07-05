import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/constants.dart';
import '../models/order/KOT_model.dart';
import '../models/order/order_items.dart';
import '../models/order/order_model.dart';
import '../models/order/guest_details.dart';
import '../models/takeawayorder_model.dart';
import '../services/api_exception.dart';
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
    int? reservationId,
    required String zoneName,
    required String restaurantName,
    required List<Guestcount> guests,
    required String orderDateTime,
    required String tableName,
  }) async {

    final url = Uri.parse(
      '${AppConstants.baseDomain}/wp-json/pinaka-restaurant-pos/v1/orders',
    );

    AppLogger.info("BASE URL => $baseUrl");
    AppLogger.info("ORDER URL => $url");
    AppLogger.info("RESTAURANT ID => $restaurantId");
    AppLogger.info("ZONE ID => $zoneId");

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
      "reservation_id": reservationId,
      "order_datetime": orderDateTime,
    };

    AppLogger.info("REQUEST BODY => ${jsonEncode(body)}");

    final authHeader = token.startsWith("Bearer ")
        ? token
        : "Bearer $token";

    AppLogger.info("AUTH HEADER => $authHeader");

    try {
      final response = await ApiExceptionHandler.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': authHeader,
        },
        body: jsonEncode(body),
      );

      AppLogger.info("ORDER STATUS => ${response.statusCode}");
      AppLogger.info("ORDER RESPONSE => ${response.body}");

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        final data = jsonDecode(response.body);

        final order = OrderModel.fromJson(data);

        return order.copyWith(
          orderId: data['order_id'] ?? order.id,
        );
      }

      throw Exception(
        ApiExceptionHandler.parseError(
          response,
          defaultMessage: "Failed to create order.",
        ),
      );
    } catch (e, stackTrace) {
      AppLogger.error("Create Order Exception: $e");
      AppLogger.error(stackTrace.toString());

      if (e is Exception) rethrow;

      throw Exception(
        "Something went wrong while creating the order.",
      );
    }
  }
  Future<Map<String, dynamic>> cancelOrder({
    required int parentOrderId,
    required String token,
    required restaurantId,
    required int zoneId,
  }) async {
    final url = Uri.parse(
      '${AppConstants
          .baseDomain}/wp-json/pinaka-restaurant-pos/v1/orders/$parentOrderId',
    );

    final body = {
      "flag_type": "cancel_parent_order",
      "order_id": parentOrderId,
      "restaurant_id": restaurantId,
      "zone_id": zoneId,
    };

    AppLogger.debug("CancelOrder Request URL: $url");
    AppLogger.debug("CancelOrder Body: ${jsonEncode(body)}");

    try {
      final response = await ApiExceptionHandler.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      AppLogger.info("Cancel Order Status: ${response.statusCode}");
      AppLogger.info("Cancel Order Response: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }

      throw Exception(
        ApiExceptionHandler.parseError(
          response,
          defaultMessage: "Failed to cancel order.",
        ),
      );
    } catch (e, stackTrace) {
      AppLogger.error("Cancel Order Exception: $e");
      AppLogger.error(stackTrace.toString());

      if (e is Exception) {
        rethrow;
      }

      throw Exception(
        "Something went wrong while cancelling the order.",
      );
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
    final url = Uri.parse(
      '${AppConstants.baseDomain}/wp-json/pinaka-restaurant-pos/v1/orders',
    );


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
      final response = await ApiExceptionHandler.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
          token.startsWith("Bearer ") ? token : "Bearer $token",
        },
        body: jsonEncode(body),
      );

      AppLogger.debug("KOT API Response Code: ${response.statusCode}");
      AppLogger.debug("KOT API Response Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        return KotModel(
          kotId: data['kot_id'] ?? 0,
          kotNumber: data['kot_number'] ?? '',
          time: DateTime.now(),
          status: 'created',
          items: items,
          parentOrderId: parentOrderId,
          captainId: captainId,
          kotItems: [],
        );
      }

      throw Exception(
        ApiExceptionHandler.parseError(
          response,
          defaultMessage: "Failed to create KOT.",
        ),
      );
    } catch (e, stackTrace) {
      AppLogger.error("Error creating KOT: $e");
      AppLogger.error(stackTrace.toString());

      if (e is Exception) {
        rethrow;
      }

      throw Exception(
        "Something went wrong while creating KOT.",
      );
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

    //  Ensure either product_id OR variation_id
    if (item.variationId != null && item.variationId! > 0) {
      lineItem["variation_id"] = item.variationId;
    } else if (item.productId != null && item.productId! > 0) {
      lineItem["product_id"] = item.productId;
    } else {
      // Skip this item, don’t send invalid payload
      AppLogger.error(" Skipping invalid line_item: missing productId/variationId");
      return null;
    }

    AppLogger.debug(" Line item payload: $lineItem");
    return lineItem;
  }
  Future<OrderModel?> getOrderByTable({
    required int restaurantId,
    int? zoneId,
    required int tableId,
    required String token,
  }) async {
    AppLogger.debug(
      '🐛 Fetching order with parameters → tableId=$tableId, zoneId=${zoneId ?? 'null'}, restaurantId=$restaurantId',
    );

    try {
      final queryParams = {
        'restaurant_id': restaurantId.toString(),
        'table_id': tableId.toString(),
        if (zoneId != null) 'zone_id': zoneId.toString(),
      };

      final url = Uri.parse(
        '${AppConstants.baseDomain}/wp-json/pinaka-restaurant-pos/v1/kot/get-order-by-table',
      ).replace(queryParameters: queryParams);

      AppLogger.debug("🐛 Request URL: $url");

      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      });

      AppLogger.debug("🐛 Response status code: ${response.statusCode}");
      AppLogger.debug("🐛 Response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        AppLogger.debug("🐛 Decoded JSON data: $data");

        if (data == null || data.isEmpty) {
          AppLogger.error("⛔ No parent order found for table $tableId");
          return null;
        }

        final parent = data['parent_order'] as Map<String, dynamic>? ?? data as Map<String, dynamic>;

        // ✅ Fallback zoneId if backend didn’t return it
        final effectiveZoneId = parent['zone_id'] ?? zoneId ?? 0;
        // / ✅ FIX: read guest_count
        final int guestCount = parent['guest_count'] ?? 0;
        AppLogger.debug("👥 Guest count from API = $guestCount");


        // Parse all KOTs
        final kotOrders = (parent['kot_orders'] as List<dynamic>? ?? [])
            .map((k) => KotModel.fromJson(k as Map<String, dynamic>))
            .toList();

        // Flatten all items from all KOTs
        final items = kotOrders.expand((kot) => kot.items).toList();

        return OrderModel(
          orderId: parent['order_id'] ?? parent['id'] ?? 0,
          tableId: parent['table_id'] ?? 0,
          tableName: parent['table_name'] ?? '',
          zoneId: effectiveZoneId, // ✅ fixed here
          zoneName: parent['zone_name'] ?? '',
          status: parent['status'] ?? '',
          items: items,
          kotOrders: kotOrders,
          // ✅ PASS GUEST DATA
          guestCount: guestCount,
          orderDateTime: parent['order_datetime'] != null
              ? DateTime.parse(parent['order_datetime'])
              : null,
          // guestDetails: guestDetails,
        );

      } else {
        AppLogger.error("⛔ Failed to fetch order. Status: ${response.statusCode}");
      }
    } catch (e, st) {
      AppLogger.error("⛔ Error fetching order for table $tableId: $e\n$st");
    }

    return null;
  }
  Future<TakeAwayOrderModel> createTakeAwayOrder({
    required String restaurantId,
    required String token,
    required String orderDateTime,
  }) async {
    final url = Uri.parse(
      '${AppConstants.baseDomain}/wp-json/pinaka-restaurant-pos/v1/orders',
    );

    final body = {
      "flag_type": "parent_takeaway_order",
      "restaurant_id": int.parse(restaurantId),
      "created_via": "takeaway",
      "order_datetime": orderDateTime,
    };

    AppLogger.info("Take Away Request => ${jsonEncode(body)}");

    final response = await ApiExceptionHandler.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": token.startsWith("Bearer ")
            ? token
            : "Bearer $token",
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);

      return TakeAwayOrderModel(
        orderId: data["order_id"],
        restaurantId: data["restaurant_id"],
        status: data["status"] ?? "",
        orderType: data["order_type"] ?? "",
      );
    }

    throw Exception(
      ApiExceptionHandler.parseError(
        response,
        defaultMessage: "Failed to create Take Away order.",
      ),
    );
  }
//  update the order same kot
  Future<void> updateTakeAwayKot({
    required int kotId,
    required int parentOrderId,
    required int restaurantId,
    required int captainId,
    required List<OrderItems> items,
    required String token,
  }) async {
    final body = {
      "flag_type": "update_kot_order",
      "parent_order_id": parentOrderId,
      "restaurant_id": restaurantId,
      "captain_id": captainId,
      "line_items": items
          .map((item) => _orderItemToLineItem(item))
          .whereType<Map<String, dynamic>>()
          .toList(),
    };

    await http.put(
      Uri.parse(
        "$baseUrl/wp-json/pinaka-restaurant-pos/v1/orders/$kotId",
      ),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(body),
    );
  }
  Future<void> cancelTakeAwayOrder({
    required int parentOrderId,
    required int restaurantId,
    required String token,
  }) async {
    final url = Uri.parse(
      '${AppConstants.baseDomain}/wp-json/pinaka-restaurant-pos/v1/orders/$parentOrderId',
    );

    final body = {
      "flag_type": "cancel_takeaway_order",
      "restaurant_id": restaurantId,
    };

    AppLogger.info("=== TAKEAWAY CANCEL DEBUG ===");
    AppLogger.info("URL => $url");
    AppLogger.info("ParentOrderId => $parentOrderId");
    AppLogger.info("RestaurantId => $restaurantId");
    AppLogger.info("Body => ${jsonEncode(body)}");
    AppLogger.info("=============================");

    final response = await http.put(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": token.startsWith("Bearer ")
            ? token
            : "Bearer $token",
      },
      body: jsonEncode(body),
    );

    AppLogger.info("STATUS => ${response.statusCode}");
    AppLogger.info("RESPONSE => ${response.body}");
  }


}



