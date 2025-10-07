import 'package:flutter/material.dart';
import '../../repositories/table_merge_repository.dart';
import 'area_movement_notifier.dart';

class MergeEditTablePopup extends StatefulWidget {
  final int index;
  final Map<String, dynamic> tableData;
  final Function(int, Map<String, dynamic>) onMergeEdit;
  final String token;

  const MergeEditTablePopup({
    super.key,
    required this.index,
    required this.tableData,
    required this.onMergeEdit,
    required this.token,
  });

  @override
  State<MergeEditTablePopup> createState() => _MergeEditTablePopupState();
}

class _MergeEditTablePopupState extends State<MergeEditTablePopup> {
  String? selectedParent;
  Set<String> selectedChildren = {};
  Set<String> originallyMergedTables = {};

  List<Map<String, dynamic>> parentTables = [];
  List<Map<String, dynamic>> childTables = [];

  bool isLoading = true;

  final TableMergeRepository _repository = TableMergeRepository();

  @override
  void initState() {
    super.initState();
    _loadMergeTables();
  }

  Future<void> _loadMergeTables() async {
    try {
      final result = await _repository.fetchMergeTables(widget.token);
      final int currentZoneId = widget.tableData['zone_id'];

      final filteredParents = (result['parent_tables'] as List<dynamic>? ?? [])
          .where((table) => table['zone_id'] == currentZoneId)
          .toList();
      final filteredChildren = (result['child_tables'] as List<dynamic>? ?? [])
          .where((table) => table['zone_id'] == currentZoneId)
          .toList();

      setState(() {
        parentTables = _sortTables(List<Map<String, dynamic>>.from(filteredParents));
        childTables = _sortTables(List<Map<String, dynamic>>.from(filteredChildren));
        isLoading = false;
      });

      _prefillMergedData();
    } catch (e) {
      debugPrint("Error fetching merge tables: $e");
      setState(() => isLoading = false);
    }
  }

  void _prefillMergedData() {
    if (widget.tableData['is_merged'] == true) {
      final mergedTablesString = widget.tableData['merged_tables'] ?? '';
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
                    child: const Icon(Icons.close, size: 18, color: Colors.white),
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

            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: _buildPanel(
                      title: "Choose Table to modify (Parent) Available:",
                      children: [
                        if (parentTables.where((t) => t['status'] == 'Available').isEmpty)
                          const Text(
                            "No tables available",
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          )
                        else
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: parentTables
                                .where((t) => t['status'] == 'Available')
                                .map((t) => _buildTableButton(
                              tableName: t['table_name'],
                              status: t['status'],
                              isParent: true,
                              isMerged: t['is_merged'] == true,
                              isUpdateMode: isUpdateMode,
                            ))
                                .toList(),
                          ),
                        const SizedBox(height: 18),
                        const Text(
                          "Choose Table to modify (Parent) Running:",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (parentTables.where((t) => t['status'] == 'Dine in').isEmpty)
                          const Text(
                            "No tables running",
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          )
                        else
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: parentTables
                                .where((t) => t['status'] == 'Dine in')
                                .map((t) => _buildTableButton(
                              tableName: t['table_name'],
                              status: t['status'],
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
                      title: "Choose Table to modify (Child) Available:",
                      children: [
                        if (childTables.where((t) => t['status'] == 'Available').isEmpty)
                          const Text(
                            "No tables available",
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          )
                        else
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: childTables
                                .where((t) => t['status'] == 'Available')
                                .map((t) => _buildTableButton(
                              tableName: t['table_name'],
                              status: t['status'],
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

            /// Merge Button
            SizedBox(
              width: 220,
              height: 40,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5A5A),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  if (selectedParent == null || selectedChildren.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                          Text("Please select parent and child tables.")),
                    );
                    return;
                  }
                  try {
                    final parentTable = parentTables
                        .firstWhere((t) => t['table_name'] == selectedParent);
                    final parentTableId = parentTable['table_id'] as int;
                    final childTableIds = childTables
                        .where((t) => selectedChildren.contains(t['table_name']))
                        .map<int>((t) => t['table_id'] as int)
                        .toList();

                    final result = widget.tableData['is_merged'] == true
                        ? await _repository.updateMergeTablesWithStatus(
                      token: widget.token,
                      restaurantId: widget.tableData['restaurant_id'],
                      zoneName: widget.tableData['areaName'],
                      parentTableId: parentTableId,
                      childTableIds: childTableIds,
                    )
                        : await _repository.createMergeTables(
                      token: widget.token,
                      restaurantId: widget.tableData['restaurant_id'],
                      zoneName: widget.tableData['areaName'],
                      parentTableId: parentTableId,
                      childTableIds: childTableIds,
                    );

                    if (result['success'] == true) {
                      Navigator.of(context).pop();
                      AreaMovementNotifier.showPopup(
                        context: context,
                        fromArea: widget.tableData['areaName'],
                        toArea: widget.tableData['areaName'],
                        tableName: parentTable['table_name'],
                        customMessage:
                        'Table "${parentTable['table_name']}" merged with ${childTableIds.length} table(s) successfully.',
                      );

                      widget.onMergeEdit(widget.index, widget.tableData);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                            Text(result['message'] ?? "Merge failed.")),
                      );
                    }
                  } catch (e) {
                    debugPrint("Error creating merge tables: $e");
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error: $e")),
                    );
                  }
                },
                child: Text(
                  widget.tableData['is_merged'] == true
                      ? "Update & Proceed"
                      : "Merge & Proceed",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
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
          color: const Color(0xFFF0F3FC), borderRadius: BorderRadius.circular(12)),
      child: ListView(
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black)),
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
    bool isMergedFinal = isMerged || originallyMergedTables.contains(tableName);
    bool isBlocked = false;
    if (isUpdateMode) {
      if (isMergedFinal && !originallyMergedTables.contains(tableName)) {
        isBlocked = true;
      }
    } else {
      if (isMergedFinal) {
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
        width: 160,
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
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}