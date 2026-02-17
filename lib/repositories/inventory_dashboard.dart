import 'dart:convert';
import 'package:http/http.dart' as http;

// import '../models/dashboard/inventory_dashboard_model.dart';
import '../models/dashboard_model/inventory_dashboard.dart';


class InventoryRepository {
  final String baseUrl =
      "https://merchantrestaurant.alektasolutions.com/wp-json/pinaka-restaurant-pos/v1/merchant-dashboard/get-inventory-alerts";

  Future<List<InventoryAlert>> getInventoryAlerts(String token) async {
    final url = Uri.parse("$baseUrl/merchant-dashboard/get-inventory-alerts");

    final response = await http.get(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => InventoryAlert.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load inventory alerts");
    }
  }
}