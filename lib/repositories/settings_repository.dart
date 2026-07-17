// // lib/repository/settings_repository.dart
//
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import '../constants/constants.dart';
// import '../utils/logger.dart';
//
// class SettingsRepository {
//   /// 🔹 Fetch General Settings for a specific user
//   Future<Map<String, dynamic>> fetchGeneralSettings({
//     required String token,
//     required String userId,
//   }) async {
//     final String apiUrl = '${AppConstants.getGeneralSettingsEndpoint}?user_id=$userId';
//
//     AppLogger.info("Fetching general settings from: $apiUrl");
//
//     try {
//       final response = await http.get(
//         Uri.parse(apiUrl),
//         headers: {
//           "Authorization": "Bearer $token",
//           "Content-Type": "application/json",
//         },
//       );
//
//       AppLogger.debug("Response Status: ${response.statusCode}");
//       AppLogger.debug("Response Body: ${response.body}");
//
//       final data = jsonDecode(response.body);
//
//       if (response.statusCode == 200 && data["success"] == true) {
//         AppLogger.info("✅ General settings fetched successfully");
//         return {
//           "success": true,
//           "data": data["data"],
//         };
//       } else {
//         String message = data["message"] ?? "Failed to load settings";
//         AppLogger.warning("❌ Fetch failed: $message");
//         return {"success": false, "message": message};
//       }
//     } catch (e) {
//       AppLogger.error("🔥 Exception in fetchGeneralSettings: $e");
//       return {"success": false, "message": "Exception: $e"};
//     }
//   }
// }
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../constants/constants.dart';
import '../models/General_Settings_Model.dart';
import '../utils/logger.dart';

class GeneralSettingsRepository {
  Future<Map<String, dynamic>> fetchGeneralSettings({
    required String token,
  }) async {
    final String apiUrl = AppConstants.getGeneralSettingsEndpoint;

    AppLogger.info("Fetching General Settings: $apiUrl");

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      AppLogger.debug("Status Codess: ${response.statusCode}");
      AppLogger.debug("Response Body: ${response.body}");

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data["success"] == true) {
        return data;
      } else {
        throw Exception(data["message"] ?? "Failed to fetch settings");
      }
    } catch (e) {
      AppLogger.error("Exception: $e");
      rethrow;
    }
  }
  Future<SaveGeneralSettingsResponse> saveGeneralSettings({
    required String token,
    required SaveGeneralSettingsRequest request,
  }) async {
    final url = AppConstants.saveGeneralSettingsEndpoint;

    AppLogger.info("Saving General Settings: $url");

    final response = await http.post(
      Uri.parse(url),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(request.toJson()),
    );

    AppLogger.debug("Status Code: ${response.statusCode}");
    AppLogger.debug("Response: ${response.body}");

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);

      if (json["success"] == true) {
        return SaveGeneralSettingsResponse.fromJson(json);
      } else {
        throw Exception(json["message"] ?? "Failed to save settings");
      }
    } else {
      throw Exception(
        "Failed to save settings (${response.statusCode})",
      );
    }
  }
  Future<String> uploadImage({
    required String token,
    required String imagePath,
  }) async {
    final file = File(imagePath);
    final fileName = file.path.split('/').last;

    final uri = Uri.parse(AppConstants.uploadMediaEndpoint);

    final request = http.MultipartRequest('POST', uri);

    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Content-Disposition': 'attachment; filename="$fileName"',
    });

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        imagePath,
        filename: fileName,
      ),
    );

    final streamedResponse = await request.send();
    final responseBody = await streamedResponse.stream.bytesToString();

    if (streamedResponse.statusCode == 200 ||
        streamedResponse.statusCode == 201) {
      final json = jsonDecode(responseBody);
      return json["source_url"];
    }

    throw Exception(responseBody);
  }
  Future<void> editProfileImage({
    required String token,
    required String profileImageUrl,
  }) async {
    final response = await http.post(
      Uri.parse(AppConstants.editProfileImageEndpoint),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "profile_image_url": profileImageUrl,
      }),
    );

    AppLogger.debug(response.body);

    final json = jsonDecode(response.body);

    if (response.statusCode != 200 || json["success"] != true) {
      throw Exception(json["message"] ?? "Failed to update profile image");
    }
  }
  Future<void> editReceiptImage({
    required String token,
    required String receiptLogoUrl,
  }) async {
    final response = await http.post(
      Uri.parse(AppConstants.editReceiptImageEndpoint),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "receipt_logo_url": receiptLogoUrl,
      }),
    );

    AppLogger.debug(response.body);

    final json = jsonDecode(response.body);

    if (response.statusCode != 200 || json["success"] != true) {
      throw Exception(json["message"] ?? "Failed to update receipt logo");
    }
  }

}