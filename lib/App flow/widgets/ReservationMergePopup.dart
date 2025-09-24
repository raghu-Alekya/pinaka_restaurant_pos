import 'package:flutter/material.dart';
import '../../repositories/merge_reserve_repository.dart';

class ReservationMergePopup extends StatefulWidget {
  final int index;
  final Map<String, dynamic> tableData;
  final String token;
  final Function(int, Map<String, dynamic>) onMergeEdit;
  final int people;
  final String name;
  final String phone;
  final DateTime date;
  final String time;
  final String slotType;
  final String zoneName;
  final String restaurantName;
  final int restaurantId;
  final String priority;

  const ReservationMergePopup({
    super.key,
    required this.index,
    required this.tableData,
    required this.token,
    required this.onMergeEdit,
    required this.people,
    required this.name,
    required this.phone,
    required this.date,
    required this.time,
    required this.slotType,
    required this.zoneName,
    required this.restaurantName,
    required this.restaurantId,
    required this.priority,
  });

  @override
  State<ReservationMergePopup> createState() => _ReservationMergePopupState();
}

class _ReservationMergePopupState extends State<ReservationMergePopup> {
  String? selectedParent;
  Set<String> selectedChildren = {};
  Set<String> originallyMergedTables = {};

  List<Map<String, dynamic>> parentTables = [];
  List<Map<String, dynamic>> childTables = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMergeTables();
  }

  Future<void> _loadMergeTables() async {
    try {
      final repository = MergeReserveRepository(token: widget.token);
      final data = await repository.fetchMergeTables();
      final int currentZoneId = widget.tableData['zone_id'];

      final filteredParents = (data['parent_tables'] as List<dynamic>? ?? [])
          .where((table) => table['zone_id'] == currentZoneId)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      final filteredChildren = (data['child_tables'] as List<dynamic>? ?? [])
          .where((table) => table['zone_id'] == currentZoneId)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      setState(() {
        parentTables = _sortTables(filteredParents);
        childTables = _sortTables(filteredChildren);
        isLoading = false;
      });

      _prefillMergedData();
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load tables: $e')),
      );
    }
  }

  void _prefillMergedData() {
    if (widget.tableData['is_merged'] == true) {
      final mergedTablesString =
          widget.tableData['merged_tables'] ?? widget.tableData['tableName'] ?? '';
      final mergedList = mergedTablesString.split('-');

      if (mergedList.isNotEmpty) {
        setState(() {
          selectedParent = mergedList.first;
          selectedChildren = mergedList.skip(1).toSet();
          originallyMergedTables = mergedList.toSet();
          if (selectedParent != null &&
              !parentTables.any((t) => t['table_name'] == selectedParent)) {
            parentTables.add({
              'table_id': widget.tableData['table_id'],
              'table_name': selectedParent,
              'status': widget.tableData['status'] ?? 'Unknown',
              'zone_id': widget.tableData['zone_id'],
              'capacity': widget.tableData['capacity'],
              'shape': widget.tableData['shape'],
            });
          }

          for (final child in selectedChildren) {
            if (!childTables.any((t) => t['table_name'] == child)) {
              childTables.add({
                'table_id': widget.tableData['table_id'],
                'table_name': child,
                'status': widget.tableData['status'] ?? 'Unknown',
                'zone_id': widget.tableData['zone_id'],
                'capacity': widget.tableData['capacity'],
                'shape': widget.tableData['shape'],
              });
            }
          }

          parentTables = _sortTables(parentTables);
          childTables = _sortTables(childTables);
        });
      }
    }
  }

  List<Map<String, dynamic>> _sortTables(List<Map<String, dynamic>> tables) {
    tables.sort((a, b) {
      final nameA = a['table_name']?.toString() ?? '';
      final nameB = b['table_name']?.toString() ?? '';
      final numA = int.tryParse(RegExp(r'\d+').stringMatch(nameA) ?? '') ?? 0;
      final numB = int.tryParse(RegExp(r'\d+').stringMatch(nameB) ?? '') ?? 0;
      if (numA != numB) return numA.compareTo(numB);
      return nameA.compareTo(nameB);
    });
    return tables;
  }

  Future<void> _saveReservation() async {
    final mergedTablesString = widget.tableData['merged_tables'] ?? '';
    final reservationData = {
      'people': widget.people,
      'name': widget.name,
      'phone': widget.phone,
      'date': widget.date.toString(),
      'time': widget.time,
      'tableNo': mergedTablesString,
      'slotType': widget.slotType,
      'zoneName': widget.zoneName,
      'restaurantName': widget.restaurantName,
      'restaurantId': widget.restaurantId,
      'priority': widget.priority,
      'isUpdateMode': widget.tableData['is_merged'] == true,
      'reservationId': widget.tableData['reservation_id'] ?? 0,
    };
    print("Reservation Data: $reservationData");

  }

  @override
  Widget build(BuildContext context) {
    final bool isUpdateMode = widget.tableData['is_merged'] == true;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      contentPadding: const EdgeInsets.all(20),
      content: SizedBox(
        width: 800,
        height: 480,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          children: [
            /// Title + Close
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 28),
                const Expanded(
                  child: Text(
                    "Merge/Edit Table",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF5A5A),
                      shape: BoxShape.circle,
                    ),
                    child:
                    const Icon(Icons.close, size: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            /// Instruction
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(
                    text:
                    "Choose a parent table and one or more child tables to merge within the ",
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54),
                  ),
                  TextSpan(
                    text: "${widget.tableData['areaName']}",
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                  ),
                  const TextSpan(
                    text:
                    " area. The parent table will act as the primary table, and all selected child tables will be combined under it.",
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),

            /// Panels
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: _buildPanel(
                      title: "Choose Parent Table:",
                      children: [
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: parentTables
                              .map((t) => _buildTableButton(
                            tableName: t['table_name'],
                            status: t['status'] ?? "Available",
                            isParent: true,
                            isMerged: t['is_merged'] == true,
                            isUpdateMode: isUpdateMode,
                          ))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildPanel(
                      title: "Choose Child Tables:",
                      children: [
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: childTables
                              .map((t) => _buildTableButton(
                            tableName: t['table_name'],
                            status: t['status'] ?? "Available",
                            isParent: false,
                            isMerged: t['is_merged'] == true,
                            isUpdateMode: isUpdateMode,
                          ))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            /// Merge & Confirm Reservation Button
            SizedBox(
              width: 280,
              height: 40,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5A5A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  if (selectedParent == null || selectedChildren.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please select parent and child tables.")),
                    );
                    return;
                  }
                  widget.tableData['selectedParent'] = selectedParent;
                  widget.tableData['selectedChildren'] = selectedChildren.toList();
                  Navigator.of(context).pop();
                  widget.onMergeEdit(widget.index, widget.tableData);
                  await _saveReservation();
                },
                child: Text(
                  isUpdateMode ? "Update & confirm reservation" : "Merge & confirm reservation",
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPanel({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F3FC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView(
        children: [
          Text(
            title,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTableButton({
    required String tableName,
    required String status,
    required bool isParent,
    bool isMerged = false,
    bool isUpdateMode = false,
  }) {
    bool isSelectedParent = selectedParent == tableName;
    bool isSelectedChild = selectedChildren.contains(tableName);

    if (originallyMergedTables.contains(tableName)) {
      isMerged = true;
    }

    bool isBlocked = false;
    if (isUpdateMode) {
      if (isMerged && !originallyMergedTables.contains(tableName)) {
        isBlocked = true;
      }
    } else {
      if (isMerged) {
        isBlocked = true;
      }
    }

    if (!isBlocked) {
      if ((isParent && selectedChildren.contains(tableName)) ||
          (!isParent && selectedParent == tableName)) {
        isBlocked = true;
      }
    }

    Color baseColor =
    status == "Available" ? const Color(0xFFBDECC7) : const Color(0xFFF3C0C3);
    Color bgColor = baseColor;

    if (isParent) {
      if (isSelectedParent) {
        bgColor = const Color(0xFFEAC989);
      } else if (isBlocked) {
        bgColor = const Color(0xFFD9D9D9);
      }
    } else {
      if (isSelectedChild) {
        bgColor = const Color(0xFFFFF2B1);
      } else if (isBlocked) {
        bgColor = const Color(0xFFD9D9D9);
      }
    }

    return GestureDetector(
      onTap: () {
        if (isBlocked) return;

        setState(() {
          if (isParent) {
            selectedParent = (selectedParent == tableName) ? null : tableName;
          } else {
            if (selectedChildren.contains(tableName)) {
              selectedChildren.remove(tableName);
            } else {
              selectedChildren.add(tableName);
            }
          }
        });
      },
      child: Container(
        width: 150,
        height: 40,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          tableName,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}