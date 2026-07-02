import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/complete_order_model.dart';

Future<List<CompletedOrderModel>> getCompletedOrders({
  required String token,
  required int restaurantId,
  int page = 1,
  int perPage = 10,
  DateTime? fromDate,
  DateTime? toDate,
  String? orderType,
  String? status,
  double? prepTime,
}) async {
  final now = DateTime.now();

  final from = fromDate ?? DateTime(now.year, now.month, now.day);
  final to = toDate ?? now;

  String formatDate(DateTime date) {
    return "${date.year}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.day.toString().padLeft(2, '0')}";
  }

  final queryParams = <String, String>{
    'page': page.toString(),
    'per_page': perPage.toString(),
    'restaurant_id': restaurantId.toString(),
    'from_date': formatDate(from),
    'to_date': formatDate(to),
  };

  if (orderType != null && orderType.isNotEmpty) {
    queryParams['order_type'] = orderType.toLowerCase();
  }

  if (status != null && status.isNotEmpty) {
    queryParams['status'] = status.toLowerCase();
  }

  if (prepTime != null) {
    queryParams['prep_time'] = prepTime.toString();
  }

  final url = Uri.https(
    'merchantrestaurant.alektasolutions.com',
    '/wp-json/pinaka-restaurant-pos/v1/kot/get-completed-orders',
    queryParams,
  );

  // ================= DEBUG =================
  print("========== COMPLETED ORDERS API ==========");
  print("Request URL: $url");
  print("Restaurant ID: $restaurantId");
  print("Page: $page");
  print("Per Page: $perPage");

  print("Raw Token:");
  print(token);

  print("Token starts with Bearer: ${token.startsWith("Bearer ")}");

  print("Authorization Header:");
  print("Bearer $token");

  print("Headers:");
  print({
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  });
  print("==========================================");
  // ========================================

  final response = await http.get(
    url,
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );

  print("========== RESPONSE ==========");
  print("Status Code: ${response.statusCode}");
  print("Response Headers: ${response.headers}");
  print("Response Body:");
  print(response.body);
  print("==============================");

  if (response.statusCode == 200) {
    final json = jsonDecode(response.body);

    print("Success: ${json['success']}");
    print("Message: ${json['message']}");
    print("Total Records: ${(json['data'] as List?)?.length ?? 0}");

    if (json['success'] == true) {
      final List<dynamic> data = json['data'] ?? [];

      return data
          .map((e) => CompletedOrderModel.fromJson(e))
          .toList();
    }

    throw Exception(json['message'] ?? 'Unknown error');
  }

  throw Exception(
      'Failed to load completed orders (${response.statusCode})');
}