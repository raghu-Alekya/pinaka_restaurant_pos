import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:pinaka_restaurant_pos/App%20flow/ui/employee_login_page.dart';

class Employee {
  final String id;
  final String name;
  String status;

  Employee({required this.id, required this.name, this.status = ''});
}

class AttendancePopup extends StatefulWidget {
  final List<Employee> employees;
  final VoidCallback? onComplete;
  final bool isUpdateMode;

  const AttendancePopup({
    super.key,
    required this.employees,
    this.onComplete,
    this.isUpdateMode = false,
  });

  @override
  State<AttendancePopup> createState() => _AttendancePopupState();
}

class _AttendancePopupState extends State<AttendancePopup> {
  String searchQuery = '';
  String selectedShift = '6.00 AM to 2.00 PM';
  late Timer _timer;
  String currentTime = '';
  String currentDate = '';

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

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
              width: 800,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
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
                          maxHeight: 180,
                          minHeight: 180,
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
                                  border: Border(
                                    bottom: BorderSide(
                                        color: Colors.grey.shade200),
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
                          onPressed: () {
                            print(widget.employees
                                .map((e) => '${e.name}: ${e.status}'));
                            widget.onComplete?.call();
                          },
                          child: Text(
                            widget.isUpdateMode
                                ? "Update"
                                : "Save & Continue",
                            style: const TextStyle(
                                fontSize: 16, color: Colors.white),
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
                              builder: (context) => const EmployeeLoginPage(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.logout, color: Colors.red),
                        label: const Text(
                          "Logout",
                          style: TextStyle(color: Colors.red),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: Text(
            "Daily Attendance",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text("Search:", style: TextStyle(fontSize: 16)),
            const SizedBox(width: 4),
            SizedBox(
              width: 240,
              height: 40,
              child: TextField(
                onChanged: (val) => setState(() => searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Employee ID or Name',
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 8, right: 4),
                    child: Icon(Icons.search, size: 20),
                  ),
                  prefixIconConstraints:
                  const BoxConstraints(minWidth: 32, minHeight: 32),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  isDense: true,
                ),
              ),
            ),

          const SizedBox(width: 20),
          const Text("Shift timings:", style: TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedShift,
                icon: const Icon(Icons.arrow_drop_down),
                dropdownColor: Colors.white,
                items: [
                  '6.00 AM to 2.00 PM',
                  '2.00 PM to 10.00 PM',
                  '10.00 PM to 6.00 AM',
                  '12.00 AM to 8.00 AM',
                  '8.00 AM to 4.00 PM',
                  '4.00 PM to 12.00 AM',
                  'Weekend Shift',
                  'Night Shift - Extended',
                ].map((String value) {
                  return DropdownMenuItem(
                    value: value,
                    child: Text(
                      value,
                      style: const TextStyle(fontSize: 14),
                    ),
                  );
                }).toList(),
                onChanged: (newVal) {
                  setState(() => selectedShift = newVal!);
                },
              ),
            ),
          ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currentTime,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
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
        border: Border.symmetric(
          vertical: BorderSide(color: Colors.grey.shade200),
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
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildCell(String text, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Center(
          child: Text(text, style: const TextStyle(fontSize: 16)),
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

  Widget _buildStatusButton(
      bool selected, String label, Color color, VoidCallback onTap) {
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
