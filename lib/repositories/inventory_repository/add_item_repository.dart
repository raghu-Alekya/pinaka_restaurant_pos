import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/inventory/manage_stock_model.dart';
// import '../models/inventory/manage_stock.dart';

class AddUpdateItemRepository {
  static const String baseUrl =
      'https://merchantrestaurant.alektasolutions.com/wp-json/pinaka-restaurant-pos/v1/inventories/add-update-item-details';

  final String token =
  'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczpcL1wvbWVyY2hhbnRyZXN0YXVyYW50LmFsZWt0YXNvbHV0aW9ucy5jb20iLCJpYXQiOjE3Njc3NzQ1MjQsIm5iZiI6MTc2Nzc3NDUyNCwiZXhwIjoxNzcwMzY2NTI0LCJkYXRhIjp7InVzZXIiOnsiaWQiOjUsImRldmljZSI6IiIsInBhc3MiOiIyYjhlMjJlOTM2ZTY0N2JhNDRmOWJhMmY3Y2Q1ZmFjNiJ9fX0.kk0uY8-nQPcfIgJkrWr5j5UQca9RJNzG7LBWhI5jVGE'
      .trim();

  // ✅ Added miniCategoryId here
  Future<AddUpdateItemResponse> addOrUpdateItem({
    required String itemName,
    required int categoryId,
    int? miniCategoryId, // optional mini-category
    int? taxId, // ✅
    required int itemQty,
    required int itemPrice,
    required String itemNote,
    required String itemSku,
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
      'item_name': itemName,
      'category_id': categoryId.toString(),
      'item_qty': itemQty.toString(),
      'item_price': itemPrice.toString(),
      'item_note': itemNote,
      'item_sku': itemSku,
      // ✅ Include miniCategoryId if provided
      if (miniCategoryId != null) 'mini_category_id': miniCategoryId.toString(),
    });

    final streamedResponse = await request.send();
    final responseBody = await streamedResponse.stream.bytesToString();

    if (streamedResponse.statusCode == 200) {
      return AddUpdateItemResponse.fromJson(jsonDecode(responseBody));
    } else {
      throw Exception(
        'Failed: ${streamedResponse.statusCode} $responseBody',
      );
    }
  }
}