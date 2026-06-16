import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category/items_model.dart';

class VariantRepository {
  final String baseUrl;
  final String token;

  VariantRepository({required this.baseUrl, required this.token});

  /// Fetch all variants for a given product ID
  Future<List<Variant>> fetchVariantsByProduct(
      int productId) async {
    try {
      final prefs =
      await SharedPreferences.getInstance();

      final cacheKey =
          'variants_product_$productId';

      // Load cache first
      final cachedData =
      prefs.getString(cacheKey);

      if (cachedData != null) {
        print(
            '📦 Variants loaded from cache');

        final List<dynamic> data =
        jsonDecode(cachedData);

        return data
            .map(
              (jsonItem) =>
              Variant.fromJson(jsonItem),
        )
            .toList();
      }

      print(
          '🌐 Variants loaded from API');

      final url =
          "$baseUrl/wp-json/wc/v3/products/$productId/variations";

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Authorization":
          "Bearer $token",
          "Content-Type":
          "application/json",
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data =
        json.decode(response.body);

        // Save cache
        await prefs.setString(
          cacheKey,
          jsonEncode(data),
        );

        return data
            .map(
              (jsonItem) =>
              Variant.fromJson(jsonItem),
        )
            .toList();
      }

      throw Exception(
        "Failed to load variants: "
            "${response.statusCode} "
            "${response.reasonPhrase}",
      );
    } catch (e) {
      throw Exception(
        "Error fetching variants: $e",
      );
    }
  }
}
