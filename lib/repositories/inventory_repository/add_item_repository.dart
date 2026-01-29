import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/inventory/manage_stock_model.dart';
// import '../models/inventory/manage_stock.dart';

class AddUpdateItemRepository {
  static const String baseUrl =
      'https://merchantrestaurant.alektasolutions.com/wp-json/pinaka-restaurant-pos/v1/inventories/add-update-item-details';
  Future<AddUpdateItemResponse> addOrUpdateItem({
    required String token,
    required String itemName,
    required int categoryId,
    int? miniCategoryId,
    String? taxClass,
    required int itemQty,
    required int itemPrice,
    required String itemNote,
    required String itemSku,
    String? imagePath,
  }) async {
    final uri = Uri.parse(baseUrl);

    //  (IMAGE)
    if (imagePath != null && imagePath.isNotEmpty) {
      final request = http.MultipartRequest('POST', uri);

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      request.fields.addAll({
        'item_name': itemName,
        'category_id': categoryId.toString(),
        'item_qty': itemQty.toString(),
        'item_price': itemPrice.toString(),
        'item_note': itemNote,
        'item_sku': itemSku,
        if (miniCategoryId != null)
          'mini_category_id': miniCategoryId.toString(),
        if (taxClass != null) ...{
          'tax_status': 'taxable',
          'tax_class': taxClass,
        },
      });

      request.files.add(
        await http.MultipartFile.fromPath(
          'image', // ⚠️ Confirm backend expects "image"
          imagePath,
        ),
      );

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        return AddUpdateItemResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed: ${response.statusCode} ${response.body}');
      }
    }

    // -------- NORMAL JSON POST (NO IMAGE) --------
    else {
      final requestBody = {
        'item_name': itemName,
        'category_id': categoryId,
        'item_qty': itemQty,
        'item_price': itemPrice,
        'item_note': itemNote,
        'item_sku': itemSku,
        if (miniCategoryId != null) 'mini_category_id': miniCategoryId,
        if (taxClass != null) ...{
          'tax_status': 'taxable',
          'tax_class': taxClass,
        },
      };

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        return AddUpdateItemResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed: ${response.statusCode} ${response.body}');
      }
    }
  }

}