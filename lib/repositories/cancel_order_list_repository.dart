import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/constants.dart';
import '../models/order_list/edit_order_list_model.dart';
class CancelOrderRepository {
  get baseApiPath => null;

  // ================= CANCEL PARENT ORDER =================
  Future<CancelOrderResponse> cancelOrder({
    required int orderId,
    required int restaurantId,
    required int zoneId,
    required String token,
  }) async {
    final url = Uri.parse(AppConstants.cancelOrder(orderId));

    print("📤 CANCEL PARENT ORDER API: $url");

    final payload = {
      "flag_type": "cancel_completed_order",
      "restaurant_id": restaurantId,
      "zone_id": zoneId,
    };

    print("📤 PAYLOAD: ${jsonEncode(payload)}");

    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    print("📥 STATUS: ${response.statusCode}");
    print("📥 RESPONSE: ${response.body}");

    if (response.statusCode == 200) {
      return CancelOrderResponse.fromJson(json.decode(response.body));
    } else {
      throw Exception("Cancel Parent Failed → ${response.body}");
    }
  }

  // ================= CANCEL SINGLE KOT =================
  Future<void> cancelKot({
    required int parentOrderId, // 🔹 use parent order ID here
    required int kotOrderId,    // optional if backend needs it in payload
    required int restaurantId,
    required int zoneId,
    required String token,
  }) async {
    // Use parent order ID in the endpoint
    final url = Uri.parse(AppConstants.cancelOrder(parentOrderId));

    final payload = {
      "flag_type": "cancel_completed_order",
      "restaurant_id": restaurantId,
      "zone_id": zoneId,
      "kot_order_id": kotOrderId, // optional: include KOT ID in payload
    };

    print("📤 CANCEL KOT API: $url");
    print("📤 PAYLOAD: ${jsonEncode(payload)}");

    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    print("📥 KOT STATUS: ${response.statusCode}");
    print("📥 KOT RESPONSE: ${response.body}");

    if (response.statusCode != 200) {
      throw Exception("KOT Cancel Failed → ${response.body}");
    }
  }

}