import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/category/items_model.dart';

class ProductRepository {
  final String baseUrl;
  final String token;

  ProductRepository({required this.baseUrl, required this.token});

  // Fetch products by subcategory
  Future<List<Product>> fetchProductsBySubCategory(int subCategoryId) async {
    try {
      final url =
          "$baseUrl/wp-json/pinaka-restaurant-pos/v1/products-by-category/$subCategoryId";
      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        // ✅ Map JSON to Product with hasOptions
        final List<Product> items = data.map((json) {
          final modifiers = (json['modifiers'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
              [];
          final addOns = (json['addons'] as Map<String, dynamic>?) ?? {};

          final hasOptions = modifiers.isNotEmpty || addOns.isNotEmpty;

          return Product.fromJson(json).copyWith(hasOptions: hasOptions);
        }).toList();

        return items;
      } else {
        throw Exception("Failed to load products: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error fetching products: $e");
    }
  }

  Future<List<Product>> fetchProductsByMiniSubCategory(int miniSubCategoryId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/products?mini_sub_category_id=$miniSubCategoryId'),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;

      final List<Product> items = data.map((json) {
        final modifiers = (json['modifiers'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
            [];
        final addOns = (json['addons'] as Map<String, dynamic>?) ?? {};

        final hasOptions = modifiers.isNotEmpty || addOns.isNotEmpty;

        return Product.fromJson(json).copyWith(hasOptions: hasOptions);
      }).toList();

      return items;
    } else {
      throw Exception('Failed to load products for mini subcategory');
    }
  }

// Fetch variants for a specific product (optional)
// Future<List<Variant>> fetchVariants(int productId) async { ... }
}
