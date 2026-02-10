import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import '../models/order/KOT_model.dart';
import '../models/order/transfer_table_model.dart';
import '../utils/logger.dart'; // make sure your AppLogger is here

class KotRepository {
  final String baseUrl;
  KotRepository({required this.baseUrl});

  Future<List<KotModel>> fetchKots({
    required int parentOrderId,
    required int restaurantId,
    required int zoneId,
    required String token,
  }) async {
    final url = Uri.parse(
      "$baseUrl/wp-json/pinaka-restaurant-pos/v1/kot/get-parent-kot-orders"
          "?parent_order_id=$parentOrderId&restaurant_id=$restaurantId&zone_id=$zoneId",
    );

    AppLogger.info("Fetching KOTs from URL: $url");

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      AppLogger.info("KOTs response status: ${response.statusCode}");
      AppLogger.info("KOTs response body: ${response.body}");

      if (response.statusCode != 200) {
        throw Exception(
          "Failed to fetch KOTs. Status code: ${response.statusCode}, Body: ${response.body}",
        );
      }

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (data['parent_order'] == null || data['parent_order']['kot_orders'] == null) {
        AppLogger.info("No KOTs found for parentOrderId: $parentOrderId");
        return [];
      }

      final kotOrders = data['parent_order']['kot_orders'] as List<dynamic>;
      AppLogger.info("Fetched ${kotOrders.length} KOTs successfully.");

      return kotOrders.map((e) => KotModel.fromJson(e)).toList();
    } catch (e, st) {
      AppLogger.error("Error fetching KOTs: $e");
      AppLogger.error(st.toString());
      throw Exception("Error fetching KOTs: $e");
    }
  }
}

class KotTransferRepository {
  final String baseUrl =
      "https://merchantrestaurant.alektasolutions.com/wp-json/pinaka-restaurant-pos/v1";

  Future<KotTransferResponse> transferKot({
    required int orderId,
    required int kotId,
    required int fromTableId,
    required int toTableId,
    required int restaurantId,
    required int zoneId,
    required String token,
  }) async {
    final url = Uri.parse("$baseUrl/kot/kot-transfer");

    final body = {
      "order_id": orderId,
      "kot_id": kotId,
      "from_table_id": fromTableId,
      "to_table_id": toTableId,
      "restaurant_id": restaurantId,
      "zone_id": zoneId,
    };

    // 🔹 REQUEST LOGS
    debugPrint("🔵 KOT TRANSFER API CALL");
    debugPrint("➡️ URL: $url");
    debugPrint("➡️ Headers: Authorization: Bearer $token");
    debugPrint("➡️ Body: ${jsonEncode(body)}");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(body),
    );

    // 🔹 RESPONSE LOGS
    debugPrint("🟢 RESPONSE STATUS: ${response.statusCode}");
    debugPrint("🟢 RESPONSE BODY: ${response.body}");

    if (response.statusCode == 200) {
      return KotTransferResponse.fromJson(
        jsonDecode(response.body),
      );
    } else {
      debugPrint("🔴 KOT TRANSFER FAILED");
      throw Exception("KOT transfer failed");
    }
  }
}


