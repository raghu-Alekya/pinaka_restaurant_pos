import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
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

    final cachedData = prefs.getString(_cacheKey);

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

        await prefs.setString(
          _cacheKey,
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