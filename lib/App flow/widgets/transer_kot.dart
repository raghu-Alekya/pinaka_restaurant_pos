import 'package:flutter/material.dart';

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
  final String tableNo;
  final String kotNo;
  final DateTime dateTime;
  final List<TransferKotItem> items;

  /// zoneId -> tableNames
  final Map<String, List<String>> zoneTables;

  const TransferKOTDialog({
    super.key,
    required this.tableNo,
    required this.kotNo,
    required this.dateTime,
    required this.items,
    required this.zoneTables, required List<String> tables,
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

  @override
  void initState() {
    super.initState();
    items = widget.items.map((e) => e).toList();

    if (widget.zoneTables.isNotEmpty) {
      selectedZone = widget.zoneTables.keys.first;
    }
  }

  @override
  void dispose() {
    _tableScrollController.dispose();
    _itemsScrollController.dispose();
    super.dispose();
  }

  String get onlyTime =>
      TimeOfDay.fromDateTime(widget.dateTime).format(context);

  List<String> get tables =>
      widget.zoneTables[selectedZone] ?? [];

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
            "Table : #${widget.tableNo}",
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

  Widget _zoneDropdown() {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E63FF),
        borderRadius: BorderRadius.circular(6),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedZone,
          dropdownColor: Colors.white,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600),
          onChanged: (value) {
            setState(() {
              selectedZone = value;
              selectedTable = null;
            });
          },
          items: widget.zoneTables.keys.map((zone) {
            return DropdownMenuItem(
              value: zone,
              child: Text("Zone $zone",
                  style: const TextStyle(color: Colors.black)),
            );
          }).toList(),
        ),
      ),
    );
  }

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

        return InkWell(
          onTap: () => setState(() => selectedTable = table),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF1E63FF)
                    : const Color(0xFF4CAF50),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Text(
              table,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12),
            ),
          ),
        );
      },
    );
  }

  // ================= RIGHT PANEL =================

  Widget _rightPanel() {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Select Table",
                  style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              _zoneDropdown(),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Scrollbar(
              controller: _tableScrollController,
              thumbVisibility: true,
              child: _tableGrid(),
            ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 140,
              height: 40,
              child: ElevatedButton(
                onPressed: selectedTable == null
                    ? null
                    : () {
                  Navigator.pop(context, {
                    "zone": selectedZone,
                    "table": selectedTable,
                    "items":
                    items.where((e) => e.selected).toList(),
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B6B),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6)),
                  elevation: 0,
                ),
                child: const Text("Yes, Continue",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    return Dialog(
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
    );
  }
}
