import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/complete_order_model.dart';

Future<List<CompletedOrderModel>> getCompletedOrders({
  required String token,
}) async {
  final now = DateTime.now();

  final fromDate =
      "${now.year}-${now.month.toString().padLeft(2, '0')}-01";

  final toDate =
      "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

  final url = Uri.parse(
    'https://merchantrestaurant.alektasolutions.com/wp-json/pinaka-restaurant-pos/v1/kot/get-completed-orders'
        '?page=1'
        '&per_page=50'
        '&from_date=$fromDate'
        '&to_date=$toDate'
        '&restaurant_id=1',
  );

  const token =
      'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczpcL1wvbWVyY2hhbnRyZXN0YXVyYW50LmFsZWt0YXNvbHV0aW9ucy5jb20iLCJpYXQiOjE3ODEwODY0NjUsIm5iZiI6MTc4MTA4NjQ2NSwiZXhwIjoxNzgzNjc4NDY1LCJkYXRhIjp7InVzZXIiOnsiaWQiOjUsImRldmljZSI6IiIsInBhc3MiOiIyYjhlMjJlOTM2ZTY0N2JhNDRmOWJhMmY3Y2Q1ZmFjNiJ9fX0.uXAQqbZ1WZ_HvHNP_tA3BQ28ILdqVssmIWTOfrMr-1U';

  final response = await http.get(
    url,
    headers: {
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode == 200) {
    print("Status Code: ${response.statusCode}");
    print("Response Body: ${response.body}");

    final json = jsonDecode(response.body);

    print("Decoded JSON: $json");

    final List data = json['data'];

    print("Data Length: ${data.length}");
    print("Data: $data");

    return data
        .map((e) => CompletedOrderModel.fromJson(e))
        .toList();
  } else {
    print("API Error");
    print("Status Code: ${response.statusCode}");
    print("Response Body: ${response.body}");
  }

  throw Exception('Failed to load completed orders');
}