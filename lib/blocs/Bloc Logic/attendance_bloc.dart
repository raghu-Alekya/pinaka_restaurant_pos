// lib/blocs/Bloc Logic/attendance_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../App flow/ui/DailyAttendanceScreen.dart';
import '../../repositories/employee_repository.dart';
import '../Bloc Event/attendance_event.dart';
import '../Bloc State/attendance_state.dart';

class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  final EmployeeRepository employeeRepo;

  AttendanceBloc(this.employeeRepo) : super(AttendanceInitial()) {
    on<InitializeAttendanceFlow>((event, emit) async {
      emit(AttendanceLoading());

      final prefs = await SharedPreferences.getInstance();
      final hasShownPopups = prefs.getBool('popupsShown_${event.pin}') ?? false;

      if (hasShownPopups) return;

      try {
        final shiftCreated = prefs.getBool('shiftCreated_${event.pin}') ?? false;

        if (shiftCreated) {
          emit(ShiftAlreadyCreated());
          return;
        }

        final employeeData = await employeeRepo.getAllEmployees(event.token);

        final employees = employeeData
            .map((e) => Employee(id: '#${e['ID']}', name: e['name'] ?? ''))
            .toList();

        emit(AttendancePopupReady(employees));
      } catch (e) {
        emit(AttendanceErrorState('Failed to load employees: $e'));
      }
    });
  }
}
