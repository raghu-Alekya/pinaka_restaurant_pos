import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../utils/api_exception_handler.dart';
import '../models/mini_subcategory_model.dart';

abstract class MiniSubcategoryRemoteDataSource {
  Future<MiniSubcategoryResponse> getMiniSubcategories({
    required String baseUrl,
    required String token,
    required int subcategoryId,
  });
}

class MiniSubcategoryRemoteDataSourceImpl implements MiniSubcategoryRemoteDataSource {
  @override
  Future<MiniSubcategoryResponse> getMiniSubcategories({
    required String baseUrl,
    required String token,
    required int subcategoryId,
  }) async {
    try {
      print('========== FETCH MINI SUBCATEGORIES ==========');
      final url = '$baseUrl/wp-json/pinaka-restaurant-pos/v1/categories/mini-subcategories?subcategory_id=$subcategoryId';
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
        return MiniSubcategoryResponse.fromJson(jsonData);
      } else {
        throw Exception(
          ApiExceptionHandler.parseError(
            response,
            defaultMessage: 'Failed to load mini-subcategories.',
          ),
        );
      }
    } catch (e) {
      print('ERROR: $e');
      rethrow;
    }
  }
}