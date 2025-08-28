import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../App flow/ui/employee_login_page.dart';
import '../App flow/widgets/shift_closed_popup.dart';
import '../repositories/employee_repository.dart';
import '../utils/logger.dart';
import 'global_navigator.dart';

class ShiftMonitor {
  final EmployeeRepository employeeRepository;
  final String token;

  Timer? _timer;

  ShiftMonitor({required this.employeeRepository, required this.token});
  void startMonitoring() async {
    try {
      final currentShift = await employeeRepository.getCurrentShift(token);
      AppLogger.info("Fetched current shift: $currentShift");

      if (currentShift == null || currentShift['shift_status'] == 'closed') {
        AppLogger.info("No active shift or shift already closed.");
        return;
      }

      final String? shiftEndTimeStr = currentShift['shift_timings']?['end_time'];
      final String? shiftDateStr = currentShift['shift_date'];

      if (shiftEndTimeStr == null || shiftDateStr == null ||
          shiftEndTimeStr.isEmpty || shiftDateStr.isEmpty) {
        AppLogger.error("Shift date or end time is null/empty.");
        return;
      }
      final parsedEndTime = DateFormat('hh:mma').parse(shiftEndTimeStr);
      final parsedShiftDate = DateFormat('yyyy-MM-dd').parse(shiftDateStr);

      final shiftEndDateTime = DateTime(
        parsedShiftDate.year,
        parsedShiftDate.month,
        parsedShiftDate.day,
        parsedEndTime.hour,
        parsedEndTime.minute,
      );

      final now = DateTime.now();

      if (now.isAfter(shiftEndDateTime)) {
        _checkAndCloseShift();
        return;
      }
      final duration = shiftEndDateTime.difference(now);
      AppLogger.info("Scheduling auto-close after $duration");

      _timer = Timer(duration, _checkAndCloseShift);

    } catch (e) {
      AppLogger.error("Exception in startMonitoring(): $e");
    }
  }

  void stopMonitoring() {
    _timer?.cancel();
  }

  Future<void> _checkAndCloseShift() async {
    try {
      final currentShift = await employeeRepository.getCurrentShift(token);
      AppLogger.info("Fetched current shift: $currentShift");

      if (currentShift == null || currentShift['shift_status'] == 'closed') {
        AppLogger.info("No active shift or shift already closed.");
        return;
      }

      final int shiftId = currentShift['shift_id'];
      final String shiftStatus = currentShift['shift_status'];
      final String? shiftEndTimeStr = currentShift['shift_timings']?['end_time'];
      final String? shiftDateStr = currentShift['shift_date'];

      AppLogger.info("Shift ID: $shiftId, Status: $shiftStatus, Date: $shiftDateStr, End Time: $shiftEndTimeStr");

      if (shiftEndTimeStr == null || shiftDateStr == null || shiftEndTimeStr.isEmpty || shiftDateStr.isEmpty) {
        AppLogger.error("Shift date or end time is null/empty.");
        return;
      }

      DateTime shiftEndDateTime;
      try {
        final parsedEndTime = DateFormat('hh:mma').parse(shiftEndTimeStr);
        final parsedShiftDate = DateFormat('yyyy-MM-dd').parse(shiftDateStr);

        shiftEndDateTime = DateTime(
          parsedShiftDate.year,
          parsedShiftDate.month,
          parsedShiftDate.day,
          parsedEndTime.hour,
          parsedEndTime.minute,
        );

        AppLogger.info("Parsed shift end datetime: $shiftEndDateTime");
      } catch (e) {
        AppLogger.error("Error parsing shift_date or end_time: $e");
        return;
      }

      final now = DateTime.now();
      AppLogger.info("Current time: $now");

      if (now.isAfter(shiftEndDateTime) && shiftStatus == 'open') {
        final String formattedEndTime = DateFormat("HH:mm").format(now);
        AppLogger.info("Auto-closing shift $shiftId at $formattedEndTime");

        await employeeRepository.closeShift(
          token: token,
          shiftId: shiftId,
          endTime: formattedEndTime,
        );

        AppLogger.info("Shift $shiftId successfully auto-closed.");

        stopMonitoring();

        final context = navigatorKey.currentContext;
        if (context != null) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => ShiftClosedPopup(
              message: "Shift auto-closed at ${DateFormat('hh:mm a').format(now)}",
            ),
          );

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const EmployeeLoginPage()),
                (route) => false,
          );
        } else {
          AppLogger.error("navigatorKey.currentContext is null, cannot show dialog.");
        }
      } else {
        AppLogger.info("Shift still open; not yet time to auto-close.");
      }
    } catch (e) {
      AppLogger.error("Exception in _checkAndCloseShift(): $e");
    }
  }
}