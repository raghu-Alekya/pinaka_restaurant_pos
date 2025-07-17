import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/constants.dart';
import '../utils/logger.dart';

class EmployeeRepository {

  Future<List<Map<String, dynamic>>> getAllEmployees(String token) async {
    final response = await http.get(
      Uri.parse(AppConstants.getAllEmployeesEndpoint),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    AppLogger.info('All Employees Response (${response.statusCode}): ${response.body}');

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      AppLogger.error('Failed to load employees: ${response.body}');
      throw Exception('Failed to load employees: ${response.body}');
    }
  }

  Future<void> createShift({
    required String token,
    required String shiftDate,
    required String startTime,
    required List<int> employeeIds,
  }) async {
    final payload = {
      'status': 'open',
      'shift_date': shiftDate,
      'start_time': startTime,
      'shift_emp': employeeIds,
    };

    AppLogger.debug('Shift Create Payload: ${jsonEncode(payload)}');

    final response = await http.post(
      Uri.parse(AppConstants.createShiftEndpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      AppLogger.info(' Shift successfully created.');
      AppLogger.info(' Shift Create Response: ${response.body}');
    } else {
      AppLogger.error('Shift creation failed (${response.statusCode}): ${response.body}');
      throw Exception('Shift creation failed: ${response.body}');
    }
  }

  Future<List<String>> getAllShifts(String token) async {
    final response = await http.get(
      Uri.parse(AppConstants.getAllShiftsEndpoint),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    AppLogger.info('Shift API Response (${response.statusCode}): ${response.body}');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => "${e['start_time']} - ${e['end_time']}").toList();
    } else {
      throw Exception('Failed to fetch shifts');
    }
  }
}
