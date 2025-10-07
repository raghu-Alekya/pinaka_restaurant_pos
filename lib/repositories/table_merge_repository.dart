import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/constants.dart';
import '../utils/logger.dart';

class TableMergeRepository {
  Future<Map<String, dynamic>> fetchMergeTables(String token) async {
    final url = Uri.parse(AppConstants.getAllMergeTablesEndpoint);

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    AppLogger.info("Fetch Merge Tables Response: ${response.statusCode} - ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      AppLogger.debug("Parsed Merge Tables Data: $data");
      return data;
    } else {
      AppLogger.error("Failed to fetch merge tables: ${response.body}");
      throw Exception("Failed to fetch merge tables: ${response.body}");
    }
  }

  Future<Map<String, dynamic>> createMergeTables({
    required String token,
    required int restaurantId,
    required String zoneName,
    required int parentTableId,
    required List<int> childTableIds,
  }) async {
    final url = Uri.parse(AppConstants.createMergeTablesWithStatusEndpoint);

    final body = {
      "restaurant_id": restaurantId,
      "zone_name": zoneName,
      "parent_table_id": parentTableId,
      "child_table_ids": childTableIds,
    };

    AppLogger.info("Create Merge Tables Request: $body");

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    AppLogger.info("Create Merge Tables Response: ${response.statusCode} - ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data;
    } else {
      throw Exception("Failed to create merge tables: ${response.body}");
    }
  }


  Future<Map<String, dynamic>> updateMergeTablesWithStatus({
    required String token,
    required int restaurantId,
    required String zoneName,
    required int parentTableId,
    required List<int> childTableIds,
  }) async {
    final url = Uri.parse(AppConstants.updateMergeTablesWithStatusEndpoint);
    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "restaurant_id": restaurantId,
        "zone_name": zoneName,
        "parent_table_id": parentTableId,
        "child_table_ids": childTableIds,
      }),
    );
    return jsonDecode(response.body);
  }
  Future<Map<String, dynamic>> deleteMergeTable({
    required String token,
    required int parentTableId,
    required int zoneId,
    required int restaurantId,
  }) async {
    final url = Uri.parse(AppConstants.deleteMergeTablesWithStatusEndpoint);

    final body = {
      "parent_table_id": parentTableId,
      "zone_id": zoneId,
      "restaurant_id": restaurantId,
    };

    AppLogger.info("Delete Merge Table Request: $body");

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    AppLogger.info("Delete Merge Table Response: ${response.statusCode} - ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to delete merge table: ${response.body}");
    }
  }
}

