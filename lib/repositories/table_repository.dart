import 'dart:convert';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pinaka_restaurant_pos/repositories/zone_repository.dart';

import '../constants/constants.dart';
import '../local database/table_dao.dart';
import '../utils/logger.dart';

class TableRepository {
  final TableDao tableDao = TableDao();

  /// Create table on server
  Future<Map<String, dynamic>?> createTable({
    required String token,
    required Map<String, dynamic> requestBody,
  }) async {
    final response = await http.post(
      Uri.parse(AppConstants.createTableEndpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(requestBody),
    );

    AppLogger.info('Create Table API Request Body: $requestBody');
    AppLogger.info('Create Table API Status: ${response.statusCode}');
    AppLogger.info('Create Table API Response: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Table creation failed: ${response.body}');
    }
  }

  /// Get all tables from server
  Future<List<Map<String, dynamic>>> getAllTables(String token) async {
    final response = await http.get(
      Uri.parse(AppConstants.getAllTablesEndpoint),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final tableList = decoded['table_details'];
      if (tableList != null && tableList is List) {
        return List<Map<String, dynamic>>.from(tableList);
      } else {
        throw Exception("No table data found.");
      }
    } else {
      throw Exception("Failed to fetch tables: ${response.body}");
    }
  }
  Future<List<Map<String, dynamic>>> getTablesBySlot({
    required String token,
    required String meal,
    required String date,
  }) async {
    final uri = Uri.parse(AppConstants.getAllTablesBySlot(meal, date));

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(json['table_details']);
    } else {
      throw Exception("Failed to load tables: ${response.statusCode}");
    }
  }

  /// Sync tables from server to local database
  Future<void> syncTablesFromServerToLocal(String token) async {
    try {
      final tablesFromServer = await getAllTables(token);
      final savedTableIds = <dynamic>[];

      for (var table in tablesFromServer) {
        final tableId = table['table_id'] ?? table['id'];
        if (tableId == null) {
          AppLogger.warning('Table data missing table_id: $table');
          continue;
        }

        final existingTables = await tableDao.getTablesByTableId(tableId);
        if (existingTables.isNotEmpty) {
          await tableDao.updateTable(tableId, table);
          AppLogger.info('Updated table in local DB with id $tableId');
        } else {
          await tableDao.insertTable(table);
          AppLogger.info('Inserted new table in local DB with id $tableId');
        }

        savedTableIds.add(tableId);
      }

      AppLogger.info('All table IDs saved to local DB: $savedTableIds');
    } catch (e) {
      AppLogger.error('Failed to sync tables from server to local DB: $e');
      rethrow;
    }
  }

  /// Update table on both server and local DB
  Future<void> updateTableOnServerAndLocal({
    required Map<String, dynamic> tableData,
    required String token,
    required String pin,
    required TableDao tableDao,
  }) async {
    final areaName = tableData['areaName'];
    final shape = tableData['shape'];
    final capacity = tableData['capacity'];
    final rotation = tableData['rotation'] ?? 0.0;
    final tableName = tableData['tableName'];
    final position = tableData['position'] as Offset;
    final serverTableId = tableData['table_id'];
    final localTableId = tableData['id'];
    final updateId = localTableId ?? serverTableId;

    if (updateId == null) {
      AppLogger.error('Missing table ID: $tableData');
      return;
    }

    // Get zone details
    final zoneDetails = await ZoneRepository().getZoneDetailsFromServerByAreaName(
      areaName,
      token,
      pin,
    );

    if (zoneDetails['success'] != true) {
      AppLogger.warning('Zone not found: $areaName');
      return;
    }

    final restaurantId = int.tryParse(zoneDetails['restaurant_id'].toString());
    final zoneId = zoneDetails['zone_id'];

    if (restaurantId == null || zoneId == null) {
      AppLogger.error('Invalid zone/restaurant data: $zoneDetails');
      return;
    }

    final payload = {
      "table_name": tableName,
      "restuarant_id": restaurantId,
      "zone_id": zoneId,
      "table_capacity": capacity,
      "table_shape": shape,
      "table_pos_x": position.dx,
      "table_pos_y": position.dy,
      "table_rotation": rotation,
      "table_id": serverTableId,
    };

    try {
      final response = await http.post(
        Uri.parse(AppConstants.updateTableEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );

      AppLogger.info('Update Table Payload: $payload');
      AppLogger.info('Update Table Response: ${response.body}');

      if (response.statusCode == 200) {
        await tableDao.updateTable(updateId, {
          'tableName': tableName,
          'capacity': capacity,
          'shape': shape,
          'areaName': areaName,
          'posX': position.dx,
          'posY': position.dy,
          'rotation': rotation,
          'pin': pin,
          'table_id': serverTableId,
          'zone_id': zoneId,
          'restaurant_id': restaurantId,
        });
      } else {
        AppLogger.error('Failed to update table on server: ${response.body}');
      }
    } catch (e) {
      AppLogger.error('Exception updating table: $e');
    }
  }

  /// Delete table from server
  Future<bool> deleteTableFromServer({
    required int tableId,
    required int zoneId,
    required int restaurantId,
    required String token,
  }) async {
    final url = Uri.parse(AppConstants.deleteTableEndpoint);

    final requestBody = {
      'table_id': tableId,
      'zone_id': zoneId,
      'restaurant_id': restaurantId,
    };

    AppLogger.info('Delete Table API Request: $requestBody');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(requestBody),
    );

    AppLogger.info('Delete Table API Response Status: ${response.statusCode}');
    AppLogger.info('Delete Table API Response Body: ${response.body}');

    if (response.statusCode == 200) {
      AppLogger.info('Table deleted successfully from server (table_id: $tableId)');
      return true;
    } else {
      AppLogger.error('Failed to delete table from server. Status: ${response.statusCode}');
      AppLogger.error('Response body: ${response.body}');
      return false;
    }
  }
  Future<Map<String, dynamic>> getAllSlots(String token, DateTime reservationDate) async {
    final formattedDate = DateFormat('yyyy-MM-dd').format(reservationDate);
    final url = Uri.parse(
      AppConstants.getAllSlotsByDate(formattedDate),
    );

    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load slots');
    }
  }
}