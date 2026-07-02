import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/kitchen_order.dart';
import '../utils/AppConstant.dart';
import '../utils/kds_logger.dart';

class KotOrderApiService {
  final String baseUrl;
  final String token;

  KotOrderApiService({
    required this.baseUrl,
    required this.token,
  });

  Future<List<KitchenOrder>> fetchOrders({
    required int parentOrderId,
    required int restaurantId,
    required int zoneId,
  }) async {
    try {
      final url = Uri.parse(
        "${AppConstants.parentKotOrdersEndpoint}"
            "?parent_order_id=$parentOrderId"
            "&restaurant_id=$restaurantId"
            "&zone_id=$zoneId",
      );
      KdsDebugLog.info("Fetching KOTs: $url");

      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      KdsDebugLog.info(
        "Fetch Orders Status: ${response.statusCode}",
      );

      if (response.statusCode != 200) {
        throw Exception(
          "Failed to load orders: ${response.body}",
        );
      }

      final Map<String, dynamic> json =
      jsonDecode(response.body);

      if (json["parent_order"] == null ||
          json["parent_order"]["kot_orders"] == null) {
        return [];
      }

      final List<dynamic> kotOrders =
      json["parent_order"]["kot_orders"];

      return kotOrders.map((kot) {
        return KitchenOrder(
          id: kot["kot_number"] ?? "",
          kotId: kot["id"] ?? 0,
          parentOrderId: parentOrderId,
          zoneId: zoneId,
          zoneName:
          json["parent_order"]["zone_name"] ?? "",
          tableName:
          json["parent_order"]["table_name"] ?? "",
          type:
          json["parent_order"]["order_type"] ?? "",
          status: _mapStatus(kot["status"] ?? ""),
          isCancelled: false,
          items: [],
        );
      }).toList();
    } catch (e) {
      KdsDebugLog.error(
        "fetchOrders error: $e",
      );
      rethrow;
    }
  }

  String _mapStatus(String status) {
    switch (status.toLowerCase()) {
      case 'yet to prepare':
        return 'Pending';

      case 'processing':
      case 'preparing':
      case 'kot processed':
        return 'Preparing';

      case 'ready':
        return 'Ready';

      case 'served':
        return 'Served';

      default:
        return 'Pending';
    }
  }

  void dispose() {}
}