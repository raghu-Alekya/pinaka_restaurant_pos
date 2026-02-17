import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/order/modifier_model.dart';
import '../utils/logger.dart';

class ModifierRepository {
  final String baseUrl;
  final String? token; // JWT token

  ModifierRepository({required this.baseUrl, this.token});

  Future<List<Modifier>> fetchModifiersByProductId(int productId) async {
    if (productId == 0) {
      AppLogger.error('Invalid productId: 0');
      return [];
    }

    final url =
        '$baseUrl/wp-json/pinaka-restaurant-pos/v1/modifiers-addons/get-modifiers-by-product-id?product_id=$productId';
    AppLogger.info('Fetching modifiers from URL: $url');

    try {
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.get(Uri.parse(url), headers: headers);

      AppLogger.info('Response status: ${response.statusCode}');
      AppLogger.info('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> jsonData = decoded['data'] ?? [];

        final modifiers = jsonData.map((item) => Modifier.fromJson(item)).toList();

        AppLogger.info(
            'Fetched ${modifiers.length} modifiers/add-ons for productId: $productId');
        return modifiers;

      } else if (response.statusCode == 403) {
        AppLogger.error('Access forbidden for productId: $productId');
        return [];
      } else {
        throw Exception(
            'Failed to load modifiers for product $productId, status: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error fetching modifiers: $e');
      AppLogger.error(stackTrace.toString());
      return [];
    }
  }

}
