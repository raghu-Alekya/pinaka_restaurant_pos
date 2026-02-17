import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/order_list/edit_order_list_model.dart';
import '../models/order_list/order_list_model.dart';

class EditOrderlistRepository {
  final String baseUrl;
  final String token;

  EditOrderlistRepository({required this.baseUrl, required this.token});

  /// Update an order or a KOT with detailed logs
  Future<bool> updateOrderRaw({
    required int orderId,
    int? kotOrderId,
    required Map<String, dynamic> payload,
  }) async {
    try {
      final targetId = kotOrderId ?? orderId;
      final url = "$baseUrl/orders/$targetId";

      // Log the outgoing payload in detail
      print("🚀 [UPDATE ORDER RAW] URL => $url");
      print("🚀 [UPDATE ORDER RAW] PAYLOAD => ${jsonEncode(payload)}");

      // Log line items and modifiers before sending
      if (payload.containsKey('line_items')) {
        print("📄 [LINE ITEMS BEFORE UPDATE]");
        for (var item in payload['line_items']) {
          print(
              "Item ID: ${item['id']}, Name: ${item['name']}, Quantity: ${item['quantity']}, Price: ${item['price']}");
          if (item.containsKey('modifiers')) {
            print("   Modifiers:");
            for (var mod in item['modifiers']) {
              print("      ${mod['id']} => ${mod['name']}, Qty: ${mod['quantity']}, Price: ${mod['price']}");
            }
          }
        }
      }

      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      print("✅ [UPDATE STATUS] => ${response.statusCode}");
      print("✅ [UPDATE RESPONSE] => ${response.body}");

      // Optional: Log line items after response if needed
      if (response.statusCode == 200) {
        final respData = jsonDecode(response.body);
        if (respData.containsKey('line_items')) {
          print("📄 [LINE ITEMS AFTER UPDATE]");
          for (var item in respData['line_items']) {
            print(
                "Item ID: ${item['id']}, Name: ${item['name']}, Quantity: ${item['quantity']}, Price: ${item['price']}");
            if (item.containsKey('modifiers')) {
              print("   Modifiers:");
              for (var mod in item['modifiers']) {
                print("      ${mod['id']} => ${mod['name']}, Qty: ${mod['quantity']}, Price: ${mod['price']}");
              }
            }
          }
        }
      }

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('❌ Update order raw error => $e');
      return false;
    }
  }

  /// Fetch order details with detailed logging
  Future<OrderlistModel> fetchOrder(int orderId) async {
    try {
      final url = "$baseUrl/orders/$orderId";

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print("📡 [FETCH ORDER] STATUS => ${response.statusCode}");
      print("📡 [FETCH ORDER] RESPONSE => ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Log each line item and modifiers
        if (data.containsKey('line_items')) {
          print("📄 [LINE ITEMS FETCHED]");
          for (var item in data['line_items']) {
            print(
                "Item ID: ${item['id']}, Name: ${item['name']}, Quantity: ${item['quantity']}, Price: ${item['price']}");
            if (item.containsKey('modifiers')) {
              print("   Modifiers:");
              for (var mod in item['modifiers']) {
                print("      ${mod['id']} => ${mod['name']}, Qty: ${mod['quantity']}, Price: ${mod['price']}");
              }
            }
          }
        }

        return OrderlistModel.fromJson(data);
      } else {
        throw Exception(
            'Failed to fetch order $orderId, status: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Fetch order error => $e');
      rethrow;
    }
  }

  /// Fetch KOT edit reasons
  Future<KotEditReasonModel> fetchKotEditReasons() async {
    final url = Uri.parse(
        '$baseUrl/wp-json/pinaka-restaurant-pos/v1/orders/order-kot-edit-reasons');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print("📡 [FETCH KOT REASONS] STATUS => ${response.statusCode}");
    print("📡 [FETCH KOT REASONS] RESPONSE => ${response.body}");

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return KotEditReasonModel.fromJson(data);
    } else {
      throw Exception('Failed to load KOT edit reasons: ${response.body}');
    }
  }
}