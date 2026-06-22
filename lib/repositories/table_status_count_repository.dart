import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../constants/constants.dart';
import '../models/table_count_model.dart';
// import '../models/table_status_count_model.dart';

class TableStatusCountRepository {
  final String token;

  TableStatusCountRepository({required this.token});

  Future<TableStatusCountModel> fetchTableStatusCounts({
    required int restaurantId,
  }) async {
    try {
      final url = Uri.parse(
        '${AppConstants.baseApiPath}/tables/table-status-counts?restaurant_id=$restaurantId',
      );

      if (kDebugMode) {
        print('📤 Table Status Count API: $url');
      }

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (kDebugMode) {
        print('📥 Status Code: ${response.statusCode}');
        print('📥 Response: ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          return TableStatusCountModel.fromJson(data);
        } else {
          throw Exception(
            data['message'] ?? 'Failed to fetch table status counts',
          );
        }
      } else {
        throw Exception(
          'Failed to load table status counts (${response.statusCode})',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Table Status Count Error: $e');
      }
      rethrow;
    }
  }
}

class ReservationStatusCountRepository {
  final String token;

  ReservationStatusCountRepository({
    required this.token,
  });

  Future<ReservationStatusCountModel> fetchReservationStatusCounts({
    required int restaurantId,
  }) async {
    try {
      final url = Uri.parse(
        '${AppConstants.baseApiPath}/reservation/reservation-status-counts?restaurant_id=$restaurantId',
      );

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ReservationStatusCountModel.fromJson(data);
      }

      throw Exception(
        'Failed to fetch reservation counts: ${response.statusCode}',
      );
    } catch (e) {
      rethrow;
    }
  }
}

class ActiveOrdersCountRepository {
  final String token;

  ActiveOrdersCountRepository({
    required this.token,
  });

  Future<ActiveOrdersCountModel> fetchActiveOrdersCount({
    required int restaurantId,
  }) async {
    try {
      final url = Uri.parse(
        '${AppConstants.baseApiPath}/kot/order-status-counts?restaurant_id=$restaurantId',
      );

      if (kDebugMode) {
        print('📤 Active Orders Count API: $url');
      }

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (kDebugMode) {
        print('📥 Status Code: ${response.statusCode}');
        print('📥 Response: ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ActiveOrdersCountModel.fromJson(data);
      }

      throw Exception(
        'Failed to load active orders count (${response.statusCode})',
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Active Orders Count Error: $e');
      }
      rethrow;
    }
  }
}
