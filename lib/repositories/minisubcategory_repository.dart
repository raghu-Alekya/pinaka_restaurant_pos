import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/constants.dart';
import '../models/category/items_model.dart';
import '../models/category/minisubcategory_model.dart';

class MiniSubCategoryRepository {
  MiniSubCategoryRepository();

  String get baseUrl =>
      AppConstants.baseDomain;

  /// 🔐 Load token safely (APK + Run mode)
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }


  /// Fetch mini-subcategories by subCategoryId
  Future<List<MiniSubCategory>> fetchMiniSubCategories(int subCategoryId) async {
    final token = await _getToken();

    if (token == null || token.isEmpty) {
      throw Exception("Token not available");
    }
    final url = Uri.parse(
      "${AppConstants.baseApiPath}/categories/mini-subcategories?subcategory_id=$subCategoryId",
    );

    print("Fetching mini-subcategories from: $url");

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
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
class ComboRepository {

  String get baseUrl =>
      AppConstants.baseDomain;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  /// 🔥 Fetch combo details by productId
  Future<ComboProduct> fetchComboDetails(int productId) async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      throw Exception("Token not available");
    }

    final url = Uri.parse(
      "${AppConstants.baseApiPath}/combos/search-combos?product_id=$productId",
    );

    debugPrint("🟢 Fetching combo details: $url");

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception("HTTP error ${response.statusCode}");
    }

    final decoded = json.decode(response.body);

    if (decoded['status'] != 'success') {
      throw Exception(decoded['message'] ?? "Combo API error");
    }

    final List data = decoded['data'] ?? [];
    if (data.isEmpty) {
      throw Exception("No combo data found");
    }

    // ✅ CORRECT MODEL
    return ComboProduct.fromJson(data.first);
  }

}
