import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/complete_order_model.dart';
import '../utils/AppConstant.dart';

Future<CompletedOrdersResponse> getCompletedOrders({
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
    "page": page.toString(),
    "per_page": perPage.toString(),
    "restaurant_id": restaurantId.toString(),
    "from_date": formatDate(from),
    "to_date": formatDate(to),
  };

  if (orderType != null && orderType.isNotEmpty) {
    queryParams["order_type"] = orderType.toLowerCase();
  }

  if (status != null && status.isNotEmpty) {
    queryParams["status"] = status.toLowerCase();
  }

  if (prepTime != null) {
    queryParams["prep_time"] = prepTime.toString();
  }

  final url = Uri.parse(
    AppConstants.completedOrdersEndpoint,
  ).replace(
    queryParameters: queryParams,
  );

  print("========== COMPLETED ORDERS ==========");
  print(url);

  final response = await http.get(
    url,
    headers: {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    },
  );

  print("Status Code : ${response.statusCode}");
  print(response.body);

  if (response.statusCode != 200) {
    throw Exception(
      "Failed to load completed orders (${response.statusCode})",
    );
  }

  final json = jsonDecode(response.body);

  if (json["success"] != true) {
    throw Exception(json["message"] ?? "Unknown Error");
  }

  return CompletedOrdersResponse.fromJson(json);
}