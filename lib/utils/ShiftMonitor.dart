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

  void startMonitoring() {
    _checkAndCloseShift();
    _timer = Timer.periodic(Duration(minutes: 1), (_) => _checkAndCloseShift());
  }

  void stopMonitoring() {
    _timer?.cancel();
  }

  Future<void> _checkAndCloseShift() async {
    try {
      final currentShift = await employeeRepository.getCurrentShift(token);
      if (currentShift == null || currentShift['shift_status'] == 'closed') return;

      final int shiftId = currentShift['shift_id'];
      final now = DateTime.now();
      final shiftTimings = currentShift['shift_timings'];
      final String? shiftEndTimeStr = shiftTimings?['end_time'];

      if (shiftEndTimeStr == null || shiftEndTimeStr.isEmpty) return;

      final DateFormat format = DateFormat("h:mma");
      final DateTime parsedEndTime = format.parse(shiftEndTimeStr.toUpperCase());

      DateTime manualEndTime = DateTime(
        now.year,
        now.month,
        now.day,
        parsedEndTime.hour,
        parsedEndTime.minute,
      );

      final String startTimeStr = shiftTimings?['start_time'] ?? "12:00AM";
      final DateTime parsedStartTime = format.parse(startTimeStr.toUpperCase());

      DateTime manualStartTime = DateTime(
        now.year,
        now.month,
        now.day,
        parsedStartTime.hour,
        parsedStartTime.minute,
      );

      if (manualEndTime.isBefore(manualStartTime)) {
        manualEndTime = manualEndTime.add(Duration(days: 1));
      }

      AppLogger.info("Current time: $now");
      AppLogger.info("Shift end time: $manualEndTime");

      if (now.isAfter(manualEndTime)) {
        final String formattedEndTime = DateFormat("HH:mm").format(now);
        await employeeRepository.closeShift(
          token: token,
          shiftId: shiftId,
          endTime: formattedEndTime,
        );

        AppLogger.info("Auto-closed shift $shiftId at $now");
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
          AppLogger.error("navigatorKey.currentContext is null, cannot show dialogs.");
        }
      }
    } catch (e) {
      AppLogger.error("Error in auto-close shift logic: $e");
    }
  }
}