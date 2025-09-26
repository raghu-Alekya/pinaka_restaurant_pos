import 'package:flutter/material.dart';

// ─── Item Model ────────────────────────────────
class Item {
  String name;
  double pricePerItem;
  int quantity;
  double amount;
  String? notes;
  bool selected;

  Item({
    required this.name,
    required this.pricePerItem,
    this.quantity = 1,
    this.selected = false,
    this.notes, required double amount,
  }) : amount = pricePerItem * quantity;
}

// ─── VoidItemsDialog ───────────────────────────
class VoidItemsDialog extends StatefulWidget {
  final List<Item> items;
  final String tableNo;
  final String kotNo;

  const VoidItemsDialog({
    Key? key,
    required this.items,
    required this.tableNo,
    required this.kotNo, required Null Function(String value) onRemark, required item,
  }) : super(key: key);

  @override
  State<VoidItemsDialog> createState() => _VoidItemsDialogState();
}

class _VoidItemsDialogState extends State<VoidItemsDialog> {
  final ValueNotifier<List<Item>> itemsNotifier = ValueNotifier([]);
  final ValueNotifier<String?> remarkNotifier = ValueNotifier(null);

  @override
  void initState() {
    super.initState();
    itemsNotifier.value = widget.items.map((e) => e).toList();
  }

  @override
  void dispose() {
    itemsNotifier.dispose();
    remarkNotifier.dispose();
    super.dispose();
  }

  double get subtotal =>
      itemsNotifier.value.fold(0, (sum, item) => sum + item.amount);

  int get totalItems =>
      itemsNotifier.value.fold(0, (sum, item) => sum + item.quantity);

  // ─── Header ─────────
  Widget _dialogHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: const Color(0XFFF0F3FC),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Void Items",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(30),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(6),
              child: const Icon(Icons.close, color: Colors.white, size: 20),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(

      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 4), // reduced width
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.6, // smaller width
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            _dialogHeader(context),
            const SizedBox(height: 2),
            // ─── Panels Row ─────────
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Left Panel ─────────
                  // ─── Left Panel ─────────
                  Expanded(
                    flex: 1,
                    child: Container(
                      color: Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            child: Text(
                              "To void an item, please select the item and provide a reason for voiding.",
                              style: TextStyle(fontSize: 12, color: Color(0XFF4C5F7D)),
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Table Headers
                          Container(
                            color: const Color(0xFFDCDADA),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: Row(
                              children: const [
                                SizedBox(width: 30, child: Text("#")),
                                Expanded(flex: 3, child: Text("Item Name", style: TextStyle(fontWeight: FontWeight.bold))),
                                Expanded(flex: 2, child: Center(child: Text("Quantity", style: TextStyle(fontWeight: FontWeight.bold)))),
                                Expanded(flex: 2, child: Text("Amount", style: TextStyle(fontWeight: FontWeight.bold))),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          // Items List
                          Expanded(
                            child: ValueListenableBuilder<List<Item>>(
                              valueListenable: itemsNotifier,
                              builder: (context, items, _) {
                                return ListView.separated(
                                  itemCount: items.length,
                                  separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.grey),
                                  itemBuilder: (context, index) {
                                    final item = items[index];
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      child: Row(
                                        children: [
                                          Checkbox(
                                            value: item.selected,
                                            onChanged: (val) {
                                              setState(() {
                                                item.selected = val!;
                                              });
                                              itemsNotifier.value = List.from(itemsNotifier.value);
                                            },
                                          ),
                                          Expanded(flex: 4, child: Text(item.name)),
                                          Expanded(
                                            flex: 2,
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                IconButton(
                                                    icon: const Icon(Icons.remove, size: 18),
                                                    onPressed: item.quantity > 1
                                                        ? () {
                                                      setState(() {
                                                        item.quantity--;
                                                        item.amount = item.pricePerItem * item.quantity;
                                                      });
                                                      itemsNotifier.value = List.from(itemsNotifier.value);
                                                    }
                                                        : null),
                                                Text("${item.quantity}"),
                                                IconButton(
                                                    icon: const Icon(Icons.add, size: 18),
                                                    onPressed: () {
                                                      setState(() {
                                                        item.quantity++;
                                                        item.amount = item.pricePerItem * item.quantity;
                                                      });
                                                      itemsNotifier.value = List.from(itemsNotifier.value);
                                                    }),
                                              ],
                                            ),
                                          ),
                                          Expanded(flex: 2, child: Text("${item.amount.toStringAsFixed(2)}")),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),

                          // ─── VOID REMARKS INSIDE LEFT PANEL ─────────
                          ValueListenableBuilder<List<Item>>(
                            valueListenable: itemsNotifier,
                            builder: (context, items, _) {
                              final hasSelected = items.any((item) => item.selected);
                              if (!hasSelected) return const SizedBox.shrink();

                              return Container(
                                margin: const EdgeInsets.all(12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, 2)),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("Void Remarks", style: TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 6),
                                    TextField(
                                      controller: TextEditingController(text: remarkNotifier.value),
                                      decoration: InputDecoration(
                                        hintText: "Void reason here",
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                      ),
                                      onChanged: (val) => remarkNotifier.value = val,
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 4,
                                      children: ["Poor Quality","Guest Rejected","Changed Item","Bad Taste","Wrong Order"]
                                          .map((reason) => ChoiceChip(
                                        label: Text(reason, style: const TextStyle(color: Colors.white)),
                                        selected: remarkNotifier.value == reason,
                                        selectedColor: const Color(0xFF4C81F1),
                                        backgroundColor: const Color(0xFF4C81F1).withOpacity(0.8),
                                        onSelected: (_) {
                                          remarkNotifier.value = reason;
                                          setState(() {});
                                        },
                                      ))
                                          .toList(),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        OutlinedButton(
                                          onPressed: () => remarkNotifier.value = null,
                                          style: OutlinedButton.styleFrom(
                                            backgroundColor: const Color(0xFFF6F6F6),
                                            foregroundColor: Colors.black,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                          ),
                                          child: const Text("Clear"),
                                        ),
                                        const SizedBox(width: 12),
                                        ElevatedButton(
                                          onPressed: () {
                                            itemsNotifier.value =
                                                itemsNotifier.value.where((item) => !item.selected).toList();
                                            remarkNotifier.value = null;
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFFFE6464),
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                          ),
                                          child: const Text("Save"),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),
                  // ─── Right Panel ─────────
                  Expanded(
                    flex: 1,
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                  "Table: #${widget.tableNo}    KOT: ${widget.kotNo}"),
                              Text(
                                "Date: ${DateTime.now().toLocal().toString().split(' ')[0]}  ${TimeOfDay.now().format(context)}",
                                style: const TextStyle(fontSize: 12),
                              )
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(
                            color: const Color(0xFFDCDADA),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            child: Row(
                              children: const [
                                SizedBox(width: 30, child: Text("#")),
                                Expanded(
                                    flex: 4,
                                    child: Text("Item Name",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold))),
                                Expanded(
                                    flex: 2,
                                    child: Center(
                                        child: Text("Quantity",
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)))),
                                Expanded(
                                    flex: 2,
                                    child: Text("Amount",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold))),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          Expanded(
                            child: ValueListenableBuilder<List<Item>>(
                              valueListenable: itemsNotifier,
                              builder: (context, items, _) {
                                return ListView.separated(
                                  itemCount: items.length,
                                  separatorBuilder: (_, __) => const Divider(
                                      height: 1, color: Colors.grey),
                                  itemBuilder: (context, index) {
                                    final item = items[index];
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 4),
                                      child: Row(
                                        children: [
                                          SizedBox(
                                              width: 30,
                                              child: Text("${index + 1}")),
                                          Expanded(flex: 4, child: Text(item.name)),
                                          Expanded(
                                              flex: 2,
                                              child: Center(
                                                  child: Text("${item.quantity}"))),
                                          Expanded(
                                              flex: 2,
                                              child: Text(
                                                  "${item.amount.toStringAsFixed(2)}")),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Total Items: $totalItems"),
                              Text("Sub Total: ${subtotal.toStringAsFixed(2)}")
                            ],
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: SizedBox(
                              width: 150, // desired width
                              height: 40, // desired height
                              child: ElevatedButton(
                                onPressed: () {
                                  final selectedItems = itemsNotifier.value
                                      .where((item) => item.selected)
                                      .toList();
                                  Navigator.pop(context, {
                                    'items': selectedItems,
                                    'remark': remarkNotifier.value,
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4), // circular radius
                                  ),
                                ),
                                child: const Text("Yes, Continue"),
                              ),
                            ),
                          )

                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // ─── Separate Void Remarks Container Below Left Panel ─────────
            // ValueListenableBuilder<List<Item>>(
            //   valueListenable: itemsNotifier,
            //   builder: (context, items, _) {
            //     final hasSelected = items.any((item) => item.selected);
            //     if (!hasSelected) return const SizedBox.shrink();
            //
            //     return Container(
            //       margin: const EdgeInsets.all(12),
            //       padding: const EdgeInsets.all(12),
            //       decoration: BoxDecoration(
            //         color: Colors.white,
            //         borderRadius: BorderRadius.circular(6),
            //         boxShadow: [
            //           BoxShadow(
            //             color: Colors.black12,
            //             blurRadius: 4,
            //             offset: const Offset(0, 2),
            //           )
            //         ],
            //       ),
            //       child: Column(
            //         crossAxisAlignment: CrossAxisAlignment.start,
            //         children: [
            //           const Text(
            //             "Void Remarks",
            //             style: TextStyle(fontWeight: FontWeight.bold),
            //           ),
            //           const SizedBox(height: 6),
            //           TextField(
            //             controller: TextEditingController(text: remarkNotifier.value),
            //             decoration: InputDecoration(
            //               hintText: "Void reason here",
            //               border: OutlineInputBorder(
            //                 borderRadius: BorderRadius.circular(4),
            //               ),
            //               contentPadding:
            //               const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            //             ),
            //             onChanged: (val) => remarkNotifier.value = val,
            //           ),
            //           const SizedBox(height: 8),
            //           Wrap(
            //             spacing: 6,
            //             children: [
            //               "Poor Quality",
            //               "Guest Rejected",
            //               "Changed Item",
            //               "Bad Taste",
            //               "Wrong Order"
            //             ].map((reason) {
            //               return ChoiceChip(
            //                 label: Text(reason, style: const TextStyle(color: Colors.white)),
            //                 selected: remarkNotifier.value == reason,
            //                 selectedColor: const Color(0xFF4C81F1),
            //                 backgroundColor: const Color(0xFF4C81F1).withOpacity(0.6),
            //                 onSelected: (_) {
            //                   remarkNotifier.value = reason;
            //                   setState(() {}); // updates TextField
            //                 },
            //               );
            //             }).toList(),
            //           ),
            //           const SizedBox(height: 8),
            //           Row(
            //             mainAxisAlignment: MainAxisAlignment.end,
            //             children: [
            //               OutlinedButton(
            //                 onPressed: () => remarkNotifier.value = null,
            //                 style: OutlinedButton.styleFrom(
            //                   backgroundColor: const Color(0xFFF6F6F6),
            //                   foregroundColor: Colors.black,
            //                   shape: RoundedRectangleBorder(
            //                     borderRadius: BorderRadius.circular(4),
            //                   ),
            //                 ),
            //                 child: const Text("Clear"),
            //               ),
            //               const SizedBox(width: 12),
            //               ElevatedButton(
            //                 onPressed: () {
            //                   itemsNotifier.value = itemsNotifier.value
            //                       .where((item) => !item.selected)
            //                       .toList();
            //                   remarkNotifier.value = null;
            //                 },
            //                 style: ElevatedButton.styleFrom(
            //                   backgroundColor: const Color(0xFFFE6464),
            //                   foregroundColor: Colors.white,
            //                   shape: RoundedRectangleBorder(
            //                     borderRadius: BorderRadius.circular(4),
            //                   ),
            //                 ),
            //                 child: const Text("Save"),
            //               ),
            //             ],
            //           ),
            //         ],
            //       ),
            //     );
            //   },
            // )
          ],
        ),
      ),
    );
  }
}
