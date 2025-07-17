// lib/blocs/Bloc Logic/attendance_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../App flow/ui/DailyAttendanceScreen.dart';
import '../../repositories/employee_repository.dart';
import '../Bloc Event/attendance_event.dart';
import '../Bloc State/attendance_state.dart';

class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  final EmployeeRepository employeeRepo;

  AttendanceBloc(this.employeeRepo) : super(AttendanceInitial()) {
    on<InitializeAttendanceFlow>((event, emit) async {
      emit(AttendanceLoading());

      try {
        final employeeData = await employeeRepo.getAllEmployees(event.token);

        final employees = employeeData
            .map((e) => Employee(id: e['ID'].toString(), name: e['name'] ?? ''))
            .toList();

        emit(AttendancePopupReady(employees));
      } catch (e) {
        emit(AttendanceErrorState('Failed to load employees: $e'));
      }
    });

    on<FetchShifts>((event, emit) async {
      try {
        final shifts = await employeeRepo.getAllShifts(event.token);
        emit(ShiftListLoaded(shifts));
      } catch (e) {
        emit(AttendanceErrorState('Failed to load shifts: $e'));
      }
    });
  }
}
