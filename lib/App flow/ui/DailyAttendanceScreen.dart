import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pinaka_restaurant_pos/App%20flow/ui/employee_login_page.dart';

import '../../blocs/Bloc Event/attendance_event.dart';
import '../../blocs/Bloc Logic/attendance_bloc.dart';
import '../../blocs/Bloc State/attendance_state.dart';
import '../../repositories/employee_repository.dart';
import '../../utils/logger.dart';
import '../widgets/area_movement_notifier.dart';

class Employee {
  final String id;
  final String name;
  String status;

  Employee({required this.id, required this.name, this.status = ''});
}

class AttendancePopup extends StatefulWidget {
  final List<Employee> employees;
  final void Function(String startTime)? onComplete;
  final bool isUpdateMode;
  final String token;

  const AttendancePopup({
    super.key,
    required this.employees,
    required this.token,
    this.onComplete,
    this.isUpdateMode = false,
  });

  @override
  State<AttendancePopup> createState() => _AttendancePopupState();
}

class _AttendancePopupState extends State<AttendancePopup> {
  String searchQuery = '';
  String selectedShift = '';
  late Timer _timer;
  String currentTime = '';
  String currentDate = '';

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
    context.read<AttendanceBloc>().add(FetchShifts(widget.token));
  }
  bool _isSaving = false;


  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      currentTime = DateFormat('hh:mm:ss a').format(now);
      currentDate = DateFormat('EEE, d MMMM yyyy').format(now);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _updateStatus(Employee emp, String status) {
    setState(() {
      emp.status = emp.status == status ? '' : status;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredEmployees = widget.employees.where((e) {
      return e.id.contains(searchQuery) ||
          e.name.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();

    final viewInsets = MediaQuery.of(context).viewInsets;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 300),
          padding: EdgeInsets.only(bottom: viewInsets.bottom),
          child: SingleChildScrollView(
            child: Container(
              width: 850,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFFE2FFF7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 10),
                      _buildHeader(),
                      const SizedBox(height: 20),
                      _buildTableHeader(),
                      ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxHeight: 270,
                          minHeight: 270,
                        ),
                        child: Scrollbar(
                          child: filteredEmployees.isEmpty
                              ? const Center(child: Text("No results found."))
                              : ListView.builder(
                            shrinkWrap: true,
                            itemCount: filteredEmployees.length,
                            itemBuilder: (context, index) {
                              final emp = filteredEmployees[index];
                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border(
                                    left: BorderSide(color: Colors.grey.shade500),
                                    right: BorderSide(color: Colors.grey.shade500),
                                    bottom: BorderSide(color: Colors.grey.shade500),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    _buildCell(emp.id, flex: 2),
                                    _buildCell(emp.name, flex: 3),
                                    _buildStatusCell(emp),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: 220,
                        height: 40,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          onPressed: () async {
                            if (_isSaving) return;

                            if (selectedShift.isEmpty) {
                              AreaMovementNotifier.showPopup(
                                context: context,
                                fromArea: '',
                                toArea: '',
                                tableName: 'Shift',
                                customMessage: 'Please fill the shift timings field',
                                duration: const Duration(seconds: 3),
                              );
                              return;
                            }

                            if (!widget.employees.any((e) => e.status == 'Present')) {
                              AreaMovementNotifier.showPopup(
                                context: context,
                                fromArea: '',
                                toArea: '',
                                tableName: 'Employee',
                                customMessage: 'Please mark at least one employee as Present.',
                                duration: const Duration(seconds: 3),
                              );
                              return;
                            }

                            setState(() => _isSaving = true);

                            final startTime = selectedShift.split(' - ').first.trim();
                            final presentIds = widget.employees
                                .where((e) => e.status == 'Present')
                                .map((e) => int.tryParse(e.id))
                                .whereType<int>()
                                .toList();

                            final now = DateTime.now();
                            final shiftDate = DateFormat('yyyy-MM-dd').format(now);

                            try {
                              await EmployeeRepository().createShift(
                                token: widget.token,
                                shiftDate: shiftDate,
                                startTime: startTime,
                                employeeIds: presentIds,
                              );
                              AppLogger.info('✅ Shift created for date $shiftDate at $startTime with ${presentIds.length} employees.');
                              Navigator.of(context).pop();

                              widget.onComplete?.call(startTime);
                            } catch (e) {
                              AppLogger.error('Shift creation failed: $e');
                              AreaMovementNotifier.showPopup(
                                context: context,
                                fromArea: '',
                                toArea: '',
                                tableName: 'Shift',
                                customMessage: 'Duplicate shift start time for today.',
                                duration: const Duration(seconds: 3),
                              );
                            }

                            setState(() => _isSaving = false);
                          },
                          child: _isSaving
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                              : Text(
                            widget.isUpdateMode ? "Update" : "Save & Continue",
                            style: const TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!widget.isUpdateMode)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: TextButton.icon(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                              const EmployeeLoginPage(),
                            ),
                          );
                        },
                        icon:
                        const Icon(Icons.logout, color: Colors.red),
                        label: const Text("Logout",
                            style: TextStyle(color: Colors.red)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: Text(
            "Daily Attendance",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text("Search:", style: TextStyle(fontSize: 16)),
            const SizedBox(width: 10),
            SizedBox(
              width: 240,
              height: 40,
              child: TextField(
                onChanged: (val) => setState(() => searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Employee ID or Name',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 30),
            const Text("Running Shift:", style: TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            BlocBuilder<AttendanceBloc, AttendanceState>(
              builder: (context, state) {
                if (state is ShiftListLoaded) {
                  if (selectedShift.isEmpty && state.shifts.isNotEmpty) {
                    selectedShift = state.shifts.first;
                  }

                  return Container(
                    width: 180,
                    height: 40,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      selectedShift,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                  );
                } else if (state is AttendanceErrorState) {
                  return const Text("Error loading shifts", style: TextStyle(color: Colors.red));
                } else {
                  return const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                }
              },
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currentTime,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  currentDate,
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTableHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        border: Border(
          top: BorderSide(color: Colors.grey.shade500),
          left: BorderSide(color: Colors.grey.shade500),
          right: BorderSide(color: Colors.grey.shade500),
          bottom: BorderSide(color: Colors.grey.shade500),
        ),
      ),
      child: Row(
        children: [
          _buildHeaderCell('Employee ID', flex: 2),
          _buildHeaderCell('Employee Name', flex: 3),
          _buildHeaderCell('Status', flex: 5),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCell(String text, {required int flex}) {
    String line1 = text;
    String? line2;

    final match = RegExp(r'(.+?)\s*\((.+?)\)').firstMatch(text);
    if (match != null) {
      line1 = match.group(1)!;
      line2 = match.group(2);
    }

    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              line1,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (line2 != null)
              Text(
                line2,
                style: TextStyle(
                  fontSize: 14,
                    color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCell(Employee emp) {
    return Expanded(
      flex: 5,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        child: Row(
          children: [
            _buildStatusButton(
              emp.status == 'Present',
              '✓ PRESENT',
              Colors.green,
                  () => _updateStatus(emp, 'Present'),
            ),
            const SizedBox(width: 10),
            _buildStatusButton(
              emp.status == 'Absent',
              '✕ ABSENT',
              Colors.red,
                  () => _updateStatus(emp, 'Absent'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusButton(bool selected, String label, Color color,
      VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? color : Colors.grey[200],
            borderRadius: BorderRadius.circular(6),
            boxShadow: selected
                ? [
              BoxShadow(
                color: color.withAlpha((0.3 * 255).toInt()),
                offset: const Offset(0, 2),
                blurRadius: 4,
              ),
            ]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : Colors.black,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
