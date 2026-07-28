import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pinaka_restaurant_pos/App%20flow/ui/employee_login_page.dart';

import '../../blocs/Bloc Event/attendance_event.dart';
import '../../blocs/Bloc Logic/attendance_bloc.dart';
import '../../blocs/Bloc State/attendance_state.dart';
import '../../local database/ShiftDao.dart';
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
  final Map<String, dynamic>? currentShiftData;

  const AttendancePopup({
    super.key,
    required this.employees,
    required this.token,
    this.onComplete,
    this.isUpdateMode = false,
    this.currentShiftData,
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
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
    context.read<AttendanceBloc>().add(FetchShifts(widget.token));

    if (widget.isUpdateMode) {
      _loadCurrentShiftAttendance();
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      currentTime = DateFormat('hh:mm:ss a').format(now);
      currentDate = DateFormat('EEE, d MMMM yyyy').format(now);
    });
  }

  void _updateStatus(Employee emp, String status) {
    setState(() {
      emp.status = emp.status == status ? '' : status;
    });
  }

  Future<void> _loadCurrentShiftAttendance() async {
    try {
      final currentShift = await EmployeeRepository().getCurrentShift(
        widget.token,
      );

      if (currentShift == null) return;

      final presentIds = List<int>.from(currentShift['shift_emp'] ?? []);
      final absentIds = List<int>.from(currentShift['shift_absent_emp'] ?? []);

      setState(() {
        for (var emp in widget.employees) {
          if (presentIds.contains(int.tryParse(emp.id))) {
            emp.status = 'Present';
          } else if (absentIds.contains(int.tryParse(emp.id))) {
            emp.status = 'Absent';
          } else {
            emp.status = '';
          }
        }
      });
    } catch (e) {
      AppLogger.error('Failed to load previous shift data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredEmployees =
        widget.employees.where((e) {
          return e.id.contains(searchQuery) ||
              e.name.toLowerCase().contains(searchQuery.toLowerCase());
        }).toList();

    final viewInsets = MediaQuery.of(context).viewInsets;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
                color: isDark ? theme.cardColor : const Color(0xFF0A1B4D),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 10),
                      _buildHeader(),
                      const SizedBox(height: 15),
                      _buildTableHeader(),
                      ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxHeight: 280,
                          minHeight: 280,
                        ),
                        child: Scrollbar(
                          child:
                              filteredEmployees.isEmpty
                                  ? Center(
                                    child: Text(
                                      "No results found.",
                                      style: TextStyle(
                                        color: theme.textTheme.bodyLarge?.color,
                                      ),
                                    ),
                                  )
                                  : ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: filteredEmployees.length,
                                    itemBuilder: (context, index) {
                                      final emp = filteredEmployees[index];
                                      return Container(
                                        decoration: BoxDecoration(
                                          color: theme.cardColor,
                                          border: Border(
                                            left: BorderSide(
                                              color: theme.dividerColor,
                                            ),
                                            right: BorderSide(
                                              color: theme.dividerColor,
                                            ),
                                            bottom: BorderSide(
                                              color: theme.dividerColor,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            _buildCell(emp.id, flex: 2),
                                            _buildCell(emp.name, flex: 4),
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
                                customMessage:
                                    'Please fill the shift timings field',
                                duration: const Duration(seconds: 3),
                              );
                              return;
                            }

                            if (!widget.employees.any(
                              (e) => e.status == 'Present',
                            )) {
                              AreaMovementNotifier.showPopup(
                                context: context,
                                fromArea: '',
                                toArea: '',
                                tableName: 'Employee',
                                customMessage:
                                    'Please mark at least one employee as Present.',
                                duration: const Duration(seconds: 3),
                              );
                              return;
                            }

                            setState(() => _isSaving = true);

                            final startTime =
                                selectedShift.split(' - ').first.trim();
                            final presentIds =
                                widget.employees
                                    .where((e) => e.status == 'Present')
                                    .map((e) => int.tryParse(e.id))
                                    .whereType<int>()
                                    .toList();

                            final absentIds =
                                widget.employees
                                    .where((e) => e.status == 'Absent')
                                    .map((e) => int.tryParse(e.id))
                                    .whereType<int>()
                                    .toList();

                            final now = DateTime.now();
                            final shiftDate = DateFormat(
                              'yyyy-MM-dd',
                            ).format(now);

                            AppLogger.info(
                              ' Selected Shift Start Time: $startTime',
                            );
                            AppLogger.info(
                              ' Present Employee IDs: $presentIds',
                            );
                            AppLogger.info(' Absent Employee IDs: $absentIds');

                            try {
                              if (widget.isUpdateMode) {
                                final currentShift = await EmployeeRepository()
                                    .getCurrentShift(widget.token);
                                final shiftId = currentShift?['shift_id'];

                                if (shiftId == null) {
                                  throw Exception(
                                    'Current shift not found or missing ID.',
                                  );
                                }

                                await EmployeeRepository().updateShift(
                                  token: widget.token,
                                  shiftId: shiftId,
                                  presentEmployeeIds: presentIds,
                                  absentEmployeeIds: absentIds,
                                );

                                AppLogger.info(
                                  '✅ Shift updated with ID $shiftId',
                                );

                                AreaMovementNotifier.showPopup(
                                  context: context,
                                  fromArea: '',
                                  toArea: '',
                                  tableName: 'Shift',
                                  customMessage: 'Shift updated successfully!',
                                  duration: const Duration(seconds: 3),
                                );
                              } else {
                                final shiftId = await EmployeeRepository()
                                    .createShift(
                                      token: widget.token,
                                      shiftDate: shiftDate,
                                      startTime: startTime,
                                      employeeIds: presentIds,
                                      absentEmployeeIds: absentIds,
                                    );

                                await ShiftDao().saveShift(shiftId, shiftDate);
                                AppLogger.info(
                                  '✅ Shift created for date $shiftDate at $startTime with ${presentIds.length} employees.',
                                );

                                AreaMovementNotifier.showPopup(
                                  context: context,
                                  fromArea: '',
                                  toArea: '',
                                  tableName: 'Shift',
                                  customMessage: 'Shift created successfully!',
                                  duration: const Duration(seconds: 3),
                                );
                              }

                              await Future.delayed(
                                const Duration(milliseconds: 500),
                              );
                              if (context.mounted) Navigator.of(context).pop();
                              widget.onComplete?.call(startTime);
                            } catch (e) {
                              AppLogger.error(
                                'Shift creation/update failed: $e',
                              );

                              String errorMessage;

                              if (e.toString().contains(
                                'Empty response body',
                              )) {
                                errorMessage =
                                    'An open shift already exists. Please close the current shift first.';
                              } else if (e.toString().contains('shift_id')) {
                                errorMessage =
                                    'Shift response missing shift ID. Please check with admin.';
                              } else {
                                errorMessage =
                                    'Shift operation failed. Please try again.';
                              }

                              AreaMovementNotifier.showPopup(
                                context: context,
                                fromArea: '',
                                toArea: '',
                                tableName: 'Shift',
                                customMessage: errorMessage,
                                duration: const Duration(seconds: 3),
                              );

                              // Navigate to login only for generic shift operation failure
                              if (errorMessage ==
                                  'Shift operation failed. Please try again.') {
                                await Future.delayed(
                                  const Duration(seconds: 3),
                                );

                                if (context.mounted) {
                                  final prefs =
                                      await SharedPreferences.getInstance();
                                  await prefs.clear();

                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => const EmployeeLoginPage(
                                            storeBaseUrl: '',
                                            storeName: '',
                                            storeId: '',
                                          ),
                                    ),
                                    (route) => false,
                                  );
                                }
                              }
                            }
                            setState(() => _isSaving = false);
                          },
                          child:
                              _isSaving
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                  : Text(
                                    widget.isUpdateMode
                                        ? "Update"
                                        : "Save & Continue",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                        ),
                      ),
                    ],
                  ),
                  if (!widget.isUpdateMode)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Material(
                        elevation: 3,
                        borderRadius: BorderRadius.circular(10),
                        shadowColor: Colors.black.withAlpha(100),
                        child: TextButton(
                          onPressed: () async {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.clear();

                            if (context.mounted) {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => const EmployeeLoginPage(
                                        storeBaseUrl: '',
                                        storeName: '',
                                        storeId: '',
                                      ),
                                ),
                                (route) => false,
                              );
                            }
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            backgroundColor:
                                isDark
                                    ? Colors.grey.shade800
                                    : const Color(0xFFFFF3EE),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.logout,
                                color:
                                    isDark
                                        ? Colors.orange.shade300
                                        : const Color(0xFFFF3D00),
                                size: 22,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Logout',
                                style: TextStyle(
                                  color:
                                      isDark
                                          ? Colors.orange.shade300
                                          : const Color(0xFFFF3D00),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (widget.isUpdateMode)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF86157),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0x3F000000),
                                blurRadius: 11,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            "Daily Attendance",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Search:",
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(width: 10),

            SizedBox(
              width: 240,
              height: 40,
              child: TextField(
                onChanged: (val) => setState(() => searchQuery = val),
                style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                decoration: InputDecoration(
                  hintText: "Employee ID or Name",
                  hintStyle: TextStyle(color: theme.hintColor),
                  prefixIcon: Icon(
                    Icons.search,
                    size: 20,
                    color: theme.iconTheme.color,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: theme.dividerColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: theme.colorScheme.primary),
                  ),
                  isDense: true,
                  filled: true,
                  fillColor: isDark ? Colors.grey.shade900 : Colors.white,
                ),
              ),
            ),

            const SizedBox(width: 30),

            Text(
              "Running Shift:",
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),

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
                      color: theme.cardColor,
                      border: Border.all(color: theme.dividerColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      selectedShift,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                  );
                } else if (state is AttendanceErrorState) {
                  return const Text(
                    "Error loading shifts",
                    style: TextStyle(color: Colors.red),
                  );
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
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                Text(
                  currentDate,
                  style: const TextStyle(fontSize: 14, color: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTableHeader() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF4D4F62) : const Color(0xFFD7D7D7),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
        border: Border.all(color: theme.dividerColor),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
        child: Row(
          children: [
            _buildHeaderCell('Employee ID', flex: 2, showRightBorder: true),
            _buildHeaderCell('Employee Name', flex: 4, showRightBorder: true),
            _buildHeaderCell('Status', flex: 5, showRightBorder: false),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCell(
    String text, {
    required int flex,
    bool showRightBorder = true,
  }) {
    final theme = Theme.of(context);

    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            right:
                showRightBorder
                    ? BorderSide(color: theme.dividerColor)
                    : BorderSide.none,
          ),
        ),
        child: Center(
          child: Text(
            text,
            style: theme.textTheme.titleSmall?.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCell(String text, {required int flex}) {
    final theme = Theme.of(context);

    String line1 = text;
    String? line2;

    final match = RegExp(r'(.+?)\s*\((.+?)\)').firstMatch(text);
    if (match != null) {
      line1 = match.group(1)!;
      line2 = match.group(2);
    }

    final bool isFirstColumn = flex == 2;

    return Expanded(
      flex: flex,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left:
                isFirstColumn
                    ? BorderSide.none
                    : BorderSide(color: theme.dividerColor),
            right:
                isFirstColumn
                    ? BorderSide.none
                    : BorderSide(color: theme.dividerColor),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              line1,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (line2 != null)
              Text(
                line2,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
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
          mainAxisAlignment: MainAxisAlignment.center,
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

  Widget _buildStatusButton(
    bool selected,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      width: 155,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color:
                selected
                    ? color
                    : (isDark ? Color(0xFF252837) : const Color(0xFFE0E0E0)),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: selected ? color : theme.dividerColor),
            boxShadow:
                selected
                    ? [
                      BoxShadow(
                        color: color.withOpacity(0.3),
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
              color: selected ? Colors.white : theme.textTheme.bodyLarge?.color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
