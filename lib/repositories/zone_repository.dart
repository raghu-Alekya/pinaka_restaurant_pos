import 'dart:ui';

import '../Manager flow/widgets/table_helpers.dart';
import '../constants/constants.dart';
import '../local database/area_dao.dart';
import '../local database/table_dao.dart';
import '../utils/logger.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ZoneRepository {
  final areaDao = AreaDao();

  /// ✅ Fetches zone_id, restaurant_id, and restaurant_name from server using area name
  Future<Map<String, dynamic>?> getZoneDetailsFromServerByAreaName(String areaName, String token) async {
    final url = Uri.parse(AppConstants.getAllZonesEndpoint);

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      AppLogger.debug('Get All Zones (for zone lookup) Response: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true && responseData['zone_details'] is List) {
          final List zones = responseData['zone_details'];
          for (var zone in zones) {
            if (zone['zone_name'] == areaName) {
              return {
                'zone_id': zone['zone_id'],
                'restaurant_id': zone['restaurant_id'],
                'restaurant_name': zone['restaurant_name'],
              };
            }
          }
          AppLogger.error('Zone not found on server for areaName: $areaName');
          return null;
        } else {
          AppLogger.error('Invalid response format from getAllZones');
          return null;
        }
      } else {
        AppLogger.error('Failed to fetch zones from server: ${response.body}');
        return null;
      }
    } catch (e) {
      AppLogger.error('Exception during zone fetch: $e');
      return null;
    }
  }


  Future<Map<String, dynamic>> createZone({
    required String token,
    required String pin,
    required String areaName,
    required String restaurantId,
  }) async {
    final url = Uri.parse(AppConstants.createZoneEndpoint);

    AppLogger.info('Sending create zone request: $areaName for restaurant ID: $restaurantId');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'zone_name': areaName,
        'restaurant_id': restaurantId,
      }),
    );

    AppLogger.debug('Zone API Response: ${response.body}');

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final int zoneId = responseData['zone_id'];
      final String zoneStatus = responseData['zone_status'] ?? 'unknown';

      await areaDao.insertArea(areaName, pin, zoneId);

      AppLogger.info('Zone created and saved locally: $areaName with ID: $zoneId and status: $zoneStatus');

      return {
        'success': true,
        'zoneId': zoneId,
        'areaName': areaName,
        'zoneStatus': zoneStatus,
      };
    } else {
      String errorMessage = responseData['message'] ?? 'Zone creation failed';
      AppLogger.error('Zone creation failed: $errorMessage');
      return {'success': false, 'message': errorMessage};
    }
  }

  /// ✅ Updates zone name using server zone_id (fetched via area name)
  Future<bool> updateZoneName({
    required String token,
    required String pin,
    required String oldAreaName,
    required String newAreaName,
  }) async {
    // ✅ Fetch zone details
    final zoneDetails = await getZoneDetailsFromServerByAreaName(oldAreaName, token);

    if (zoneDetails == null || zoneDetails['zone_id'] == null) {
      AppLogger.error('Zone ID not found for area: $oldAreaName');
      return false;
    }

    final int zoneId = zoneDetails['zone_id'];

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

    AppLogger.debug('Update Zone Response: ${response.body}');

    if (response.statusCode == 200) {
      // ✅ Update name locally too
      await areaDao.updateAreaName(oldAreaName, newAreaName);
      AppLogger.info('Zone name updated locally and remotely from "$oldAreaName" to "$newAreaName"');
      return true;
    } else {
      AppLogger.error('Failed to update zone name: ${response.body}');
      return false;
    }
  }


  /// ✅ Fetches all zones from the server
  Future<List<Map<String, dynamic>>> getAllZones(String token) async {
    final url = Uri.parse(AppConstants.getAllZonesEndpoint);

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      AppLogger.debug('Get All Zones Response: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['success'] == true && responseData['zone_details'] is List) {
          final List zoneDetails = responseData['zone_details'];
          return zoneDetails.map<Map<String, dynamic>>((zone) {
            return {
              'zone_id': zone['zone_id'],
              'zone_name': zone['zone_name'],
            };
          }).toList();
        } else {
          AppLogger.error('Unexpected data structure in response');
          return [];
        }
      } else {
        AppLogger.error('Failed to fetch zones: ${response.body}');
        return [];
      }
    } catch (e) {
      AppLogger.error('Exception while fetching zones: $e');
      return [];
    }
  }

  /// ✅ Deletes a zone using zone_id
  Future<bool> deleteZone({
    required String token,
    required int zoneId,
  }) async {
    final url = Uri.parse(AppConstants.deleteZoneEndpoint);

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'zone_id': zoneId}),
      );

      AppLogger.debug('Delete Zone Response: ${response.body}');

      if (response.statusCode == 200) {
        return true;
      } else {
        AppLogger.error('Failed to delete zone: ${response.body}');
        return false;
      }
    } catch (e) {
      AppLogger.error('Exception while deleting zone: $e');
      return false;
    }
  }

}
