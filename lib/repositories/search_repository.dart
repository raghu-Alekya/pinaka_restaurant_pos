import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pinaka_restaurant_pos/models/search/search_model.dart';
// import 'package:pinaka_restaurant_pos/models/product/product_model.dart';

import '../models/category/items_model.dart'; // ✅ Product model

class Search_ProductRepository {
  final String baseUrl =
      "https://merchantrestaurant.alektasolutions.com/wp-json/wc/v3/products";

  // 🔐 TOKEN
  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      throw Exception("JWT token missing");
    }

    return token.startsWith('Bearer ')
        ? token.substring(7)
        : token;
  }

  // 🔎 SEARCH PRODUCTS (FAST)
  Future<List<Search_ProductModel>> SearchfetchProducts({String? search}) async {
    if (search == null || search.trim().length < 2) return [];

    final query = search.trim().toLowerCase();
    final isNumeric = RegExp(r'^\d+$').hasMatch(query);

    final Uri uri = isNumeric
        ? Uri.parse("$baseUrl?sku=$query")
        : Uri.parse("$baseUrl?search=$query&per_page=20");

    final token = await _getToken();

    final response = await http.get(
      uri,
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      },
    );

    if (response.statusCode != 200) {
      throw Exception("Search failed");
    }

    final List data = json.decode(response.body);
    final products =
    data.map((e) => Search_ProductModel.fromJson(e)).toList();

    // 🔥 STRICT FILTER
    if (isNumeric) {
      return products.where((p) => p.sku == query).toList();
    }

    return products.where((p) {
      final name = p.name.toLowerCase();
      final sku = p.sku.toLowerCase();
      return name.contains(query) || sku.contains(query);
    }).toList();
  }

  // // 🧬 FETCH FULL PRODUCT (FOR VARIANTS)
  // Future<Product>SearchfetchProductsById(int productId) async {
  //   final token = await _getToken();
  //
  //   final response = await http.get(
  //     Uri.parse("$baseUrl/$productId"),
  //     headers: {
  //       "Authorization": "Bearer $token",
  //       "Accept": "application/json",
  //     },
  //   );
  //
  //   if (response.statusCode == 200) {
  //     return Product.fromJson(json.decode(response.body));
  //   } else {
  //     throw Exception("Failed to fetch product $productId");
  //   }
  // }
}
