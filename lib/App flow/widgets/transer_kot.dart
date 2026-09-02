import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../blocs/Bloc Event/transfer_kot_event.dart';
import '../../blocs/Bloc Logic/transfer_kot_bloc.dart';
import '../../blocs/Bloc State/transfer_kot_state.dart';
import '../../services/kds_seivices.dart';
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
  String? _selectedTable;
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

  // List<String> get tables {
  //   final allTables = widget.zoneTables[selectedZone] ?? [];
  //
  //   return allTables.where((tableName) {
  //     final tableId = widget.tableIds[tableName];
  //     return tableId != widget.fromTableId; // ❌ hide same table
  //   }).toList();
  // }


  //  hiding available tables
  List<String> get tables {
    final allTables = widget.zoneTables[selectedZone] ?? [];

    return allTables.where((tableName) {
      final tableId = widget.tableIds[tableName];
      final rawStatus = widget.tableStatus[tableName] ?? "";

      return tableId != widget.fromTableId &&
          rawStatus.trim().toLowerCase() == "dine in";
    }).toList();
  }





  // ================= HEADER =================

  Widget _header() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF2A2F3D)
            : const Color(0xFFF0F3FC),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Transfer KOT",
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: theme.textTheme.bodyLarge?.color,
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
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= LEFT TOP INFO =================

  Widget _leftTopInfoRow() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      child: Row(
        children: [
          Text(
            "Table : #${widget.tableName}",
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 18),
          Text(
            "KOT : ${widget.kotNo}",
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          Text(
            onlyTime,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  // ================= TABLE HEADER =================

  Widget _tableHeaderRow() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF3A3F4B)
            : const Color(0xFFDCDADA),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.08),
            blurRadius: 6,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Center(
              child: Text(
                "#",
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              "Item Name",
              style: TextStyle(
                color: theme.textTheme.bodyLarge?.color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                "Quantity",
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                "Amount",
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  // ================= LEFT ITEMS =================

  Widget _leftItemsTable() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF202433)
              : Colors.white,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
          border: Border.all(
            color: theme.dividerColor,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.20 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Scrollbar(
          controller: _itemsScrollController,
          thumbVisibility: true,
          child: ListView.separated(
            controller: _itemsScrollController,
            itemCount: items.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: theme.dividerColor,
            ),
            itemBuilder: (context, index) {
              final item = items[index];

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 30,
                      child: Center(
                        child: Text(
                          "${index + 1}",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                      ),
                    ),

                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
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
                        child: Text(
                          "${item.qty}",
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                      ),
                    ),

                    Expanded(
                      flex: 2,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          item.amount.toStringAsFixed(2),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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

        final rawStatus = widget.tableStatus[table] ?? "Available";
        final status = rawStatus.trim().toLowerCase();

        final tableColor = TableStatusColors.getTableColor(status);
        final textColor = TableStatusColors.getChairColor(status);

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
                    ? theme.colorScheme.primary
                    : tableColor,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.dividerColor,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    table,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : textColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    rawStatus,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🔹 Header + Zone info
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Select Table",
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              "Zone : ${widget.zoneNames[selectedZone] ?? ''}",
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // 🔹 Tables grid
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF202433)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.dividerColor,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(
                    isDark ? 0.20 : 0.06,
                  ),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Scrollbar(
              controller: _tableScrollController,
              thumbVisibility: true,
              child: _tableGrid(),
            ),
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
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 1),
                    ),
                  );
                  return;
                }

                context.read<TransferKotBloc>().add(
                  TransferKotEvent(
                    orderId: widget.orderId,
                    kotId: widget.kotId,
                    fromTableId: widget.fromTableId,
                    toTableId: widget.tableIds[selectedTable!]!,
                    restaurantId: widget.restaurantId,
                    zoneId: widget.zoneIds[selectedZone!]!,
                    token: widget.authToken,
                  ),
                );
              },
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.resolveWith<Color>(
                      (states) {
                    if (states.contains(MaterialState.disabled)) {
                      return const Color(0xFFBDBDBD);
                    }
                    return const Color(0xFFFE6464);
                  },
                ),
                foregroundColor:
                MaterialStateProperty.all(Colors.white),
                shape: MaterialStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              child: const Text(
                "Yes, Continue",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }



  // ================= BUILD =================

  @override
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocListener<TransferKotBloc, TransferKotState>(
      listener: (context, state) async {
        if (state is KotTransferSuccess) {

          debugPrint('==========================================');
          debugPrint('✅ KOT TRANSFER SUCCESS');
          debugPrint('KOT ID          : ${widget.kotId}');
          debugPrint('KOT NUMBER      : ${widget.kotNo}');
          debugPrint('OLD TABLE ID    : ${widget.fromTableId}');
          debugPrint('OLD TABLE NAME  : ${widget.tableName}');
          debugPrint('NEW TABLE NAME  : $selectedTable');
          debugPrint('NEW TABLE ID    : ${state.toTableId}');
          debugPrint('OLD PARENT ID   : ${widget.orderId}');
          debugPrint('NEW PARENT ID   : ${state.newParentId}');
          debugPrint('RESTAURANT ID   : ${widget.restaurantId}');
          debugPrint('ZONE ID         : ${widget.zoneIds[selectedZone!]}');
          debugPrint('ZONE NAME       : ${widget.zoneNames[selectedZone!]}');
          debugPrint('==========================================');

          // Get POS Store ID
          final prefs = await SharedPreferences.getInstance();

          final storeId =
              prefs.getString('store_id')?.trim() ?? '';

          if (storeId.isEmpty) {
            debugPrint(
              '❌ STORE ID EMPTY - TABLE TRANSFER MQTT NOT SENT',
            );
          } else if (selectedTable == null ||
              selectedTable!.trim().isEmpty) {
            debugPrint(
              '❌ NEW TABLE EMPTY - TABLE TRANSFER MQTT NOT SENT',
            );
          } else {
            await KdsMqttPublisher.notifyKotTableUpdated(
              restaurantId:
              widget.restaurantId.toString(),

              storeId: storeId,

              kotId:
              widget.kotId,

              kotNumber:
              widget.kotNo,

              parentOrderId:
              widget.orderId,

              newParentOrderId:
              state.newParentId,

              oldTableId:
              widget.fromTableId,

              oldTableName:
              widget.tableName,

              tableId:
              state.toTableId,

              tableName:
              selectedTable!,

              zoneId:
              widget.zoneIds[selectedZone!],

              zoneName:
              widget.zoneNames[selectedZone!] ?? '',
            );

            debugPrint(
              '✅ TABLE TRANSFER MQTT SENT',
            );
          }

          Navigator.pop(context, {
            "newParentId": state.newParentId,
            "toTableId": state.toTableId,
          });
        }

        if (state is KotTransferFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 1),
            ),
          );
        }
      },
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(
          horizontal: 26,
          vertical: 16,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF2A2F3D)
                  : theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.dividerColor,
              ),
            ),
            width: MediaQuery.of(context).size.width * 0.86,
            height: MediaQuery.of(context).size.height * 0.86,
            child: Column(
              children: [
                _header(),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _leftTopInfoRow(),
                              const SizedBox(height: 10),
                              _tableHeaderRow(),
                              _leftItemsTable(),
                              const SizedBox(height: 50),
                            ],
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          flex: 4,
                          child: _rightPanel(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}