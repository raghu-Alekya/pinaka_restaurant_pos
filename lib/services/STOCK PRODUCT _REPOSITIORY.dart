import 'dart:convert';
import 'package:http/http.dart' as http;

class ProductRepository {
  final String baseUrl;
  final String token;

  ProductRepository({
    required this.baseUrl,
    required this.token,
  });

  // ==========================================================
  // GET PRODUCTS
  // ==========================================================

  Future<List<Map<String, dynamic>>> fetchProducts() async {
    final url = Uri.parse(
      '$baseUrl/wp-json/pinaka-restaurant-pos/v1/products',
    );

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print(
        'PRODUCT API STATUS: ${response.statusCode}',
      );

      print(
        'PRODUCT API RESPONSE: ${response.body}',
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded is List) {
          return decoded
              .map(
                (e) => Map<String, dynamic>.from(e),
          )
              .toList();
        }

        // API response:
        // {
        //   "products": [...]
        // }

        if (decoded is Map &&
            decoded['products'] is List) {
          return (decoded['products'] as List)
              .map(
                (e) => Map<String, dynamic>.from(e),
          )
              .toList();
        }

        return [];
      }

      throw Exception(
        'Failed to fetch products: '
            '${response.statusCode}',
      );
    } catch (e) {
      print(
        'PRODUCT API ERROR: $e',
      );

      rethrow;
    }
  }

  // ==========================================================
  // UPDATE PRODUCT STOCK STATUS
  // ==========================================================

  Future<bool> updateProductStatus({
    required int productId,
    required String status,
    required String pin,
  }) async {
    final url = Uri.parse(
      '$baseUrl/wp-json/pinaka-restaurant-pos/v1/products/status',
    );

    try {
      final requestBody = {
        'product_id': productId,
        'status': status,
        'pin': pin,
      };

      print(
        '==========================================',
      );

      print(
        'UPDATE PRODUCT STATUS API',
      );

      print(
        'URL: $url',
      );

      print(
        'REQUEST BODY: '
            '${jsonEncode(requestBody)}',
      );

      print(
        '==========================================',
      );

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print(
        'UPDATE STATUS CODE: '
            '${response.statusCode}',
      );

      print(
        'UPDATE STATUS RESPONSE: '
            '${response.body}',
      );

      // ==========================================
      // SUCCESS
      // ==========================================

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        return true;
      }

      // ==========================================
      // ERROR
      // ==========================================

      throw Exception(
        'Failed to update product status. '
            'Status code: ${response.statusCode}, '
            'Response: ${response.body}',
      );
    } catch (e) {
      print(
        'UPDATE PRODUCT STATUS ERROR: $e',
      );

      rethrow;
    }
  }
}