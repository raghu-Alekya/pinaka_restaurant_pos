// lib/blocs/Bloc Event/attendance_event.dart
abstract class AttendanceEvent {}

class InitializeAttendanceFlow extends AttendanceEvent {
  final String token;
  final String pin;

  InitializeAttendanceFlow({required this.token, required this.pin});
}
