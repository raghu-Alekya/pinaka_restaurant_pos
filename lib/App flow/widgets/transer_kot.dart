import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/Bloc Event/transfer_kot_event.dart';
import '../../blocs/Bloc Logic/transfer_kot_bloc.dart';
import '../../blocs/Bloc State/transfer_kot_state.dart';
import '../../utils/TableStatusColors.dart';

class TransferKotItem {
  String name;
  String? note;
  int qty;
  double amount;
  bool selected;

  TransferKotItem({
    required this.name,
    this.note,
    required this.qty,
    required this.amount,
    this.selected = true,
  });
}

class TransferKOTDialog extends StatefulWidget {
  // UI
  final String tableName;
  final String kotNo;
  final DateTime dateTime;
  final List<TransferKotItem> items;

  /// zoneName -> tableNames
  final Map<String, List<String>> zoneTables;

  // 🔥 REQUIRED FOR API
  final int orderId;
  final int kotId;
  final int fromTableId;
  final int restaurantId;
  final String authToken;

  /// zoneName -> zoneId
  final Map<String, int> zoneIds;

  /// tableName -> tableId
  final Map<String, int> tableIds;
  final Map<String, String> tableStatus;
  final String kotZone;// tableName → status
  final Map<String, String> zoneNames;


  const TransferKOTDialog({
    super.key,
    required this.tableName,
    required this.kotNo,
    required this.dateTime,
    required this.items,
    required this.zoneTables,

    // API
    required this.orderId,
    required this.kotId,
    required this.fromTableId,
    required this.restaurantId,
    required this.authToken,
    required this.zoneIds,
    required this.tableIds,
    required this.tableStatus,
    required this.kotZone,
    required this.zoneNames,
  });

  @override
  State<TransferKOTDialog> createState() => _TransferKOTDialogState();
}

class _TransferKOTDialogState extends State<TransferKOTDialog> {
  late List<TransferKotItem> items;

  String? selectedZone;
  String? selectedTable;

  final ScrollController _tableScrollController = ScrollController();
  final ScrollController _itemsScrollController = ScrollController();

  // @override
  @override
  void initState() {
    super.initState();

    items = widget.items.toList();

    selectedZone = widget.kotZone;
    debugPrint("🧪 kotZone = ${widget.kotZone}");
    debugPrint("🧪 zoneNames = ${widget.zoneNames}");
    debugPrint("🧪 selectedZone = $selectedZone");
// 🔥 THIS WAS REQUIRED
  }



  @override
  void dispose() {
    _tableScrollController.dispose();
    _itemsScrollController.dispose();
    super.dispose();
  }

  String get onlyTime =>
      TimeOfDay.fromDateTime(widget.dateTime).format(context);

  List<String> get tables {
    final allTables = widget.zoneTables[selectedZone] ?? [];

    return allTables.where((tableName) {
      final tableId = widget.tableIds[tableName];
      return tableId != widget.fromTableId; // ❌ hide same table
    }).toList();
  }


  // ================= HEADER =================

  Widget _header() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: const BoxDecoration(color: Color(0xFFF0F3FC)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Transfer KOT",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2C3E50),
            ),
          ),
          InkWell(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: Color(0xFFFF4B4B),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close,
                  color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  // ================= LEFT TOP INFO =================

  Widget _leftTopInfoRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F6FF),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Text(
            "Table : #${widget.tableName}",
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          const SizedBox(width: 18),
          Text(
            "KOT : ${widget.kotNo}",
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          const Spacer(),
          Text(
            onlyTime,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  // ================= TABLE HEADER =================

  Widget _tableHeaderRow() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFDCDADA),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Row(
        children: [
          SizedBox(width: 30, child: Center(child: Text("#"))),
          Expanded(flex: 4, child: Text("Item Name")),
          Expanded(flex: 2, child: Center(child: Text("Quantity"))),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text("Amount"),
            ),
          ),
        ],
      ),
    );
  }

  // ================= LEFT ITEMS =================

  Widget _leftItemsTable() {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(top: 6),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE6E6E6)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Scrollbar(
          controller: _itemsScrollController,
          thumbVisibility: true,
          child: ListView.separated(
            controller: _itemsScrollController,
            itemCount: items.length,
            separatorBuilder: (_, __) =>
            const Divider(height: 1, color: Color(0xFFEDEDED)),
            itemBuilder: (context, index) {
              final item = items[index];
              return Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                          if ((item.note ?? "").isNotEmpty)
                            Text(
                              item.note!,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFFFF3B30),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Center(
                        child: Text("${item.qty}",
                            style:
                            const TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          item.amount.toStringAsFixed(2),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ================= ZONE DROPDOWN =================

  // Widget _zoneDropdown() {
  //   return Container(
  //     height: 36,
  //     padding: const EdgeInsets.symmetric(horizontal: 12),
  //     decoration: BoxDecoration(
  //       color: const Color(0xFFFFFF),
  //       borderRadius: BorderRadius.circular(6),
  //     ),
  //     child: DropdownButtonHideUnderline(
  //       child: DropdownButton<String>(
  //         value: selectedZone,
  //         dropdownColor: Colors.white,
  //         icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black),
  //         style: const TextStyle(
  //             color: Colors.white, fontWeight: FontWeight.w600),
  //         onChanged: (value) {
  //           setState(() {
  //             selectedZone = value;
  //             selectedTable = null;
  //           });
  //         },
  //         items: widget.zoneTables.keys.map((zone) {
  //           return DropdownMenuItem(
  //             value: zone,
  //             child: Text("Zone $zone",
  //                 style: const TextStyle(color: Colors.black)),
  //           );
  //         }).toList(),
  //       ),
  //     ),
  //   );
  // }

  // ================= TABLE GRID =================

  Widget _tableGrid() {
    return GridView.builder(
      controller: _tableScrollController,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 2.4,
      ),
      itemCount: tables.length,
      itemBuilder: (context, index) {
        final table = tables[index];
        final isSelected = selectedTable == table;

        // ✅ normalize status
        final rawStatus = widget.tableStatus[table] ?? "Available";
        final status = rawStatus.trim().toLowerCase();

        // 🎨 colors only (NO blocking)
        final tableColor = TableStatusColors.getTableColor(status);
        final textColor  = TableStatusColors.getChairColor(status);

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () {
              debugPrint("🟢 Table selected for transfer: $table");
              setState(() {
                selectedTable = table;
              });
            },
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF1E63FF) // 🔵 selected
                    : tableColor,             // 🎨 status color
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF1E63FF)
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    table,
                    style: TextStyle(
                      color: isSelected ? Colors.white : textColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    rawStatus, // show status text
                    style: TextStyle(
                      fontSize: 9,
                      color: isSelected
                          ? Colors.white70
                          : textColor.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }


  // ================= RIGHT PANEL =================

  Widget _rightPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🔹 Header + Zone info
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "Select Table",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            Text(
              "Zone : ${widget.zoneNames[selectedZone] ?? ''}",
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),


        const SizedBox(height: 12),

        // 🔹 Tables grid
        Expanded(
          child: Scrollbar(
            controller: _tableScrollController,
            thumbVisibility: true,
            child: _tableGrid(),
          ),
        ),

        const SizedBox(height: 14),

        // 🔹 Action button
        Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            width: 140,
            height: 40,
            child: ElevatedButton(
              onPressed: selectedTable == null
                  ? null
                  : () {
                final selectedItems =
                items.where((e) => e.selected).toList();

                if (selectedItems.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Select at least one item"),
                    ),
                  );
                  return;
                }

                context.read<TransferKotBloc>().add(
                  TransferKotEvent(
                    orderId: widget.orderId,
                    kotId: widget.kotId,
                    fromTableId: widget.fromTableId,
                    toTableId:
                    widget.tableIds[selectedTable!]!,
                    restaurantId: widget.restaurantId,
                    zoneId: widget.zoneIds[selectedZone!]!,
                    token: widget.authToken,
                  ),
                );
              },
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(
                  const Color(0xFFFE6464),
                ),
              ),
              child: const Text(
                "Yes, Continue",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }



  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    return BlocListener<TransferKotBloc, TransferKotState>(
        listener: (context, state) {
          if (state is KotTransferSuccess) {
            Navigator.pop(context, {
              "newParentId": state.newParentId,
              "toTableId": state.toTableId,
            });

            // ScaffoldMessenger.of(context).showSnackBar(
            //   SnackBar(content: Text(state.message)),
            // );
          }

          if (state is KotTransferFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error)),
            );
          }
        },
     child: Dialog(
      backgroundColor: Colors.white,
      insetPadding:
      const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.86,
        height: MediaQuery.of(context).size.height * 0.86,
        child: Column(
          children: [
            _header(),
            Expanded(
              child: Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "To transfer KOT, please select the items and choose the table.",
                            style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF4C5F7D)),
                          ),
                          const SizedBox(height: 10),
                          _leftTopInfoRow(),
                          const SizedBox(height: 10),
                          _tableHeaderRow(),
                          _leftItemsTable(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(flex: 4, child: _rightPanel()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ));

  }
}