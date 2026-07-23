import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/sidebar/category_model_.dart';
import '../services/api_exception.dart';

class CategoryRepository {
  final String baseUrl;

  CategoryRepository({required this.baseUrl});

  static const String _cacheKey = 'categories_cache';

  Future<List<Category>> fetchCategories({
    required String token,
    required String restaurantId,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Clean up legacy global cache if present
    if (prefs.containsKey(_cacheKey)) {
      await prefs.remove(_cacheKey);
    }

    final scopedCacheKey = '${_cacheKey}_$restaurantId';
    final cachedData = prefs.getString(scopedCacheKey);

    if (cachedData != null) {
      try {
        final List data = jsonDecode(cachedData);
        return data.map((e) => Category.fromJson(e)).toList();
      } catch (_) {}
    }

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

    try {
      final url = Uri.parse(
        '$baseUrl/wp-json/pinaka-restaurant-pos/v1/categories/get-main-courses',
      );

      final response = await ApiExceptionHandler.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print("Category Status Code: ${response.statusCode}");
      print("Category Response: ${response.body}");

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        final List data = jsonData["category"] ?? [];

        final scopedCacheKey = '${_cacheKey}_$restaurantId';
        await prefs.setString(
          scopedCacheKey,
          jsonEncode(data),
        );

        return data
            .map((e) => Category.fromJson(e))
            .toList();
      }

      throw Exception(
        ApiExceptionHandler.parseError(
          response,
          defaultMessage: "Unable to load categories.",
        ),
      );
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }

      throw Exception(
        "Something went wrong while loading categories.",
      );
    }
  }
}