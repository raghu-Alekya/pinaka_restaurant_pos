import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/constants.dart';
import '../utils/logger.dart';

class EmployeeRepository {
  Future<List<Map<String, dynamic>>> getAllEmployees(String token) async {
    final response = await http.get(
      Uri.parse(AppConstants.getAllEmployeesEndpoint),
      headers: {'Authorization': 'Bearer $token'},
    );

    AppLogger.info(
      'All Employees Response (${response.statusCode}): ${response.body}',
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      AppLogger.error('Failed to load employees: ${response.body}');
      throw Exception('Failed to load employees: ${response.body}');
    }
  }

  Future<int> createShift({
    required String token,
    required String shiftDate,
    required String startTime,
    required List<int> employeeIds,
    required List<int> absentEmployeeIds,
  }) async {
    final url = Uri.parse(
      'https://merchantrestaurant.alektasolutions.com/wp-json/pinaka-restaurant-pos/v1/shifts/create-shift',
    );

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'status': 'open',
        'shift_date': shiftDate,
        'start_time': startTime,
        'shift_emp': employeeIds,
        'shift_absent_emp': absentEmployeeIds,
      }),
    );

    if (response.statusCode == 200) {
      if (response.body.isEmpty) {
        throw FormatException(
          "Empty response body. Possible open shift not closed.",
        );
      }

      final body = jsonDecode(response.body);
      if (!body.containsKey('shift_id')) {
        throw FormatException(
          "No shift_id in response. Possibly an active shift already exists.",
        );
      }

      return body['shift_id'];
    } else {
      throw Exception(
        "Failed to create shift. Status code: ${response.statusCode}",
      );
    }
  }

  Future<List<String>> getAllShifts(String token) async {
    final response = await http.get(
      Uri.parse(AppConstants.getAllShiftsEndpoint),
      headers: {'Authorization': 'Bearer $token'},
    );

    AppLogger.info(
      'Shift API Response (${response.statusCode}): ${response.body}',
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => "${e['start_time']} - ${e['end_time']}").toList();
    } else {
      throw Exception('Failed to fetch shifts');
    }
  }

  Future<void> updateShift({
    required String token,
    required int shiftId,
    required List<int> presentEmployeeIds,
    required List<int> absentEmployeeIds,
  }) async {
    final url = Uri.parse('https://merchantrestaurant.alektasolutions.com/wp-json/pinaka-restaurant-pos/v1/shifts/update-shift');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'shift_id': shiftId,
        'shift_emp': presentEmployeeIds,
        'shift_absent_emp': absentEmployeeIds,
      }),
    );

    AppLogger.info('Update Shift Response (${response.statusCode}): ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Failed to update shift. Response: ${response.body}');
    }
  }


  Future<Map<String, dynamic>?> getCurrentShift(String token) async {
    final url = Uri.parse(
      'https://merchantrestaurant.alektasolutions.com/wp-json/pinaka-restaurant-pos/v1/shifts/current-shift',
    );

    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    AppLogger.info(
      'Current Shift Response (${response.statusCode}): ${response.body}',
    );

    if (response.statusCode == 200 && response.body.isNotEmpty) {
      final Map<String, dynamic> shift = jsonDecode(response.body);
      return shift;
    }

    return null;
  }
  Future<void> closeShift({
    required String token,
    required int shiftId,
  }) async {
    final url = Uri.parse(
      'https://merchantrestaurant.alektasolutions.com/wp-json/pinaka-restaurant-pos/v1/shifts/update-shift',
    );

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'shift_id': shiftId,
        'status': 'closed',
      }),
    );

    AppLogger.info('Close Shift Response (${response.statusCode}): ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Failed to close shift. Response: ${response.body}');
    }
  }

}
