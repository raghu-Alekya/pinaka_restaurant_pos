import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/order/KOT_model.dart';
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
