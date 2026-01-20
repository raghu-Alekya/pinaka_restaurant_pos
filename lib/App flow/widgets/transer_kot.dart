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
  final List<String> tables;

  const TransferKOTDialog({
    super.key,
    required this.tableNo,
    required this.kotNo,
    required this.dateTime,
    required this.items,
    required this.tables,
  });

  @override
  State<TransferKOTDialog> createState() => _TransferKOTDialogState();
}

class _TransferKOTDialogState extends State<TransferKOTDialog> {
  late List<TransferKotItem> items;
  String? selectedTable;

  final ScrollController _tableScrollController = ScrollController();
  final ScrollController _itemsScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    items = widget.items.map((e) => e).toList();
  }

  @override
  void dispose() {
    _tableScrollController.dispose();
    _itemsScrollController.dispose();
    super.dispose();
  }

  String get onlyTime => TimeOfDay.fromDateTime(widget.dateTime).format(context);

  // ✅ qty button (same light red bg)
  Widget _qtyBtn({required IconData icon, required VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: const Color(0xFFFFE6E6),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 16, color: Colors.black87),
      ),
    );
  }

  // ✅ Header same
  Widget _header() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFFF0F3FC),
      ),
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
            borderRadius: BorderRadius.circular(30),
            child: Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: Color(0xFFFF4B4B),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Left panel top info row (Table + KOT + TIME only)
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
            onlyTime, // ✅ only time with AM/PM
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Table header (same as your void popup)
  Widget _tableHeaderRow() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFDCDADA),
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: const Row(
        children: [
          SizedBox(
            width: 30,
            child: Center(
              child: Text("#", style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text("Item Name", style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Text("Quantity", style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text("Amount", style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ LEFT ITEMS TABLE
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
          interactive: true,
          child: ListView.separated(
            controller: _itemsScrollController,
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFEDEDED)),
            itemBuilder: (context, index) {
              final item = items[index];

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Row(
                  children: [
                    // checkbox
                    // SizedBox(
                    //   width: 34,
                    //   child: Checkbox(
                    //     value: item.selected,
                    //     activeColor: const Color(0xFF1E63FF),
                    //     side: const BorderSide(color: Color(0xFF1E63FF), width: 1.2),
                    //     onChanged: (v) {
                    //       setState(() => item.selected = v ?? false);
                    //     },
                    //   ),
                    // ),

                    // item name
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if ((item.note ?? "").isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                item.note!,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFFFF3B30),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // qty buttons
                    Expanded(
                      flex: 2,
                      child: Center(
                        child: Text(
                          "${item.qty}", // or item.quantity
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),


                    // amount
                    Expanded(
                      flex: 2,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          item.amount.toStringAsFixed(2),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2C3E50),
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

  // ✅ RIGHT TABLE SELECTOR (green buttons)
  Widget _rightTableSelector() {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFEDEDED)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Select Table",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Scrollbar(
                controller: _tableScrollController,
                thumbVisibility: true,
                interactive: true,
                child: GridView.builder(
                  controller: _tableScrollController,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 2.2,
                  ),
                  itemCount: widget.tables.length,
                  itemBuilder: (context, index) {
                    final t = widget.tables[index];
                    final isSelected = selectedTable == t;

                    return InkWell(
                      onTap: () => setState(() => selectedTable = t),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFF44B14F),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF1E63FF) : const Color(0xFF44B14F),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Text(
                          t,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.86,
        height: MediaQuery.of(context).size.height * 0.86,
        decoration: BoxDecoration(
          // border: Border.all(color: const Color(0xFF1E63FF), width: 2),
        ),
        child: Column(
          children: [
            _header(),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // LEFT SIDE
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "To transfer KOT, please select the items and choose the table.",
                            style: TextStyle(fontSize: 12, color: Color(0xFF4C5F7D)),
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

                    // RIGHT SIDE
                    Expanded(
                      flex: 4,
                      child: Column(
                        children: [
                          _rightTableSelector(),
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerRight,
                            child: SizedBox(
                              width: 150,
                              height: 42,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context, {
                                    "selectedTable": selectedTable,
                                    "selectedItems": items.where((e) => e.selected).toList(),
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF6B6B),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  "Yes, Continue",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
