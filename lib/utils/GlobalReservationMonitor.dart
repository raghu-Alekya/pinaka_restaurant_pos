import 'dart:async';
import 'package:flutter/material.dart';
import '../repositories/ReservationRepository.dart';
import '../utils/logger.dart';

class GlobalReservationMonitor {
  static final GlobalReservationMonitor _instance = GlobalReservationMonitor._internal();
  factory GlobalReservationMonitor() => _instance;
  GlobalReservationMonitor._internal();

  final ReservationRepository _reservationRepository = ReservationRepository();
  final ValueNotifier<List<Map<String, dynamic>>> reservationsNotifier = ValueNotifier([]);

  Timer? _timer;
  String? _token;

  void start(String token) {
    if (_timer != null && _timer!.isActive) {
      AppLogger.info("GlobalReservationMonitor already running — skipping restart.");
      return;
    }

    _token = token;
    AppLogger.info("Starting GlobalReservationMonitor with token.");
    _fetchReservations();

    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      AppLogger.info("GlobalReservationMonitor: Triggering periodic fetch...");
      _fetchReservations();
    });
  }

  void stop() {
    AppLogger.info("Stopping GlobalReservationMonitor.");
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _fetchReservations() async {
    if (_token == null) {
      AppLogger.error("GlobalReservationMonitor: Token is null, cannot fetch reservations.");
      return;
    }

    try {
      final reservations = await _reservationRepository.fetchAllReservations(_token!);
      AppLogger.info("Fetched ${reservations.length} reservations at ${DateTime.now()}");
      reservationsNotifier.value = reservations;
    } catch (e) {
      AppLogger.error("Error fetching reservations: $e");
    }
  }
}
