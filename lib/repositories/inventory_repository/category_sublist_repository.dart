import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/inventory/category_sublist_model.dart';

class CategorySublistRepository {
  final String baseUrl;

  CategorySublistRepository({required this.baseUrl});

  Future<CategorySublistResponse> fetchCategorySublist({
    required int categoryId,
    required String token,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/wp-json/pinaka-restaurant-pos/v1/inventories/show-category-sublist?category_id=$categoryId',
    );

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return CategorySublistResponse.fromJson(jsonData);
    } else {
      throw Exception(
        'Failed to fetch category sublist: ${response.body}',
      );
    }
  }
}