import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../models/inventory/bev_model.dart';

class ProductRepository {
  static const String baseUrl =
      'https://merchantrestaurant.alektasolutions.com/wp-json/pinaka-restaurant-pos/v1/inventories/get-products-by-name-sku';

  final String token;

  ProductRepository({required this.token});

  Future<Model> getProducts({
    String? search,
    String? sku,
    String? filter,
    int? categoryId,
    int? itemId,
  }) async {
    final Map<String, String> queryParams = {};

    // PRIORITY 1: Fetch by item ID
    if (itemId != null) {
      queryParams['item_id'] = itemId.toString();
    }
    // PRIORITY 2: Search / SKU
    else if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    } else if (sku != null && sku.isNotEmpty) {
      queryParams['barcode'] = sku;
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
        'Authorization': 'Bearer $token', // ✅ use dynamic token
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