import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/constants.dart';
import '../models/category/subcategory_model.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_exception.dart';

class SubCategoryRepository {

  SubCategoryRepository();

  Future<List<SubCategory>> fetchSubCategories({
    required String categoryId,
    required String token,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final cacheKey = 'subcategory_$categoryId';

    // 1. Load cache first
    final cachedData = prefs.getString(cacheKey);

    if (cachedData != null) {
      try {
        final List<dynamic> data = jsonDecode(cachedData);

        return data
            .map((json) => SubCategory.fromJson(json))
            .toList();
      } catch (_) {}
    }

    // 2. No cache -> API
    return await _fetchFromApi(
      categoryId: categoryId,
      token: token,
    );
  }

  Future<List<SubCategory>> refreshSubCategories({
    required String categoryId,
    required String token,
  }) async {
    return await _fetchFromApi(
      categoryId: categoryId,
      token: token,
    );
  }

  Future<List<SubCategory>> _fetchFromApi({
    required String categoryId,
    required String token,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final response = await ApiExceptionHandler.get(
        Uri.parse('${AppConstants.baseApiPath}/categories/get-main-courses'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('API Response: ${response.body}');

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);

        if (body['status'] == "success" && body['category'] != null) {
          final category = (body['category'] as List)
              .cast<Map<String, dynamic>>()
              .firstWhere(
                (cat) => cat['id'].toString() == categoryId.toString(),
            orElse: () => {},
          );

          if (category.isNotEmpty && category['subcategory'] != null) {
            final List<dynamic> subCategoryJson = category['subcategory'];

            // Save cache
            await prefs.setString(
              'subcategory_$categoryId',
              jsonEncode(subCategoryJson),
            );

            final subCategories = subCategoryJson
                .map((json) => SubCategory.fromJson(json))
                .toList();

            return subCategories;
          }
        }

        return [];
      }

      // If response is not 200, parse the error using the common handler
      final errorMessage = ApiExceptionHandler.parseError(
        response,
        defaultMessage: 'Failed to load subcategories',
      );
      throw Exception(errorMessage);
    } catch (e) {
      print('Error fetching subcategories: $e');
      if (e is Exception) {
        rethrow;
      }
      throw Exception(
          'Unexpected error occurred while fetching subcategories.');
    }
  }
}