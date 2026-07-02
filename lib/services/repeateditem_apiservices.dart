import 'dart:convert';
import 'package:http/http.dart' as http;

Future<List<dynamic>> getKitchenItemsCount({
  required String token,
  required int restaurantId,
}) async {
  final uri = Uri.https(
    'merchantrestaurant.alektasolutions.com',
    '/wp-json/pinaka-restaurant-pos/v1/kot/get-kitchen-items-count',
    {
      'restaurant_id': restaurantId.toString(),
    },
  );

  print("Request URL: $uri");

  final response = await http.get(
    uri,
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );

  print("Status Code: ${response.statusCode}");
  print("Response: ${response.body}");

  if (response.statusCode == 200) {
    final List<dynamic> json = jsonDecode(response.body);
    return json;
  }

  throw Exception('Failed to load kitchen items count');
}