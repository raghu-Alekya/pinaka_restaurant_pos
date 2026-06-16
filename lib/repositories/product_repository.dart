import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category/items_model.dart';



class ProductRepository {
  final String baseUrl;
  // final String token;

  ProductRepository({required this.baseUrl});

  /// 🔐 Load token safely (APK + Run mode)
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Fetch products by subcategory
  Future<List<Product>> fetchProductsBySubCategory(
      int subCategoryId) async {

    final prefs = await SharedPreferences.getInstance();

    final cacheKey =
        'products_subcategory_$subCategoryId';

    // Load cache first
    final cachedData =
    prefs.getString(cacheKey);

    if (cachedData != null) {
      print(
          '📦 Products loaded from cache');

      final List<dynamic> data =
      jsonDecode(cachedData);

      return data.map((json) {
        final modifiers =
            (json['modifiers']
            as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
                [];

        final addOns =
            (json['addons']
            as Map<String, dynamic>?) ??
                {};

        final hasOptions =
            modifiers.isNotEmpty ||
                addOns.isNotEmpty;

        return Product.fromJson(json)
            .copyWith(
          hasOptions: hasOptions,
        );
      }).toList();
    }

    print('🌐 Products loaded from API');

    final token = await _getToken();

    if (token == null || token.isEmpty) {
      throw Exception("Token not available");
    }

    final url =
        "$baseUrl/wp-json/pinaka-restaurant-pos/v1/products-by-category/$subCategoryId";

    final response = await http.get(
      Uri.parse(url),
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
        "Content-Type": "application/json",
        "User-Agent": "PinakaPOS-Android",
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data =
      json.decode(response.body);

      // Save API response in cache
      await prefs.setString(
        cacheKey,
        jsonEncode(data),
      );

      return data.map((json) {
        final modifiers =
            (json['modifiers']
            as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
                [];

        final addOns =
            (json['addons']
            as Map<String, dynamic>?) ??
                {};

        final hasOptions =
            modifiers.isNotEmpty ||
                addOns.isNotEmpty;

        return Product.fromJson(json)
            .copyWith(
          hasOptions: hasOptions,
        );
      }).toList();
    }

    throw Exception(
        "Failed to load products");
  }


  // Future<List<Product>> fetchProductsByMiniSubCategory(
  //     int miniSubCategoryId) async {
  //
  //   final prefs = await SharedPreferences.getInstance();
  //
  //   final cacheKey =
  //       'products_mini_subcategory_$miniSubCategoryId';
  //
  //   // Load cache first
  //   final cachedData = prefs.getString(cacheKey);
  //
  //   if (cachedData != null) {
  //     print('📦 Mini SubCategory Products loaded from cache');
  //
  //     final List<dynamic> data =
  //     jsonDecode(cachedData);
  //
  //     return data.map((json) {
  //       final modifiers =
  //           (json['modifiers'] as List<dynamic>?)
  //               ?.map((e) => e.toString())
  //               .toList() ??
  //               [];
  //
  //       final addOns =
  //           (json['addons'] as Map<String, dynamic>?) ?? {};
  //
  //       final hasOptions =
  //           modifiers.isNotEmpty || addOns.isNotEmpty;
  //
  //       return Product.fromJson(json)
  //           .copyWith(hasOptions: hasOptions);
  //     }).toList();
  //   }
  //
  //   print('🌐 Mini SubCategory Products loaded from API');
  //
  //   final token = await _getToken();
  //
  //   if (token == null || token.isEmpty) {
  //     throw Exception("Token not available");
  //   }
  //
  //   final url = Uri.parse(
  //     '$baseUrl/products?mini_sub_category_id=$miniSubCategoryId',
  //   );
  //
  //   final response = await http.get(
  //     url,
  //     headers: {
  //       "Authorization": "Bearer $token",
  //       "Accept": "application/json",
  //       "Content-Type": "application/json",
  //       "User-Agent": "PinakaPOS-Android",
  //     },
  //   );
  //
  //   if (response.statusCode == 200) {
  //     final List<dynamic> data =
  //     jsonDecode(response.body);
  //
  //     // Save cache
  //     await prefs.setString(
  //       cacheKey,
  //       jsonEncode(data),
  //     );
  //
  //     return data.map((json) {
  //       final modifiers =
  //           (json['modifiers'] as List<dynamic>?)
  //               ?.map((e) => e.toString())
  //               .toList() ??
  //               [];
  //
  //       final addOns =
  //           (json['addons'] as Map<String, dynamic>?) ?? {};
  //
  //       final hasOptions =
  //           modifiers.isNotEmpty || addOns.isNotEmpty;
  //
  //       return Product.fromJson(json)
  //           .copyWith(hasOptions: hasOptions);
  //     }).toList();
  //   }
  //
  //   print("❌ STATUS: ${response.statusCode}");
  //   print("❌ BODY: ${response.body}");
  //
  //   throw Exception(
  //       'Failed to load products for mini subcategory');
  // }
// Fetch variants for a specific product (optional)
// Future<List<Variant>> fetchVariants(int productId) async { ... }
}
