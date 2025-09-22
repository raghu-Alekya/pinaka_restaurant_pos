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
        return data.map((item) => Product.fromJson(item)).toList();
      } else {
        throw Exception("Failed to load products: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error fetching products: $e");
    }
  }
  Future<List<Product>> fetchProductsByMiniSubCategory(int miniSubCategoryId) async {
    final response = await http.get(Uri.parse('$baseUrl/products?mini_sub_category_id=$miniSubCategoryId'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.map((e) => Product.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load products for mini subcategory');
    }
  }

  // Fetch variants for a specific product
  // Future<List<Variant>> fetchVariants(int productId) async {
  //   try {
  //     final url = "$baseUrl/wp-json/wc/v3/products/$productId/variations";
  //     final response = await http.get(
  //       Uri.parse(url),
  //       headers: {
  //         "Authorization": "Bearer $token",
  //         "Content-Type": "application/json",
  //       },
  //     );
  //
  //     if (response.statusCode == 200) {
  //       final List<dynamic> data = json.decode(response.body);
  //       return data.map((v) => Variant.fromJson(v)).toList();
  //     } else {
  //       throw Exception("Failed to load variants: ${response.statusCode}");
  //     }
  //   } catch (e) {
  //     throw Exception("Error fetching variants: $e");
  //   }
  // }
}
