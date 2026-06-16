import 'dart:convert';
import 'package:http/http.dart' as http;
// import '../models/category/category.dart';
import '../models/sidebar/category_model_.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CategoryRepository {
  final String baseUrl;

  CategoryRepository({required this.baseUrl});

  static const String _cacheKey = 'categories_cache';

  Future<List<Category>> fetchCategories({
    required String token,
    required String restaurantId,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Load cache first
    final cachedData = prefs.getString(_cacheKey);

    if (cachedData != null) {
      try {
        final List data = jsonDecode(cachedData);
        return data
            .map((json) => Category.fromJson(json))
            .toList();
      } catch (_) {}
    }

    // 2. If no cache, call API
    return await _fetchFromApi(
      token: token,
      restaurantId: restaurantId,
    );
  }

  Future<List<Category>> refreshCategories({
    required String token,
    required String restaurantId,
  }) async {
    return await _fetchFromApi(
      token: token,
      restaurantId: restaurantId,
    );
  }

  Future<List<Category>> _fetchFromApi({
    required String token,
    required String restaurantId,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final url = Uri.parse(
      '$baseUrl/wp-json/pinaka-restaurant-pos/v1/categories/get-main-courses',
    );

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print('API Response: ${response.body}');

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);

      final List data = jsonData['category'] ?? [];

      // Save latest data to cache
      await prefs.setString(
        _cacheKey,
        jsonEncode(data),
      );

      return data
          .map((json) => Category.fromJson(json))
          .toList();
    }

    throw Exception(
      'Failed to load categories: ${response.statusCode}',
    );
  }
}
