import '../constants/constants.dart';
import '../local database/area_dao.dart';
import '../local database/login_dao.dart';
import '../utils/logger.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ZoneRepository {
  final areaDao = AreaDao();
  final loginDao = LoginDao();

  /// ✅ Fetches zone_id, restaurant_id, and restaurant_name from server using area name
  Future<Map<String, dynamic>> getZoneDetailsFromServerByAreaName(
      String areaName,
      String token, [
        String? pin,
      ]) async {
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
            if (zone['zone_name'].toString().trim().toLowerCase() ==
                areaName.trim().toLowerCase()) {
              return {
                'success': true,
                'zone_id': zone['zone_id'],
                'restaurant_id': zone['restaurant_id'],
                'restaurant_name': zone['restaurant_name'],
                'source': 'server',
              };
            }
          }

          AppLogger.warning('Zone not found on server for areaName: $areaName');
        } else {
          AppLogger.error('Invalid response format from getAllZones');
        }
      } else {
        AppLogger.error('Failed to fetch zones from server: ${response.body}');
      }
    } catch (e) {
      AppLogger.error('Exception during zone fetch: $e');
    }

    // ✅ Fallback to local DB if pin is provided
    if (pin != null) {
      AppLogger.info('Falling back to local DB for area "$areaName" and PIN "$pin"');

      final db = await areaDao.getDb();
      final result = await db.query(
        'areas',
        where: 'areaName = ? AND pin = ?',
        whereArgs: [areaName, pin],
      );

      if (result.isNotEmpty) {
        final row = result.first;

        // Get restaurant_id and restaurant_name from login
        final login = await loginDao.getLatestLogin();

        return {
          'success': true,
          'zone_id': row['zoneId'],
          'restaurant_id': login?['restaurant_id'],
          'restaurant_name': login?['restaurant_name'],
          'source': 'local',
        };
      } else {
        AppLogger.warning('Zone "$areaName" not found in local DB for PIN "$pin"');
      }
    }
    return {
      'success': false,
      'zone_id': null,
      'restaurant_id': null,
      'restaurant_name': null,
      'source': 'none',
      'message': 'Zone not found on server or local DB',
    };
  }


  /// ✅ Create zone on server and insert locally
  Future<Map<String, dynamic>> createZone({
    required String token,
    required String pin,
    required String areaName,
    required String restaurantId,
  }) async {
    final url = Uri.parse(AppConstants.createZoneEndpoint);

    AppLogger.info('Sending create zone request: $areaName for restaurant ID: $restaurantId');

    try {
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
    } catch (e) {
      AppLogger.error('Exception during zone creation: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// ✅ Update zone name on server and locally
  Future<bool> updateZoneName({
    required String token,
    required String pin,
    required String oldAreaName,
    required String newAreaName,
  }) async {
    final zoneDetails = await getZoneDetailsFromServerByAreaName(oldAreaName, token);

    if (zoneDetails == null || zoneDetails['zone_id'] == null) {
      AppLogger.error('Zone ID not found for area: $oldAreaName');
      return false;
    }

    final int zoneId = zoneDetails['zone_id'];
    final url = Uri.parse(AppConstants.updateZoneEndpoint);

    try {
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
        await areaDao.updateAreaName(oldAreaName, newAreaName);
        AppLogger.info('Zone name updated locally and remotely from "$oldAreaName" to "$newAreaName"');
        return true;
      } else {
        AppLogger.error('Failed to update zone name: ${response.body}');
        return false;
      }
    } catch (e) {
      AppLogger.error('Exception while updating zone: $e');
      return false;
    }
  }

  /// ✅ Get all zones from server and return as a list
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

  /// ✅ Delete zone from server and local DB
  Future<bool> deleteZone({
    required String token,
    required int zoneId,
    required String areaName,
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
        await areaDao.deleteArea(areaName);
        AppLogger.info('Zone "$areaName" deleted from server and local DB.');
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
