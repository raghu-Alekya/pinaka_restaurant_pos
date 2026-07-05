import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/Bloc Event/kot_event.dart';
import '../../blocs/Bloc Event/void_item_evnts.dart';
import '../../blocs/Bloc Logic/kot_bloc.dart';
import '../../blocs/Bloc Logic/order_bloc.dart';
import '../../blocs/Bloc Logic/void_item_bloc.dart';
import '../../blocs/Bloc State/void_item_state.dart';
import '../../models/order/void_kot_items.dart';
import '../../repositories/void_item_repository.dart';

class VoidItemsDialog extends StatefulWidget {
  final List<KotItem> items;
  final String tableNo;
  final String kotNo;
  final int restaurantId;   // ✅ add
  final int zoneId;
  final String token;
  final int parentOrderId; // ✅ add


  final int kotId; // ✅ add this field

  final void Function(String value) onRemark;
  final dynamic item;

  const VoidItemsDialog({
    Key? key,
    required this.token,
    required this.items,
    required this.tableNo,
    required this.kotNo,
    required this.kotId,
    required this.restaurantId,
    required this.parentOrderId, // ✅ add
    required this.zoneId,  // ✅ now required properly
    required this.onRemark,
    required this.item,
  }) : super(key: key);

  @override
  State<VoidItemsDialog> createState() => _VoidItemsDialogState();
}


class _VoidItemsDialogState extends State<VoidItemsDialog> {
  // LEFT PANEL -> Original KOT items (never changes)
  late final List<KotItem> originalKotItems;

  // final repo = editkotRepository(baseUrl: '');

  // RIGHT PANEL -> Editable items
  late final ValueNotifier<List<KotItem>> itemsNotifier;

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
    originalKotItems = widget.items.map((e) => e.copyWith()).toList();

// RIGHT PANEL (editable copy)
    itemsNotifier = ValueNotifier<List<KotItem>>(
      widget.items.map((e) => e.copyWith()).toList(),
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

  int get leftTotalItems =>
      originalKotItems.fold(0, (sum, item) => sum + item.quantity);

  double get leftTotalAmount =>
      originalKotItems.fold(0.0, (sum, item) => sum + item.amount);

  // ─── Header ────────────────────────────────
  Widget _dialogHeader(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Color(0xffF4F6FB),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Void Items",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w500,
              color: Color(0xff3C4A63),
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
      decoration: const BoxDecoration(
        color: Color(0xFFDCDADA),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
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

  // ─── LEFT PANEL (Original KOT - No changes) ────────────────────────────────
  Widget _leftPanel() {
    return Expanded(
        flex: 1,
        child:Container(
          // decoration: BoxDecoration(
          //   color: Colors.white,
          //   borderRadius: BorderRadius.circular(12),
          //   border: Border.all(
          //     color: const Color(0xffE6E8EF),
          //   ),
          //   boxShadow: [
          //     BoxShadow(
          //       color: Colors.black.withOpacity(.04),
          //       blurRadius: 12,
          //       offset: const Offset(0, 4),
          //     )
          //   ],
          // ),
            padding: const EdgeInsets.all(12),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "To void an item, please select the item and provide a reason for voiding.",
                    style: TextStyle(fontSize: 14, color: Color(0xFF4C5F7D),fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: ShapeDecoration(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        shadows: const [
                          BoxShadow(
                            color: Color(0x19000000),
                            blurRadius: 0,
                            offset: Offset(0, 0),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _tableHeaderRow(isLeft: true),

                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xFFE6E6E6),
                                ),
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(8),
                                  bottomRight: Radius.circular(8),
                                ),
                              ),
                              child: Scrollbar(
                                controller: _leftScrollController,
                                thumbVisibility: true,
                                interactive: true,
                                child: ListView.separated(
                                  controller: _leftScrollController,
                                  itemCount: originalKotItems.length,
                                  separatorBuilder: (_, __) =>
                                  const Divider(
                                    height: 1,
                                    color: Color(0xFFEDEDED),
                                  ),
                                  itemBuilder: (context, index) {
                                    final item = originalKotItems[index];

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 12),
                                      child: Row(
                                        children: [
                                          const SizedBox(width: 36),

                                          // Item Name + Modifiers
                                          Expanded(
                                            flex: 4,
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item.productName,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                if (item.modifiers.isNotEmpty)
                                                  Padding(
                                                    padding: const EdgeInsets.only(top: 2),
                                                    child: Text(
                                                      "Modifiers: ${item.modifiers.join(
                                                          ", ")}",
                                                      style: const TextStyle(
                                                        fontSize: 10,
                                                        color: Colors.blueGrey,
                                                        fontWeight: FontWeight.w500,
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
                          const SizedBox(height: 8),

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
                            child:
                            Row(
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
                  )]))
    );
  }

  // ─── RIGHT PANEL (Editable) ────────────────────────────────
  Widget _rightPanel() {
    return Expanded(
        flex: 1,
        child: Container(
            padding: const EdgeInsets.all(12),
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
                        "Date :  ${DateTime.now().toLocal().toString().split(
                            ' ')[0]}   ${TimeOfDay.now().format(context)}",
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600 ,color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: ShapeDecoration(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        // shadows: const [
                        //   BoxShadow(
                        //     color: Color(0x19000000),
                        //     blurRadius: 10,
                        //     offset: Offset(0, 0),
                        //     spreadRadius: 0,
                        //   ),
                        // ],
                      ),
                      child: Column(
                        children: [
                          _tableHeaderRow(isLeft: false),

                          Expanded(
                            child: ValueListenableBuilder<List<KotItem>>(
                              valueListenable: itemsNotifier,
                              builder: (context, items, _) {
                                final rightItems = items;

                                return Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: const Color(0xFFE6E6E6),
                                    ),
                                    borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(8),
                                      bottomRight: Radius.circular(8),
                                    ),
                                    // shadows: const [
                                    //   BoxShadow(
                                    //     color: Color(0x19000000),
                                    //     blurRadius: 10,
                                    //     offset: Offset(0, 0),
                                    //     spreadRadius: 0,
                                    //   ),
                                    // ],

                                  ),
                                  child: Column(
                                    children: [

                                      /// LIST
                                      Expanded(
                                        child: Scrollbar(
                                          controller: _rightScrollController,
                                          thumbVisibility: true,
                                          interactive: true,
                                          child: ListView.separated(
                                            controller: _rightScrollController,
                                            itemCount: rightItems.length,
                                            separatorBuilder: (_, __) =>
                                            const Divider(
                                              height: 1,
                                              color: Color(0xFFEDEDED),
                                            ),
                                            itemBuilder: (context, index) {
                                              final item = rightItems[index];

                                              return Padding(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 12, vertical: 8),
                                                child: Row(
                                                  children: [
                                                    SizedBox(
                                                      width: 28,
                                                      child: Text("${index + 1}"),
                                                    ),
                                                    Expanded(
                                                      flex: 4,
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment
                                                            .start,
                                                        children: [
                                                          Text(
                                                            item.productName,
                                                            style: const TextStyle(
                                                              fontSize: 13,
                                                              fontWeight: FontWeight.w500,
                                                            ),
                                                          ),
                                                          if (item.modifiers.isNotEmpty)
                                                            Padding(
                                                              padding: const EdgeInsets.only(
                                                                  top: 2),
                                                              child: Text(
                                                                "Modifiers: ${item.modifiers
                                                                    .join(", ")}",
                                                                style: const TextStyle(
                                                                  fontSize: 10,
                                                                  color: Colors.blueGrey,
                                                                  fontWeight: FontWeight.w500,
                                                                ),
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                    ),

                                                    Expanded(
                                                      flex: 2,
                                                      child: Row(
                                                        mainAxisAlignment: MainAxisAlignment
                                                            .center,
                                                        children: [
                                                          // ➖ Minus button
                                                          _qtyButton(
                                                            icon: Icons.remove,
                                                            onTap: () {
                                                              if (item.quantity <= 0)
                                                                return; // ✅ allow zero, stop below 0

                                                              item.quantity--;
                                                              item.amount =
                                                                  item.price * item.quantity;

                                                              // refresh UI
                                                              itemsNotifier.value = List.from(
                                                                  itemsNotifier.value);
                                                            },
                                                          ),


                                                          const SizedBox(width: 8),

                                                          Text(
                                                            "${item.quantity}",
                                                            style: const TextStyle(
                                                                fontWeight: FontWeight.w600),
                                                          ),

                                                          const SizedBox(width: 8),

                                                          // ➕ Plus button
                                                          _qtyButton(
                                                            icon: Icons.add,
                                                            onTap: () {
                                                              final originalQty = originalKotItems[index]
                                                                  .quantity;

                                                              if (item.quantity >=
                                                                  originalQty) {
                                                                ScaffoldMessenger
                                                                    .of(context)
                                                                    .showSnackBar(
                                                                  SnackBar(
                                                                    content: Text(
                                                                      "Cannot exceed actual quantity ($originalQty)",
                                                                    ),
                                                                    duration: Duration(seconds: 1),
                                                                    backgroundColor: Colors.red,
                                                                  ),
                                                                );
                                                                return;
                                                              }

                                                              item.quantity++;
                                                              item.amount =
                                                                  item.price * item.quantity;

                                                              // refresh UI
                                                              itemsNotifier.value = List.from(
                                                                  itemsNotifier.value);
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
                                                              fontWeight: FontWeight.w600),
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

                                    ],
                                  ),
                                );
                              },
                            ),
                          ),

                          // const SizedBox(height: 5),

                          const SizedBox(height: 6),

                          /// TOTAL ROW OUTSIDE CONTAINER
                          ValueListenableBuilder<List<KotItem>>(
                            valueListenable: itemsNotifier,
                            builder: (context, items, _) {
                              final subtotal = items.fold(
                                  0.0, (sum, item) => sum + item.amount);
                              final totalItems = items.fold(
                                  0, (sum, item) => sum + item.quantity);

                              return Row(
                                children: [
                                  Text("Total Items : $totalItems",
                                      style: const TextStyle(
                                          fontSize: 14, fontWeight: FontWeight.w600)),
                                  const Spacer(),
                                  Text("Sub Total : ${subtotal.toStringAsFixed(2)}",
                                      style: const TextStyle(
                                          fontSize: 14, fontWeight: FontWeight.w600)),
                                ],
                              );
                            },
                          ),


                          const SizedBox(height: 28),

                          Align(
                            alignment: Alignment.centerRight,
                            child: SizedBox(
                              width: 150,
                              height: 40,
                              child: ElevatedButton(
                                onPressed: () {
                                  debugPrint("✅ Save clicked");
                                  debugPrint("kotId = ${widget.kotId}");
                                  debugPrint("token = ${widget.token}");
                                  debugPrint("selectedReason = $selectedReason");

                                  final selectedItems = itemsNotifier.value; // ✅ include 0 qty also

                                  debugPrint("selectedItems count = ${selectedItems.length}");

                                  final request = UpdatekotRequest(
                                    lineItems: selectedItems
                                        .map((e) => LineItemUpdate(id: e.id, productId: e.productId,  quantity: e.quantity))
                                        .toList(),
                                    metaData: [
                                      MetaDataItem(key: "kot_remarks", value: selectedReason ?? ""),
                                    ],
                                  );

                                  context.read<UpdatekotBloc>().add(
                                    UpdatekotPressed(
                                      token: widget.token,
                                      kotId: widget.kotId,
                                      request: request,
                                    ),
                                  );
                                },

                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF6B6B),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  " Save ",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: false,
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

                  )]))

    );

  }


  @override
  Widget build(BuildContext context) {
    return BlocListener<UpdatekotBloc, UpdatekotState>(
      listener: (context, state) {
        if (state is UpdatekotSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("KOT Updated Successfully"),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),),
          );

          /// ✅ Refresh KOT list using KotBloc
          context.read<KotBloc>().add(
            FetchKots(
              parentOrderId: widget.parentOrderId,
              // if you have in response
              restaurantId: widget.restaurantId,
              zoneId: widget.zoneId,
              token: widget.token,
            ),
          );

          Navigator.pop(context, true);
        }

        if (state is UpdatekotFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message ?? "Update failed"),
              duration: Duration(seconds: 1),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 26, vertical: 10),
        backgroundColor: Colors.white,
        child: Container(
          width: MediaQuery
              .of(context)
              .size
              .width * 0.82,
          height: MediaQuery
              .of(context)
              .size
              .height * 0.82,
          decoration: BoxDecoration(
            // border: Border.all(color: const Color(0xFF1E63FF), width: 2),
          ),
          child: Column(
            children: [
              _dialogHeader(context),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _leftPanel(),
                      const SizedBox(width: 10),
                      _rightPanel(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}