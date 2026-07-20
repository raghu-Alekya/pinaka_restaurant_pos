import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../constants/constants.dart';
import '../models/kot_status_count_model.dart';

class KotOrderCountRepository {
  final String token;

  KotOrderCountRepository({
    required this.token,
  });

  Future<KotOrderCountModel> fetchKotOrderCount() async {
    try {
      final url = Uri.parse(
        '${AppConstants.baseApiPath}/kot/count/',
      );

      if (kDebugMode) {
        print("📤 KOT Order Count API: $url");
      }

      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (kDebugMode) {
        print("📥 Status Code: ${response.statusCode}");
        print("📥 Response: ${response.body}");
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return KotOrderCountModel.fromJson(data);
      }

      throw Exception(
        "Failed to load KOT Order Count (${response.statusCode})",
      );
    } catch (e) {
      if (kDebugMode) {
        print("❌ KOT Order Count Error: $e");
      }
      rethrow;
    }
  }
}