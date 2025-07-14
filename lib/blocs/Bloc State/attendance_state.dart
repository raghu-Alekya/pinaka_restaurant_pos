// lib/blocs/Bloc State/attendance_state.dart
import '../../App flow/ui/DailyAttendanceScreen.dart';

abstract class AttendanceState {}

class AttendanceInitial extends AttendanceState {}

class AttendanceLoading extends AttendanceState {}

class AttendancePopupReady extends AttendanceState {
  final List<Employee> employees;
  AttendancePopupReady(this.employees);
}

class ShiftCreatedState extends AttendanceState {}

class CheckInRequiredState extends AttendanceState {}

class CheckInCompletedState extends AttendanceState {}

class ShiftAlreadyCreated extends AttendanceState {}

class AttendanceErrorState extends AttendanceState {
  final String message;
  AttendanceErrorState(this.message);
}
