import 'dart:convert';
import 'package:http/http.dart' as http;
// import '../models/category/category.dart';
import '../models/sidebar/category_model_.dart';

class CategoryRepository {
  final String baseUrl;

  CategoryRepository({required this.baseUrl});

  // Fetch all categories for a restaurant
  Future<List<Category>> fetchCategories({
    required String token,
    required String restaurantId,
  }) async {
    final url = Uri.parse('$baseUrl/wp-json/pinaka-restaurant-pos/v1/categories/get-main-courses');


    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );print('API Response: ${response.body}');

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);

      // Use the correct key "category"
      final List data = jsonData['category'] ?? [];
      print('Parsed categories: $data');

      return data.map((json) => Category.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load categories: ${response.statusCode}');
    }

  }
}
