import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/constants.dart';
import '../models/kot_status_count_model.dart';
import '../utils/logger.dart';

class KotStatusCountRepository {
  final String token;

  KotStatusCountRepository({required this.token});

  Future<KotStatusCountModel> fetchKotStatusCount({
    required int restaurantId,
  }) async {
    final url = Uri.parse(
      "${AppConstants.getKotStatusCountEndpoint}?restaurant_id=$restaurantId",
    );

    AppLogger.info("Fetching KOT Status Count: $url");

    try {
      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      AppLogger.info("Status Code: ${response.statusCode}");
      AppLogger.info("Response Body: ${response.body}");

      if (response.statusCode != 200) {
        throw Exception(
          "Failed to fetch KOT Status Count. Status: ${response.statusCode}",
        );
      }

      return KotStatusCountModel.fromJson(
        jsonDecode(response.body),
      );
    } catch (e, st) {
      AppLogger.error("Error fetching KOT Status Count: $e");
      AppLogger.error(st.toString());
      rethrow;
    }
  }
}