import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../models/inventory/manage_stock_model.dart';

// import '../models/inventory/manage_stock.dart';

class ManageStockRepository {
  static const String baseUrl =
      'https://merchantrestaurant.alektasolutions.com/wp-json/pinaka-restaurant-pos/v1/inventories/update-stock-details';

  final String token =
      'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczpcL1wvbWVyY2hhbnRyZXN0YXVyYW50LmFsZWt0YXNvbHV0aW9ucy5jb20iLCJpYXQiOjE3NjczNDM5NzksIm5iZiI6MTc2NzM0Mzk3OSwiZXhwIjoxNzY5OTM1OTc5LCJkYXRhIjp7InVzZXIiOnsiaWQiOjUsImRldmljZSI6IiIsInBhc3MiOiIyYjhlMjJlOTM2ZTY0N2JhNDRmOWJhMmY3Y2Q1ZmFjNiJ9fX0.2i80aj2lDtVOCj_yckQw_JP1ScM4r7f6f5ilHBP0fGk';

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

    request.headers['Authorization'] = 'Bearer $token';

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