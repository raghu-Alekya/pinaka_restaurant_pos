// lib/repository/settings_repository.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/constants.dart';
import '../utils/logger.dart';

class SettingsRepository {
  /// 🔹 Fetch General Settings for a specific user
  Future<Map<String, dynamic>> fetchGeneralSettings({
    required String token,
    required String userId,
  }) async {
    final String apiUrl = '${AppConstants.getGeneralSettingsEndpoint}?user_id=$userId';

    AppLogger.info("Fetching general settings from: $apiUrl");

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      AppLogger.debug("Response Status: ${response.statusCode}");
      AppLogger.debug("Response Body: ${response.body}");

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data["success"] == true) {
        AppLogger.info("✅ General settings fetched successfully");
        return {
          "success": true,
          "data": data["data"],
        };
      } else {
        String message = data["message"] ?? "Failed to load settings";
        AppLogger.warning("❌ Fetch failed: $message");
        return {"success": false, "message": message};
      }
    } catch (e) {
      AppLogger.error("🔥 Exception in fetchGeneralSettings: $e");
      return {"success": false, "message": "Exception: $e"};
    }
  }
}
