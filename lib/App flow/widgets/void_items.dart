import 'package:flutter/material.dart';

// ─── Item Model ────────────────────────────────
class Item {
  String name;
  double pricePerItem;
  int quantity;
  double amount;
  String? notes;
  bool selected;
  List<String> modifiers;

  Item({
    required this.name,
    required this.pricePerItem,
    this.quantity = 1,
    this.selected = false,
    this.notes,
    this.modifiers = const [],
  }) : amount = pricePerItem * quantity;
}

// ─── VoidItemsDialog ───────────────────────────
class VoidItemsDialog extends StatefulWidget {
  final List<Item> items;
  final String tableNo;
  final String kotNo;

  final void Function(String value) onRemark;
  final dynamic item;

  const VoidItemsDialog({
    Key? key,
    required this.items,
    required this.tableNo,
    required this.kotNo,
    required this.onRemark,
    required this.item,
  }) : super(key: key);

  @override
  State<VoidItemsDialog> createState() => _VoidItemsDialogState();
}

class _VoidItemsDialogState extends State<VoidItemsDialog> {
  // LEFT PANEL -> Original KOT items (never changes)
  late final List<Item> originalKotItems;

  // RIGHT PANEL -> Editable items
  late final ValueNotifier<List<Item>> itemsNotifier;

  final TextEditingController remarkController = TextEditingController();

  final ScrollController _rightScrollController = ScrollController();
  final ScrollController _leftScrollController = ScrollController();

  String? selectedReason;

  final List<String> voidReasons = [
    "Wrong Item",
    "Customer Cancelled",
    "Kitchen Delay",
    "Order Mistake",
    "Other",
  ];

  @override
  void initState() {
    super.initState();

    // LEFT PANEL (fixed copy)
    originalKotItems = widget.items
        .map((e) => Item(
      name: e.name,
      pricePerItem: e.pricePerItem,
      quantity: e.quantity,
      notes: e.notes,
      modifiers: e.modifiers, //
    ))
        .toList();

    // RIGHT PANEL (editable copy)
    itemsNotifier = ValueNotifier<List<Item>>(
      widget.items
          .map((e) => Item(
        name: e.name,
        pricePerItem: e.pricePerItem,
        quantity: e.quantity,
        notes: e.notes,
        modifiers: e.modifiers,
      ))
          .toList(),
    );
  }

  @override
  void dispose() {
    itemsNotifier.dispose();
    remarkController.dispose();
    _rightScrollController.dispose();
    _leftScrollController.dispose();
    super.dispose();
  }

  double get subtotal =>
      itemsNotifier.value.fold(0.0, (sum, item) => sum + item.amount);

  int get totalItems =>
      itemsNotifier.value.fold(0, (sum, item) => sum + item.quantity);

  // ─── Header ────────────────────────────────
  Widget _dialogHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFFF0F3FC),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Void Items",
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

  Widget _tableHeaderRow({bool isLeft = false}) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFDCDADA),
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          SizedBox(
            width: isLeft ? 36 : 28,
            child: const Center(
              child: Text(
                "#",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const Expanded(
            flex: 4,
            child: Text(
              "Item Name",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const Expanded(
            flex: 2,
            child: Center(
              child: Text(
                "Quantity",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                "Amount",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _qtyButton({
    required IconData icon,
    required VoidCallback? onTap,
  }) {
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
  int get leftTotalItems {
    return originalKotItems.fold(0, (sum, item) => sum + item.quantity);
  }

  double get leftTotalAmount {
    return originalKotItems.fold(0.0, (sum, item) => sum + item.amount);
  }


  // ─── LEFT PANEL (Original KOT - No changes) ────────────────────────────────
  Widget _leftPanel() {
    return Expanded(
      flex: 1,
      child: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "To void an item, please select the item and provide a reason for voiding.",
              style: TextStyle(fontSize: 12, color: Color(0xFF4C5F7D)),
            ),
            const SizedBox(height: 12),
            _tableHeaderRow(isLeft: true),
            const SizedBox(height: 6),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE6E6E6)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Scrollbar(
                  controller: _leftScrollController,
                  thumbVisibility: true,
                  interactive: true,
                  child: ListView.separated(
                    controller: _leftScrollController,
                    itemCount: originalKotItems.length,
                    separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      color: Color(0xFFEDEDED),
                    ),
                    itemBuilder: (context, index) {
                      final item = originalKotItems[index];

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 10),
                        child: Row(
                          children: [
                            const SizedBox(width: 36),

                            // Item Name + Notes
                            Expanded(
                              flex: 4,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (item.modifiers.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        "Modifiers: ${item.modifiers.join(", ")}",
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.blueGrey,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),

                                  if ((item.notes ?? "").isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        item.notes!,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFFFF3B30),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            // Qty (Read Only)
                            Expanded(
                              flex: 2,
                              child: Center(
                                child: Text(
                                  "${item.quantity}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),

                            // Amount (Read Only)
                            Expanded(
                              flex: 2,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  item.amount.toStringAsFixed(2),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
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
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Text(
                  "Total Items : $leftTotalItems",
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const Spacer(),
                Text(
                  "Total Amount : ${leftTotalAmount.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),


            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F6FF),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Text(
                    "Enter Reason :",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedReason,
                          hint: const Text(
                            "Select Reason",
                            style: TextStyle(fontSize: 12),
                          ),
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down),
                          items: voidReasons.map((reason) {
                            return DropdownMenuItem(
                              value: reason,
                              child: Text(
                                reason,
                                style: const TextStyle(fontSize: 12),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedReason = value;
                            });
                            widget.onRemark(value ?? "");
                          },
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
    );
  }

  // ─── RIGHT PANEL (Editable) ────────────────────────────────
  Widget _rightPanel() {
    return Expanded(
      flex: 1,
      child: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  "Table : #${widget.tableNo}",
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(width: 18),
                Text(
                  "KOT : ${widget.kotNo}",
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const Spacer(),
                Text(
                  "Date :  ${DateTime.now().toLocal().toString().split(' ')[0]}   ${TimeOfDay.now().format(context)}",
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _tableHeaderRow(isLeft: false),
            const SizedBox(height: 6),
            Expanded(
              child: ValueListenableBuilder<List<Item>>(
                valueListenable: itemsNotifier,
                builder: (context, items, _) {
                  final rightItems = items; // show all items including qty 0

                  return Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE6E6E6)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Scrollbar(
                      controller: _rightScrollController,
                      thumbVisibility: true,
                      interactive: true,
                      child: ListView.separated(
                        controller: _rightScrollController,
                        itemCount: rightItems.length,
                        separatorBuilder: (_, __) => const Divider(
                          height: 1,
                          color: Color(0xFFEDEDED),
                        ),
                        itemBuilder: (context, index) {
                          final item = rightItems[index];

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 28,
                                  child: Text("${index + 1}"),
                                ),
                                Expanded(
                                  flex: 4,
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      if (item.modifiers.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 2),
                                          child: Text(
                                            "Modifiers: ${item.modifiers.join(", ")}",
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Colors.blueGrey,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),

                                      if ((item.notes ?? "").isNotEmpty)
                                        Padding(
                                          padding:
                                          const EdgeInsets.only(top: 2),
                                          child: Text(
                                            item.notes!,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Color(0xFFFF3B30),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.center,
                                    children: [
                                      _qtyButton(
                                        icon: Icons.remove,
                                        onTap: () {
                                          if (item.quantity > 0) {
                                            item.quantity--;
                                            item.amount = item.pricePerItem *
                                                item.quantity;
                                            itemsNotifier.value = List.from(
                                                itemsNotifier.value);
                                            setState(() {});
                                          }
                                        },
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "${item.quantity}",
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(width: 8),
                                      _qtyButton(
                                        icon: Icons.add,
                                        onTap: () {
                                          item.quantity++;
                                          item.amount = item.pricePerItem *
                                              item.quantity;
                                          itemsNotifier.value =
                                              List.from(itemsNotifier.value);
                                          setState(() {});
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      item.amount.toStringAsFixed(2),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
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
                  );
                },
              ),
            ),
            const SizedBox(height: 10),

            // Total Row
            Row(
              children: [
                Text(
                  "Total Items : $totalItems",
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                Text(
                  "Sub Total : ${subtotal.toStringAsFixed(2)}",
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),

            const SizedBox(height: 18),

            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 150,
                height: 40,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, {
                      'items': itemsNotifier.value
                          .where((e) => e.quantity > 0)
                          .toList(),
                      'remark': selectedReason ?? "",
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B6B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    elevation: 0,
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
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 26, vertical: 10),
      backgroundColor: Colors.white,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.82,
        height: MediaQuery.of(context).size.height * 0.82,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF1E63FF), width: 2),
        ),
        child: Column(
          children: [
            _dialogHeader(context),
            Expanded(
              child: Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _leftPanel(),
                    const SizedBox(width: 16),
                    _rightPanel(),
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
