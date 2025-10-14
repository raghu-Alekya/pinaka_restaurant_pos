import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/category/items_model.dart';
import '../models/category/minisubcategory_model.dart';

class MiniSubCategoryRepository {
  final String baseUrl;
  final String token;

  MiniSubCategoryRepository({required this.baseUrl, required this.token});

  /// Fetch mini-subcategories by subCategoryId
  Future<List<MiniSubCategory>> fetchMiniSubCategories(int subCategoryId) async {
    final url = Uri.parse("$baseUrl//wp-json/pinaka-restaurant-pos/v1/categories/mini-subcategories?subcategory_id=$subCategoryId");

    print("Fetching mini-subcategories from: $url");

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczpcL1wvbWVyY2hhbnRyZXN0YXVyYW50LmFsZWt0YXNvbHV0aW9ucy5jb20iLCJpYXQiOjE3NTgyNjk5NDcsIm5iZiI6MTc1ODI2OTk0NywiZXhwIjoxNzYwODYxOTQ3LCJkYXRhIjp7InVzZXIiOnsiaWQiOjUsImRldmljZSI6IiIsInBhc3MiOiIyYjhlMjJlOTM2ZTY0N2JhNDRmOWJhMmY3Y2Q1ZmFjNiJ9fX0.WxZtMoMWv6NRDmaLd4Gt1N4_gIW9x25WyGTWIuWVre4',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      print("Response: ${response.body}");
      final data = json.decode(response.body);
      if (data['status'] == 'success') {
        List<MiniSubCategory> miniSubCategories =
        (data['mini_subcategories'] is List)
            ? (data['mini_subcategories'] as List)
            .map((e) => MiniSubCategory.fromJson(e))
            .toList()
            : [];

        return miniSubCategories;
      } else {
        throw Exception("Failed to fetch mini-subcategories: ${data['message'] ?? 'Unknown error'}");
      }
    } else {
      throw Exception("HTTP error: ${response.statusCode}");
    }
  }
  // Future<List<Product>> fetchProducts(int subCategoryId) async {
  //   final id = subCategoryId is int
  //       ? subCategoryId
  //       : int.tryParse(subCategoryId.toString()) ?? 0;
  //
  //   final url = "$baseUrl/wp-json/pinaka-restaurant-pos/v1/products-by-category/$subCategoryId";
  //   final response = await http.get(Uri.parse(url), headers: {"Authorization": "Bearer $token"});
  //
  //   if (response.statusCode == 200) {
  //     final data = jsonDecode(response.body);
  //     List<Product> products = (data['products'] as List)
  //         .map((json) => Product(
  //       id: int.tryParse(json['id'].toString()) ?? 0,
  //       name: json['name'],
  //       price: double.tryParse(json['price'].toString()) ?? 0.0,
  //       image: json['image'] ?? '',
  //       isVeg: json['isVeg'] ?? true,
  //       variants: [], // handle variants if needed
  //     ))
  //         .toList();
  //
  //     return products;
  //   } else {
  //     throw Exception("Failed to load products");
  //   }
  // }

}
