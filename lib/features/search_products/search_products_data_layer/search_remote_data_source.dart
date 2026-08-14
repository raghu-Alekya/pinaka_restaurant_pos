import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:restaurant_captain_app/features/search_products/search_products_data_layer/search_model.dart';
import '../../../utils/api_exception_handler.dart';

abstract class SearchRemoteDataSource {
  Future<SearchResponse> searchProducts({
    required String baseUrl,
    required String token,
    required String query,
  });
}

class SearchRemoteDataSourceImpl implements SearchRemoteDataSource {
  @override
  Future<SearchResponse> searchProducts({
    required String baseUrl,
    required String token,
    required String query,
  }) async {
    try {
      // Encode the query to handle spaces and special characters
      final encodedQuery = Uri.encodeComponent(query);
      final url = '$baseUrl/wp-json/pinaka-restaurant-pos/v1/products-by-category/get-products?search=$encodedQuery';

      print('🔍 Search URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('🔍 Search Status: ${response.statusCode}');
      print('🔍 Search Response: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return SearchResponse.fromJson(jsonData);
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else if (response.statusCode == 404) {
        throw Exception('Search endpoint not found. Please check API URL.');
      } else {
        throw Exception(
          ApiExceptionHandler.parseError(
            response,
            defaultMessage: 'Failed to search products. Status: ${response.statusCode}',
          ),
        );
      }
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } on http.ClientException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Something went wrong while searching. Please try again.');
    }
  }
}