abstract class AttendanceEvent {}

class InitializeAttendanceFlow extends AttendanceEvent {
  final String token;
  final String pin;

  InitializeAttendanceFlow({required this.token, required this.pin});
}

class FetchShifts extends AttendanceEvent {
  final String token;

  FetchShifts(this.token);
}
