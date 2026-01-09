import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../models/inventory/bev_model.dart';
// import '../models/inventory/bevmodel.dart';

class ProductRepository {
  static const String baseUrl =
      'https://merchantrestaurant.alektasolutions.com/wp-json/pinaka-restaurant-pos/v1/inventories/get-products-by-name-sku';

  // 🔐 Ideally store token securely (Hive / SecureStorage)
  final String token =
      'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczpcL1wvbWVyY2hhbnRyZXN0YXVyYW50LmFsZWt0YXNvbHV0aW9ucy5jb20iLCJpYXQiOjE3NjczNDM5NzksIm5iZiI6MTc2NzM0Mzk3OSwiZXhwIjoxNzY5OTM1OTc5LCJkYXRhIjp7InVzZXIiOnsiaWQiOjUsImRldmljZSI6IiIsInBhc3MiOiIyYjhlMjJlOTM2ZTY0N2JhNDRmOWJhMmY3Y2Q1ZmFjNiJ9fX0.2i80aj2lDtVOCj_yckQw_JP1ScM4r7f6f5ilHBP0fGk'; // shortened

  Future<Model> getProducts({
    String? search,
    String? sku,
    String? filter,
    int? categoryId,
    int? itemId,
  }) async {
    final Map<String, String> queryParams = {};

    // ✅ PRIORITY 1: Fetch by item ID
    if (itemId != null) {
      queryParams['item_id'] = itemId.toString();
    }
    // ✅ PRIORITY 2: Search / SKU
    else if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    } else if (sku != null && sku.isNotEmpty) {
      queryParams['sku'] = sku;
    }

    if (filter != null && filter.isNotEmpty) {
      queryParams['filter'] = filter;
    }

    if (categoryId != null && itemId == null) {
      queryParams['category_id'] = categoryId.toString();
    }

    final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);

    print('================ PRODUCT API CALL ================');
    print('➡️ URL: $uri');
    print('➡️ Query Params: $queryParams');

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print('⬅️ Status Code: ${response.statusCode}');
    print('⬅️ Response Body: ${response.body}');
    print('=================================================');

    if (response.statusCode == 200) {
      return Model.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(
        'Failed to fetch products: ${response.statusCode} ${response.body}',
      );
    }
  }
}