import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/order/repeat_kot_model.dart';
// import '../models/repeat_kot_model.dart';

class repeatOrderRepository {
  final String baseUrl;

  repeatOrderRepository({required this.baseUrl});

  Future<RepeatKotModel> repeatKotOrder({
    required int orderId,
    required int restaurantId,
    required int zoneId,
    required String token,
  }) async {
    final uri = Uri.parse(
      "$baseUrl/wp-json/pinaka-restaurant-pos/v1/orders/repeat-kot-order",
    );

    final response = await http.post(
      uri,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "order_id": orderId,
        "restaurant_id": restaurantId,
        "zone_id": zoneId,
      }),
    );

    if (response.statusCode == 200) {
      return RepeatKotModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(
        "Repeat KOT failed (${response.statusCode}): ${response.body}",
      );
    }
  }

}
