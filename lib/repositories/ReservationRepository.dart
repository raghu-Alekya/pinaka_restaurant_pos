import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../App flow/widgets/area_movement_notifier.dart';
import '../constants/constants.dart';
import '../utils/logger.dart';

class ReservationRepository {
  Future<DateTimeRange?> getReservationDateRange(String token) async {
    final url = Uri.parse(
      '${AppConstants.baseApiPath}/reservation/reservation-date-range',
    );

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        AppLogger.info("API response: $data");

        final startDateStr = data['start_date'];
        final endDateStr = data['end_date'];

        if (startDateStr == null || endDateStr == null) {
          AppLogger.warning("start_date or end_date is null");
          return null;
        }
        final formatter = DateFormat('yyyy-MM-dd');
        final startDate = formatter.parse(startDateStr);
        final endDate = formatter.parse(endDateStr);

        return DateTimeRange(start: startDate, end: endDate);
      } else {
        AppLogger.error("HTTP ${response.statusCode}: ${response.body}");
      }
    } catch (e, stack) {
      AppLogger.error("Exception in getReservationDateRange: $e\n$stack");
    }
    return null;
  }
  Future<Map<String, dynamic>?> createReservation({
    required BuildContext context,
    required String token,
    required int people,
    required String name,
    required String phone,
    required DateTime date,
    required String time,
    required String tableNo,
    required String slotType,
    required String zoneName,
    required String restaurantName,
    required int restaurantId,
    required String priority,
  }) async {
    final uri = Uri.parse(
      'https://merchantrestaurant.alektasolutions.com/wp-json/pinaka-restaurant-pos/v1/reservation/create-reservation',
    );

    final body = {
      "no_of_people": people,
      "customer_name": name,
      "customer_phone": phone,
      "reservation_date": DateFormat('yyyy-MM-dd').format(date),
      "reservation_time": time,
      "table_no": tableNo,
      "table_status": "Reserve",
      "slot_type": slotType,
      "zone_name": zoneName,
      "restaurant_name": restaurantName,
      "restaurant_id": restaurantId,
      "priority_category": priority,
    };

    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      final result = jsonDecode(response.body);

      final String message = result['message'] ?? 'Unknown response';

      if (response.statusCode == 200 && result['success'] == true) {
        AreaMovementNotifier.showPopup(
          context: context,
          fromArea: '',
          toArea: '',
          tableName: '',
          customMessage: message,
        );
        return result;
      } else {
        AreaMovementNotifier.showPopup(
          context: context,
          fromArea: '',
          toArea: '',
          tableName: '',
          customMessage: message,
        );
      }
    } catch (e, stack) {
      AppLogger.error("Exception in createReservation: $e\n$stack");

      AreaMovementNotifier.showPopup(
        context: context,
        fromArea: '',
        toArea: '',
        tableName: '',
        customMessage: 'Reservation failed. Please try again.',
      );
    }

    return null;
  }
}
