import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pinaka_restaurant_pos/models/search/search_model.dart';
// import 'package:pinaka_restaurant_pos/models/product/product_model.dart';

import '../constants/constants.dart';
import '../models/category/items_model.dart'; // ✅ Product model

class Search_ProductRepository {
  String get baseUrl =>
      "${AppConstants.baseApiPath}/products-by-category/get-products";
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

  // 🔎 SEARCH PRODUCTS (POS API)
  Future<List<Search_ProductModel>> SearchfetchProducts({
    required String search,
  }) async {
    if (search.trim().length < 2) return [];

    final query = search.trim();

    final Uri uri = Uri.parse("$baseUrl?search=$query");
    final token = await _getToken();

    final response = await http.get(
      uri,
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      },
    );

    if (response.statusCode != 200) {
      throw Exception("Search failed: ${response.statusCode}");
    }

    final decoded = json.decode(response.body);

    // ✅ IMPORTANT FIX
    final List data = decoded['data'] ?? [];

    final products = data
        .map((e) => Search_ProductModel.fromJson(e))
        .toList();

    // 🔍 OPTIONAL: frontend strict filtering
    final lowerQuery = query.toLowerCase();

    return products.where((p) {
      final name = p.name.toLowerCase();
      final sku = p.sku.toLowerCase();
      return name.contains(lowerQuery) || sku.contains(lowerQuery);
    }).toList();
  }
}

