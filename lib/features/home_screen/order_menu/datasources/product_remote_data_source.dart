import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../utils/api_exception_handler.dart';
import '../models/category_model.dart'; // reuse ProductModel

abstract class ProductRemoteDataSource {
  Future<List<ProductModel>> getProductsByCategory({
    required String baseUrl,
    required String token,
    required int categoryId,
  });
}

class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  @override
  Future<List<ProductModel>> getProductsByCategory({
    required String baseUrl,
    required String token,
    required int categoryId,
  }) async {
    try {
      print('========== FETCH PRODUCTS BY CATEGORY ==========');
      final url = '$baseUrl/wp-json/pinaka-restaurant-pos/v1/products-by-category/$categoryId';
      print('URL: $url');

      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'User-Agent': 'PinakaPOS-Android',
      };

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print('Status: ${response.statusCode}');
      print('Response: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as List;
        return jsonData.map((e) => ProductModel.fromJson(e)).toList();
      } else {
        throw Exception(
          ApiExceptionHandler.parseError(
            response,
            defaultMessage: 'Failed to load products.',
          ),
        );
      }
    } catch (e) {
      print('ERROR: $e');
      rethrow;
    }
  }
}