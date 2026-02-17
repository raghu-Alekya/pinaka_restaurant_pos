import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../models/inventory/manage_stock_model.dart';

class ManageStockRepository {
  static const String baseUrl =
      'https://merchantrestaurant.alektasolutions.com/wp-json/pinaka-restaurant-pos/v1/inventories/update-stock-details';

  final String token;

  ManageStockRepository({required this.token});

  Future<UpdateStockResponse> updateStock({
    required int itemId,
    required int qty,
    required bool isAdd,
    required String reason,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(baseUrl),
    );

    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    request.fields.addAll({
      'item_id': itemId.toString(),
      'qty': qty.toString(),
      'flag_type': isAdd ? 'Add Stock' : 'Reduce Stock',
      'reason': reason,
    });

    final streamedResponse = await request.send();
    final responseBody = await streamedResponse.stream.bytesToString();

    if (streamedResponse.statusCode == 200) {
      return UpdateStockResponse.fromJson(jsonDecode(responseBody));
    } else {
      throw Exception(
        'Failed: ${streamedResponse.statusCode} $responseBody',
      );
    }
  }
}