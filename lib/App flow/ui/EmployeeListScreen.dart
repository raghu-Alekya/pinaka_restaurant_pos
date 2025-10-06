import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pinaka_restaurant_pos/App%20flow/ui/tables_screen.dart';
import '../../local database/table_dao.dart';
import '../../models/UserPermissions.dart';
import '../../repositories/dashboard_repository.dart';
import '../widgets/top_bar.dart';

class EmployeeListScreen extends StatefulWidget {
  final String pin;
  final String token;
  final String restaurantId;
  final String restaurantName;
  final UserPermissions? userPermissions;

  const EmployeeListScreen({
    Key? key,
    required this.pin,
    required this.token,
    required this.restaurantId,
    required this.restaurantName,
    required this.userPermissions,
  }) : super(key: key);

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  UserPermissions? _userPermissions;
  String searchQuery = "";
  int currentPage = 1;
  final int entriesPerPage = 8;
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> employees = [];
  bool isLoading = true;
  final TextEditingController _shiftController = TextEditingController();
  String shiftQuery = "";

  late DashboardRepository _repository;

  @override
  void initState() {
    super.initState();
    _userPermissions = widget.userPermissions;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkDashboardPermission();
      _repository = DashboardRepository(
        token: widget.token,
        restaurantId: widget.restaurantId,
      );
      _fetchEmployees();
    });
  }

  void _checkDashboardPermission() async {
    if (_userPermissions != null && !_userPermissions!.canAccessDashboard) {
      final tableDao = TableDao();
      final tables = await tableDao.getTablesByManagerPin(widget.pin);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                TablesScreen(
                  loadedTables: tables,
                  pin: widget.pin,
                  token: widget.token,
                  restaurantId: widget.restaurantId,
                  restaurantName: widget.restaurantName,
                ),
          ),
        );
      }
    }
  }

  Future<void> _fetchEmployees() async {
    try {
      setState(() => isLoading = true);

      final today = DateFormat("yyyy-MM-dd").format(DateTime.now());
      final data = await _repository.fetchEmployeeList(date: today);

      setState(() {
        employees = data;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching employees: $e");
      setState(() => isLoading = false);
    }
  }

  List<Widget> _buildPaginationButtons(int totalPages) {
    List<Widget> buttons = [];
    for (int i = 1; i <= totalPages; i++) {
      buttons.add(
        SizedBox(
          width: 40,
          height: 36,
          child: OutlinedButton(
            onPressed: () => setState(() => currentPage = i),
            style: OutlinedButton.styleFrom(
              backgroundColor:
              currentPage == i ? Colors.red.shade400 : Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6)),
              padding: EdgeInsets.zero,
            ),
            child: Text(
              i.toString(),
              style: TextStyle(
                color: currentPage == i ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
      buttons.add(const SizedBox(width: 5));
    }
    return buttons;
  }

  @override
  Widget build(BuildContext context) {
    final filteredEmployees = employees.where((emp) {
      final query = searchQuery.toLowerCase();
      final shiftQ = shiftQuery.toLowerCase();
      final name = emp["name"].toString().toLowerCase();
      final id = emp["user_id"].toString().toLowerCase();
      final shift = (emp["shift_timing"] ?? "").toLowerCase();

      final matchesNameOrId = name.contains(query) || id.contains(query);
      final matchesShift = shift.contains(shiftQ);

      return matchesNameOrId && matchesShift;
    }).toList();

    final totalPages = (filteredEmployees.length / entriesPerPage).ceil();
    final startIndex = (currentPage - 1) * entriesPerPage;
    final currentData =
    filteredEmployees.skip(startIndex).take(entriesPerPage).toList();

    const double headerHeight = 50;

    return Scaffold(
      appBar: TopBar(
        token: widget.token,
        pin: widget.pin,
        userPermissions: _userPermissions,
        onPermissionsReceived: (permissions) {
          setState(() {
            _userPermissions = permissions;
          });
        },
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white,
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.arrow_back, size: 18),
                        SizedBox(width: 5),
                        Text(
                          'Back',
                          style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    "Employee List",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87),
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => searchQuery = value),
                    decoration: InputDecoration(
                      hintText: "Search ID or Name",
                      prefixIcon: const Icon(Icons.search, size: 18),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade600, width: 1.5),
                      ),
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 150,
                  child: TextField(
                    controller: _shiftController,
                    onChanged: (value) => setState(() => shiftQuery = value),
                    decoration: InputDecoration(
                      hintText: "Search Shift",
                      prefixIcon: const Icon(Icons.schedule, size: 18),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade600, width: 1.5),
                      ),
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                child: Column(
                  children: [
                    // Table Headers
                    Container(
                      height: headerHeight,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 12),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE7F5FD),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(10),
                          topRight: Radius.circular(10),
                        ),
                      ),
                      child: Row(
                        children: const [
                          _TableHeaderCell("Employee ID"),
                          SizedBox(width: 10),
                          _TableHeaderCell("Employee Name"),
                          SizedBox(width: 10),
                          _TableHeaderCell("Phone"),
                          SizedBox(width: 10),
                          _TableHeaderCell("Designation"),
                          SizedBox(width: 10),
                          _TableHeaderCell("Shift"),
                          SizedBox(width: 10),
                          _TableHeaderCell("Status"),
                        ],
                      ),
                    ),

                    // Employee rows
                    Expanded(
                      child: currentData.isEmpty
                          ? const Center(
                          child: Text("No employees found"))
                          : ListView.builder(
                        itemCount: currentData.length,
                        itemBuilder: (context, index) {
                          final emp = currentData[index];
                          final status =
                              emp["attendance_status"] ?? "-";
                          final shift =
                              emp["shift_timing"] ?? "-";

                          Color bgColor;
                          Color textColor;

                          if (status.toLowerCase() == "present") {
                            bgColor = const Color(0xFFDFF6E2);
                            textColor = Colors.green;
                          } else if (status.toLowerCase() ==
                              "absent") {
                            bgColor = const Color(0xFFFDE2E2);
                            textColor = Colors.red;
                          } else {
                            bgColor = Colors.grey.shade200;
                            textColor = Colors.black54;
                          }

                          return Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAFDFF),
                              border: Border(
                                bottom: BorderSide(
                                    color: Colors.grey.shade200),
                              ),
                            ),
                            child: Row(
                              children: [
                                _TableCell(
                                    emp["user_id"].toString()),
                                _TableCell(emp["name"].toString()),
                                _TableCell(emp["phone"] ?? "-"),
                                _TableCell(emp["designation"].toString()),
                                _TableCell(shift),
                                _TableCell(
                                  status,
                                  bgColor: bgColor,
                                  textColor: textColor,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Pagination
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SizedBox(
                          width: 80,
                          height: 40,
                          child: OutlinedButton(
                            onPressed: currentPage > 1
                                ? () =>
                                setState(() => currentPage--)
                                : null,
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(6)),
                              padding: EdgeInsets.zero,
                            ),
                            child: const Text("Previous",
                                style: TextStyle(color: Colors.black)),
                          ),
                        ),
                        const SizedBox(width: 5),
                        ..._buildPaginationButtons(totalPages),
                        const SizedBox(width: 5),
                        SizedBox(
                          width: 80,
                          height: 40,
                          child: OutlinedButton(
                            onPressed: currentPage < totalPages
                                ? () =>
                                setState(() => currentPage++)
                                : null,
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(6)),
                              padding: EdgeInsets.zero,
                            ),
                            child: const Text("Next",
                                style: TextStyle(color: Colors.black)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Table Header Cell Widget
class _TableHeaderCell extends StatelessWidget {
  final String title;
  const _TableHeaderCell(this.title, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}

// Table Cell Widget
class _TableCell extends StatelessWidget {
  final String text;
  final Color? bgColor;
  final Color? textColor;

  const _TableCell(this.text, {this.bgColor, this.textColor, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (bgColor != null && textColor != null) {
      return Expanded(
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 5),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              text,
              style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
            ),
          ),
        ),
      );
    }
    return Expanded(child: Text(text, textAlign: TextAlign.center));
  }
}
