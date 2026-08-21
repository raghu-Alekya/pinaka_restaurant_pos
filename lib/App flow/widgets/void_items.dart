import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../../blocs/Bloc Event/kot_event.dart';
import '../../blocs/Bloc Event/void_item_evnts.dart';
import '../../blocs/Bloc Logic/kot_bloc.dart';
import '../../blocs/Bloc Logic/order_bloc.dart';
import '../../blocs/Bloc Logic/void_item_bloc.dart';
import '../../blocs/Bloc State/void_item_state.dart';
import '../../models/order/void_kot_items.dart';
import '../../repositories/void_item_repository.dart';
import '../../services/kds_seivices.dart';
import '../../utils/theme_provider.dart';

class VoidItemsDialog extends StatefulWidget {
  final List<KotItem> items;
  final String tableNo;
  final String kotNo;
  final int restaurantId;
  final int zoneId;
  final String token;
  final int parentOrderId;
  final String storedPinNumber;
  final String role;
  final int kotId;

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
    required this.zoneId, // ✅ now required properly
    required this.onRemark,
    required this.item,
    required this.storedPinNumber,
    required this.role,
  }) : super(key: key);

  @override
  State<VoidItemsDialog> createState() => _VoidItemsDialogState();
}

class _VoidItemsDialogState extends State<VoidItemsDialog> {
  // LEFT PANEL -> Original KOT items (never changes)
  late final List<KotItem> originalKotItems;
  // items which are reduced to 0
  final Map<int, VoidedKotItem> voidedItemsMap = {};
  // final repo = editkotRepository(baseUrl: '');

  // RIGHT PANEL -> Editable items
  late final ValueNotifier<List<KotItem>> itemsNotifier;

  final TextEditingController remarkController = TextEditingController();

  final ScrollController _rightScrollController = ScrollController();
  final ScrollController _leftScrollController = ScrollController();

  String? selectedReason;
  bool _showReasonError = false;
  final VoidItemRepository _voidItemRepository = VoidItemRepository();
  List<Map<String, dynamic>> _modifiedItems = [];
  bool _isLoadingLineItems = false;
  bool _hasQuantityChanged = false;
  // List<Map<String, dynamic>> _modifiedItems = [];
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

    _fetchVoidLineItems();
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
  Future<void> _fetchVoidLineItems() async {
    setState(() {
      _isLoadingLineItems = true;
    });

    try {
      final response = await _voidItemRepository.getKotLineItems(
        kotId: widget.kotId,
        restaurantId: widget.restaurantId,
        zoneId: widget.zoneId,
        token: widget.token,
      );

      debugPrint("Initial KOT Items: ${response.initialKotItems}");
      debugPrint("Voided Items: ${response.voidedItems}");
      debugPrint("Current Items: ${response.items}");

      // LEFT PANEL
      final initialItems = response.initialKotItems;

      // RIGHT PANEL
      final currentItems = response.items;

      if (mounted) {
        setState(() {
          originalKotItems.clear();

          // IMPORTANT:
          // InitialKotItem -> KotItem
          originalKotItems.addAll(
            initialItems.map((e) => e.toKotItem()),
          );

          // Already KotItem, so copyWith() is correct here
          itemsNotifier.value = currentItems
              .map((e) => e.copyWith())
              .toList();

          _hasQuantityChanged = false;
          _isLoadingLineItems = false;
        });
      }
    } catch (e) {
      debugPrint("❌ Failed to fetch KOT line items: $e");

      if (mounted) {
        setState(() {
          _isLoadingLineItems = false;
        });
      }
    }
  }
  double get subtotal =>
      itemsNotifier.value.fold(0.0, (sum, item) => sum + item.amount);

  int get totalItems =>
      itemsNotifier.value.fold(0, (sum, item) => sum + item.quantity);
  int get leftTotalItems =>
      originalKotItems.fold(
        0,
            (sum, item) => sum + item.originalQuantity,
      );

  double get leftTotalAmount =>
      originalKotItems.fold(
        0.0,
            (sum, item) =>
        sum + (item.originalQuantity * item.price),
      );

  // ─── Header ────────────────────────────────
  Widget _dialogHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2B3042) : const Color(0xFFF4F6FB),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        // border: isDark ? Border.all(color: Colors.white24) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Void Items",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : const Color(0xFF3C4A63),
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

  bool _checkQuantityChanged() {
    for (int i = 0; i < itemsNotifier.value.length; i++) {
      if (itemsNotifier.value[i].quantity != originalKotItems[i].quantity) {
        return true;
      }
    }
    return false;
  }

  bool get canSave {
    return _hasQuantityChanged &&
        selectedReason != null &&
        selectedReason!.trim().isNotEmpty;
  }

  Widget _tableHeaderRow({bool isLeft = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF34384F) : const Color(0xFFDCDADA),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
        border: isDark ? Border.all(color: Colors.white24) : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          SizedBox(
            width: isLeft ? 36 : 28,
            child: Center(
              child: Text(
                "#",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              "Item Name",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                "Quantity",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
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
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _qtyButton({required IconData icon, required VoidCallback? onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF4D0808) : const Color(0xFFFFE6E6),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isDark ? Colors.white24 : Colors.transparent,
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: isDark ? Colors.white : Colors.red,
        ),
      ),
    );
  }
  Widget _qtyButtonadd({required IconData icon, required VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: const Color(0xFFE4E4EC), // same blue/grey in light & dark
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: Colors.transparent,
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: Colors.grey,
        ),
      ),
    );
  }
  // ─── LEFT PANEL (Original KOT - No changes) ────────────────────────────────
  Widget _leftPanel() {
    final isDark = Provider.of<ThemeProvider>(context).isDark;
    return Expanded(
      flex: 1,
      child: Container(
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
            Text(
              "To void an item, please select the item and provide a reason for voiding.",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : const Color(0xFF4C5F7D),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: ShapeDecoration(
                  color: isDark ? const Color(0xFF202433) : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(
                      color: Colors.transparent,
                    ),
                  ),
                  shadows: isDark
                      ? []
                      : const [
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
                            color: Theme.of(context).dividerColor,
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
                            separatorBuilder:
                                (_, __) => Divider(
                              height: 1,
                              color: Theme.of(context).dividerColor,
                            ),
                            itemBuilder: (context, index) {
                              final item = originalKotItems[index];
                              final originalAmount =
                                  item.originalQuantity * item.price;
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    const SizedBox(width: 36),

                                    // Item Name + Modifiers
                                    Expanded(
                                      flex: 4,
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.productName,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodyMedium?.copyWith(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          if (item.modifiers.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 2,
                                              ),
                                              child: Text(
                                                "Modifiers: ${item.modifiers.join(", ")}",
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w500,
                                                  color:
                                                  isDark
                                                      ? Colors
                                                      .lightBlue
                                                      .shade200
                                                      : Colors.blueGrey,
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
                                          "${item.originalQuantity}",
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodyMedium?.copyWith(
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
                                          originalAmount.toStringAsFixed(2),
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
                      ),
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Text(
                          "Total Items : $leftTotalItems",
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          "Total Amount : ${leftTotalAmount.toStringAsFixed(2)}",
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color:
                        isDark
                            ? const Color(0xFF2A2F3D)
                            : const Color(0xFFF3F6FF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                "Enter Reason :",
                                style: TextStyle(
                                  color:
                                  Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.color,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  height: 38,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                    isDark
                                        ? const Color(0xFF202433)
                                        : Colors.white,
                                    border: Border.all(
                                      color:
                                      _showReasonError
                                          ? Colors.red
                                          : Theme.of(context).dividerColor,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: selectedReason,
                                      hint: Text(
                                        "Select Reason",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.color
                                              ?.withOpacity(0.7),
                                        ),
                                      ),
                                      isExpanded: true,
                                      icon: Icon(
                                        Icons.keyboard_arrow_down,
                                        color:
                                        _showReasonError
                                            ? Colors.red
                                            : null,
                                      ),
                                      items:
                                      voidReasons.map((reason) {
                                        return DropdownMenuItem(
                                          value: reason,
                                          child: Text(
                                            reason,
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          selectedReason = value;
                                          _showReasonError = false;
                                        });

                                        widget.onRemark(value ?? "");
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // Error message
                          if (_showReasonError)
                            Padding(
                              padding: const EdgeInsets.only(top: 4, left: 4),
                              child: Text(
                                "⚠ Please select a void reason",
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
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

  // ─── RIGHT PANEL (Editable) ────────────────────────────────
  Widget _rightPanel() {
    final bool isDark = Provider.of<ThemeProvider>(context).isDark;
    return Expanded(
      flex: 1,
      child: Container(
        padding: const EdgeInsets.all(12),
        color: isDark ? const Color(0xFF202433) : Colors.white,
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  "Table : #${widget.tableNo}",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(width: 18),
                Text(
                  "KOT : ${widget.kotNo}",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const Spacer(),
                Text(
                  "Date : ${DateTime.now().toLocal().toString().split(' ')[0]}   ${TimeOfDay.now().format(context)}",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: ShapeDecoration(
                  color: isDark ? const Color(0xFF202433) : Colors.white,
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
                                color: Theme.of(context).dividerColor,
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
                                      separatorBuilder:
                                          (_, __) => Divider(
                                        height: 1,
                                        color:
                                        Theme.of(context).dividerColor,
                                      ),
                                      itemBuilder: (context, index) {
                                        final item = rightItems[index];

                                        return Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          child: Row(
                                            children: [
                                              SizedBox(
                                                width: 28,
                                                child: Text(
                                                  "${index + 1}",
                                                  style: TextStyle(
                                                    color:
                                                    Theme.of(context)
                                                        .textTheme
                                                        .bodyLarge
                                                        ?.color,
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                flex: 4,
                                                child: Column(
                                                  crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      item.productName,
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        fontWeight:
                                                        FontWeight.w500,
                                                        color:
                                                        Theme.of(context)
                                                            .textTheme
                                                            .bodyLarge
                                                            ?.color,
                                                      ),
                                                    ),
                                                    if (item
                                                        .modifiers
                                                        .isNotEmpty)
                                                      Padding(
                                                        padding:
                                                        const EdgeInsets.only(
                                                          top: 2,
                                                        ),
                                                        child: Text(
                                                          "Modifiers: ${item.modifiers.join(", ")}",
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            fontWeight:
                                                            FontWeight.w500,
                                                            color:
                                                            isDark
                                                                ? Colors
                                                                .lightBlueAccent
                                                                : Colors
                                                                .blueGrey,
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
                                                    // ➖ Minus button
                                                    _qtyButton(
                                                      icon: Icons.remove,
                                                      onTap: () {
                                                        if (item.quantity <= 0)
                                                          return; // ✅ allow zero, stop below 0

                                                        item.quantity--;
                                                        item.amount =
                                                            item.price *
                                                                item.quantity;
                                                        setState(() {
                                                          _hasQuantityChanged =
                                                              _checkQuantityChanged();
                                                        });
                                                        // refresh UI
                                                        itemsNotifier
                                                            .value = List.from(
                                                          itemsNotifier.value,
                                                        );
                                                      },
                                                    ),

                                                    const SizedBox(width: 8),

                                                    Text(
                                                      "${item.quantity}",
                                                      style: TextStyle(
                                                        fontWeight:
                                                        FontWeight.w600,
                                                        fontSize: 12,
                                                        color:
                                                        Theme.of(context)
                                                            .textTheme
                                                            .bodyLarge
                                                            ?.color,
                                                      ),
                                                    ),

                                                    const SizedBox(width: 8),

                                                    // ➕ Plus button
                                                    (item.quantity < originalKotItems[index].quantity)
                                                        ? _qtyButton(
                                                      icon: Icons.add,
                                                      onTap: () {
                                                        final originalQty = originalKotItems[index].quantity;

                                                        if (item.quantity >= originalQty) return;

                                                        item.quantity++;
                                                        item.amount = item.price * item.quantity;

                                                        setState(() {
                                                          _hasQuantityChanged = _checkQuantityChanged();
                                                        });

                                                        itemsNotifier.value = List.from(itemsNotifier.value);
                                                      },
                                                    )
                                                        : _qtyButtonadd(
                                                      icon: Icons.add,
                                                      onTap: null,
                                                    ),
                                                  ],
                                                ),
                                              ),

                                              Expanded(
                                                flex: 2,
                                                child: Align(
                                                  alignment:
                                                  Alignment.centerRight,
                                                  child: Text(
                                                    item.amount.toStringAsFixed(
                                                      2,
                                                    ),
                                                    style: TextStyle(
                                                      fontWeight:
                                                      FontWeight.w600,
                                                      color:
                                                      Theme.of(context)
                                                          .textTheme
                                                          .bodyLarge
                                                          ?.color,
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
                        final bool isDark =
                            Theme.of(context).brightness == Brightness.dark;

                        final subtotal = items.fold(
                          0.0,
                              (sum, item) => sum + item.amount,
                        );
                        final totalItems = items.fold(
                          0,
                              (sum, item) => sum + item.quantity,
                        );

                        return Row(
                          children: [
                            Text(
                              "Total Items : $totalItems",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color:
                                Theme.of(
                                  context,
                                ).textTheme.bodyLarge?.color,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              "Sub Total : ${subtotal.toStringAsFixed(2)}",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color:
                                Theme.of(
                                  context,
                                ).textTheme.bodyLarge?.color,
                              ),
                            ),
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
                          onPressed: canSave
                              ? () {
                            if (selectedReason == null ||
                                selectedReason!.trim().isEmpty) {
                              setState(() {
                                _showReasonError = true;
                              });
                              return;
                            }

                            setState(() {
                              _showReasonError = false;
                            });

                            final modifiedAt = DateTime.now();

                            final selectedItems = itemsNotifier.value;
                            _modifiedItems = [];

                            for (final originalItem in originalKotItems) {
                              final modifiedItem = selectedItems.firstWhere(
                                    (item) => item.id == originalItem.id,
                                orElse: () => originalItem.copyWith(
                                  quantity: 0,
                                  amount: 0,
                                ),
                              );

                              if (originalItem.originalQuantity != modifiedItem.quantity) {
                                _modifiedItems.add({
                                  "itemId": originalItem.id,
                                  "productId": originalItem.productId,
                                  "itemName": originalItem.productName,
                                  "originalQuantity": originalItem.originalQuantity,
                                  "modifiedQuantity": modifiedItem.quantity,
                                  "voidQuantity":
                                  originalItem.originalQuantity - modifiedItem.quantity,
                                  "amount": modifiedItem.amount,
                                });
                              }
                            }

                            final auditData = {
                              "pinNumber": widget.storedPinNumber,
                              "role": widget.role,
                              "modifiedAt": modifiedAt.toIso8601String(),
                              "tableNo": widget.tableNo,
                              "kotNo": widget.kotNo,
                              "kotId": widget.kotId,
                              "reason": selectedReason,
                              "items": _modifiedItems,
                            };

                            debugPrint("========== VOID ITEM AUDIT ==========");
                            debugPrint("PIN: ${widget.storedPinNumber}");
                            debugPrint("Role: ${widget.role}");
                            debugPrint("Time: $modifiedAt");
                            debugPrint("Table: ${widget.tableNo}");
                            debugPrint("KOT: ${widget.kotNo}");
                            debugPrint("Reason: $selectedReason");
                            debugPrint("Modified Items: $_modifiedItems");
                            debugPrint("=====================================");

                            final request = UpdatekotRequest(
                              lineItems: selectedItems
                                  .map(
                                    (e) => LineItemUpdate(
                                  id: e.id,
                                  productId: e.productId,
                                  quantity: e.quantity,
                                ),
                              )
                                  .toList(),
                              metaData: [
                                MetaDataItem(
                                  key: "kot_remarks",
                                  value: selectedReason ?? "",
                                ),
                              ],
                            );

                            context.read<UpdatekotBloc>().add(
                              UpdatekotPressed(
                                token: widget.token,
                                kotId: widget.kotId,
                                request: request,
                              ),
                            );
                          }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                            canSave
                                ? const Color(0xFFFF6B6B)
                                : Colors.grey.shade400,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                              side: BorderSide(
                                color:
                                isDark
                                    ? Theme.of(context).dividerColor
                                    : Colors.transparent,
                              ),
                            ),
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
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocListener<UpdatekotBloc, UpdatekotState>(
      listener: (context, state) async {
        if (state is UpdatekotSuccess) {
          debugPrint('========== KOT UPDATE SUCCESS ==========');

          for (final item in _modifiedItems) {
            await KdsMqttPublisher.notifyKotItemQuantityUpdated(
              restaurantId: widget.restaurantId.toString(),
              kotId: widget.kotId,
              kotNumber: widget.kotNo,
              itemId: item['itemId'],
              quantity: item['modifiedQuantity'],
              parentOrderId: widget.parentOrderId,
            );
          }

          debugPrint('✅ QUANTITY MQTT SENT');

          context.read<KotBloc>().add(
            FetchKots(
              parentOrderId: widget.parentOrderId,
              restaurantId: widget.restaurantId,
              zoneId: widget.zoneId,
              token: widget.token,
            ),
          );

          Navigator.pop(context, true);
        }
        if (state is UpdatekotFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message ?? "Update failed"),
              duration: Duration(seconds: 1),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          // side: BorderSide(color: isDark ? Colors.white24 : Colors.transparent),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 26, vertical: 10),
        backgroundColor: isDark ? const Color(0xFF202433) : Colors.white,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.82,
          height: MediaQuery.of(context).size.height * 0.82,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF202433) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            // border: Border.all(
            //   color: isDark ? Colors.white24 : Colors.transparent,
            // ),
          ),
          child: Column(
            children: [
              _dialogHeader(context),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 4,
                  ),
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
