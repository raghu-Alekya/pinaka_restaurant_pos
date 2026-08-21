import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../utils/api_exception_handler.dart';
import '../models/category_model.dart';

abstract class CategoryRemoteDataSource {
  Future<CategoryResponse> getMainCategories({
    required String baseUrl,
    required String token,
  });
}

class CategoryRemoteDataSourceImpl implements CategoryRemoteDataSource {
  @override
  Future<CategoryResponse> getMainCategories({
    required String baseUrl,
    required String token,
  }) async {
    try {
      print('========== FETCH MAIN CATEGORIES ==========');
      final url = '$baseUrl/wp-json/pinaka-restaurant-pos/v1/categories/get-main-courses';
      print('URL: $url');

      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print('Status: ${response.statusCode}');
      print('Response: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return CategoryResponse.fromJson(jsonData);
      } else {
        throw Exception(
          ApiExceptionHandler.parseError(
            response,
            defaultMessage: 'Failed to load categories.',
          ),
        );
      }
    } catch (e) {
      final friendlyMessage = ApiExceptionHandler.parseException(e);
      print('ERROR: $e -> friendly: $friendlyMessage');
      throw friendlyMessage;
    }
  }
}