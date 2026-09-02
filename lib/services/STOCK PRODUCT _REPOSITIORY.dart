import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

import '../widgets/stock_screen.dart';

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

  Future<bool> updateMultipleProductStatus({
    required List<Map<String, dynamic>> products,
    required String pin,
  }) async {
    final url = Uri.parse(
      '$baseUrl/wp-json/pinaka-restaurant-pos/v1/products/status',
    );

    try {
      final requestBody = {
        'products': products,
        'pin': pin,
      };

      debugPrint('==========================================');
      debugPrint('BULK UPDATE PRODUCT STATUS API');
      debugPrint('URL: $url');
      debugPrint('PRODUCT COUNT: ${products.length}');
      debugPrint(
        'REQUEST BODY: ${jsonEncode(requestBody)}',
      );
      debugPrint('==========================================');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      debugPrint(
        'UPDATE STATUS CODE: ${response.statusCode}',
      );

      debugPrint(
        'UPDATE STATUS RESPONSE: ${response.body}',
      );

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        return true;
      }

      throw Exception(
        'Failed to update product status. '
            'Status code: ${response.statusCode}, '
            'Response: ${response.body}',
      );
    } catch (e) {
      debugPrint(
        'BULK UPDATE PRODUCT STATUS ERROR: $e',
      );

      rethrow;
    }
  }
}