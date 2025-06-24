import '../constants/constants.dart';
import '../helpers/DatabaseHelper.dart';
import '../utils/logger.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ZoneRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int?> getZoneIdByAreaName(String areaName) async {
    return await _dbHelper.getZoneIdByAreaName(areaName);
  }

  Future<Map<String, dynamic>> createZone({
    required String token,
    required String pin,
    required String areaName,
  }) async {
    final url = Uri.parse(AppConstants.createZoneEndpoint);

    AppLogger.info('Sending create zone request: $areaName');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'zone_name': areaName}),
    );

    AppLogger.debug('Zone API Response: ${response.body}');

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final int zoneId = responseData['zone_id'];
      await _dbHelper.insertAreaWithZoneId(areaName, pin, zoneId);

      AppLogger.info('Zone created and saved locally: $areaName with ID: $zoneId');
      return {'success': true, 'zoneId': zoneId, 'areaName': areaName};
    } else {
      String errorMessage = responseData['message'] ?? 'Zone creation failed';
      AppLogger.error('Zone creation failed: $errorMessage');
      return {'success': false, 'message': errorMessage};
    }
  }

  Future<bool> updateZoneName({
    required String token,
    required String pin,
    required String oldAreaName,
    required String newAreaName,
  }) async {
    try {
      int? zoneId = await getZoneIdByAreaName(oldAreaName);

      if (zoneId == null) {
        AppLogger.error('❌ Zone ID not found for area: $oldAreaName');
        return false;
      }

      final url = Uri.parse(AppConstants.updateZoneEndpoint);

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'zone_id': zoneId,
          'pin': int.parse(pin),
          'zone_name': newAreaName,
        }),
      );

      if (response.statusCode == 200) {
        AppLogger.info('✅ Area name updated on server: ${response.body}');
        await _dbHelper.updateAreaName(oldAreaName, newAreaName);
        return true;
      } else {
        AppLogger.error('❌ Failed to update area on server: ${response.body}');
        return false;
      }
    } catch (e) {
      AppLogger.error('❌ Error updating area: $e');
      return false;
    }
  }
}
