import 'dart:convert';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/tax_model.dart';

class TaxRepository {
  final String _baseUrl =
      'https://merchantrestaurant.alektasolutions.com/wp-json/wc/v3/taxes';

  /// 🔐 Always read JWT from storage
  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      throw Exception("JWT token missing");
    }

    // ✅ Normalize token (handles old stored "Bearer xxx")
    return token.startsWith('Bearer ')
        ? token.substring(7)
        : token;
  }

  Future<List<TaxModel>> fetchTaxes() async {
    final token = await _getToken();

    if (kDebugMode) {
      print("🔐 TAX TOKEN => $token");
      print("🔐 HEADER   => Bearer $token");
    }

    final response = await http.get(
      Uri.parse(_baseUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    // 🔍 DEBUG PRINTS
    print('TAX API STATUS CODE: ${response.statusCode}');
    print('TAX API RAW RESPONSE: ${response.body}');

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((e) => TaxModel.fromJson(e)).toList();
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception("Unauthorized – JWT expired or invalid");
    }

    throw Exception('Failed to load taxes');
  }
}
