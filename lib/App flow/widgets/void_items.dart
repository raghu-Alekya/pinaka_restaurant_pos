import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../../blocs/Bloc Event/kot_event.dart';
import '../../blocs/Bloc Event/void_item_evnts.dart';
import '../../blocs/Bloc Logic/kot_bloc.dart';
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
    required this.parentOrderId,
    required this.zoneId,
    required this.onRemark,
    required this.item,
    required this.storedPinNumber,
    required this.role,
  }) : super(key: key);

  @override
  State<VoidItemsDialog> createState() => _VoidItemsDialogState();
}

class _VoidItemsDialogState extends State<VoidItemsDialog> {
  // ---------------------------------------------------------------------------
  // DATA
  // ---------------------------------------------------------------------------

  /// LEFT PANEL
  /// Original KOT items. This list never changes when the user edits quantity.
  late final List<KotItem> originalKotItems;

  /// RIGHT PANEL
  /// Editable copy of the KOT items.
  late final ValueNotifier<List<KotItem>> itemsNotifier;

  /// Items whose quantity was changed.
  final Map<int, VoidedKotItem> voidedItemsMap = {};

  final TextEditingController remarkController =
  TextEditingController();

  final ScrollController _rightScrollController =
  ScrollController();

  final ScrollController _leftScrollController =
  ScrollController();

  final VoidItemRepository _voidItemRepository =
  VoidItemRepository();

  List<Map<String, dynamic>> _modifiedItems = [];

  bool _isLoadingLineItems = false;
  bool _hasQuantityChanged = false;
  bool _showReasonError = false;

  String? selectedReason;

  final List<String> voidReasons = [
    "Wrong Item",
    "Customer Cancelled",
    "Kitchen Delay",
    "Order Mistake",
    "Other",
  ];

  // ---------------------------------------------------------------------------
  // INIT
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();

    originalKotItems =
        widget.items.map((e) => e.copyWith()).toList();

    itemsNotifier = ValueNotifier<List<KotItem>>(
      widget.items.map((e) => e.copyWith()).toList(),
    );

    _fetchVoidLineItems();
  }

  // ---------------------------------------------------------------------------
  // DISPOSE
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    itemsNotifier.dispose();
    remarkController.dispose();
    _rightScrollController.dispose();
    _leftScrollController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // API
  // ---------------------------------------------------------------------------

  Future<void> _fetchVoidLineItems() async {
    if (mounted) {
      setState(() {
        _isLoadingLineItems = true;
      });
    }

    try {
      final response =
      await _voidItemRepository.getKotLineItems(
        kotId: widget.kotId,
        restaurantId: widget.restaurantId,
        zoneId: widget.zoneId,
        token: widget.token,
      );

      debugPrint(
        "Initial KOT Items: ${response.initialKotItems}",
      );

      debugPrint(
        "Voided Items: ${response.voidedItems}",
      );

      debugPrint(
        "Current Items: ${response.items}",
      );

      final initialItems = response.initialKotItems;
      final currentItems = response.items;

      if (!mounted) return;

      setState(() {
        // LEFT PANEL
        originalKotItems.clear();

        originalKotItems.addAll(
          initialItems.map(
                (e) => e.toKotItem(),
          ),
        );

        // RIGHT PANEL
        itemsNotifier.value = currentItems
            .map(
              (e) => e.copyWith(),
        )
            .toList();

        _hasQuantityChanged = false;
        _isLoadingLineItems = false;
      });
    } catch (e) {
      debugPrint(
        "❌ Failed to fetch KOT line items: $e",
      );

      if (!mounted) return;

      setState(() {
        _isLoadingLineItems = false;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // TOTALS
  // ---------------------------------------------------------------------------

  double get previousKotAmount {
    return originalKotItems.fold(
      0.0,
          (sum, item) =>
      sum +
          (item.originalQuantity * item.price),
    );
  }

  double get updatedKotAmount {
    return itemsNotifier.value.fold(
      0.0,
          (sum, item) => sum + item.amount,
    );
  }

  int get leftTotalItems {
    return originalKotItems.fold(
      0,
          (sum, item) =>
      sum + item.originalQuantity,
    );
  }

  int get rightTotalItems {
    return itemsNotifier.value.fold(
      0,
          (sum, item) => sum + item.quantity,
    );
  }

  // ---------------------------------------------------------------------------
  // CHANGE COUNT
  // ---------------------------------------------------------------------------

  int get changeCount {
    int count = 0;

    for (final original in originalKotItems) {
      final current = _findCurrentItem(original.id);

      final currentQuantity =
          current?.quantity ?? 0;

      if (original.originalQuantity !=
          currentQuantity) {
        count++;
      }
    }

    return count;
  }

  // ---------------------------------------------------------------------------
  // FIND CURRENT ITEM
  // ---------------------------------------------------------------------------

  KotItem? _findCurrentItem(int id) {
    for (final item in itemsNotifier.value) {
      if (item.id == id) {
        return item;
      }
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // QUANTITY CHANGE CHECK
  // ---------------------------------------------------------------------------

  bool _checkQuantityChanged() {
    for (final original in originalKotItems) {
      final current = _findCurrentItem(original.id);

      final currentQuantity =
          current?.quantity ?? 0;

      if (currentQuantity !=
          original.originalQuantity) {
        return true;
      }
    }

    return false;
  }

  // ---------------------------------------------------------------------------
  // CAN SAVE
  // ---------------------------------------------------------------------------

  bool get canSave {
    return _hasQuantityChanged &&
        selectedReason != null &&
        selectedReason!.trim().isNotEmpty;
  }

  // ---------------------------------------------------------------------------
  // REFRESH ITEMS
  // ---------------------------------------------------------------------------

  void _refreshItems() {
    _hasQuantityChanged =
        _checkQuantityChanged();

    itemsNotifier.value =
    List<KotItem>.from(
      itemsNotifier.value,
    );

    setState(() {});
  }

  // ---------------------------------------------------------------------------
  // RESET
  // ---------------------------------------------------------------------------

  void _resetChanges() {
    final resetItems = originalKotItems
        .map(
          (item) => item.copyWith(
        quantity: item.originalQuantity,
        amount:
        item.originalQuantity *
            item.price,
      ),
    )
        .toList();

    itemsNotifier.value = resetItems;

    setState(() {
      _hasQuantityChanged = false;
      _showReasonError = false;
      selectedReason = null;
    });

    widget.onRemark("");
  }

  // ===========================================================================
  // HEADER
  // ===========================================================================

  Widget _dialogHeader(BuildContext context) {
    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF2B3042)
            : const Color(0xFFF1F3F7),
        borderRadius:
        const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          // ---------------------------------------------------------------
          // TITLE
          // ---------------------------------------------------------------

          Expanded(
            flex: 8,
            child: Column(
              mainAxisAlignment:
              MainAxisAlignment.center,
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  "VOID ITEMS",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight:
                    FontWeight.w700,
                    color: isDark
                        ? Colors.white
                        : const Color(
                      0xFF1F2937,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "To void an item please select the item and provide a reason for voiding",
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? Colors.white60
                        : const Color(
                      0xFF8A8F98,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ---------------------------------------------------------------
          // TABLE / KOT
          // ---------------------------------------------------------------

          Expanded(
            flex: 4,
            child: Column(
              mainAxisAlignment:
              MainAxisAlignment.center,
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  "Table: ${widget.tableNo}",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                    FontWeight.w600,
                    color: isDark
                        ? Colors.white70
                        : const Color(
                      0xFF53627A,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  "${widget.kotNo}",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight:
                    FontWeight.w700,
                    color: isDark
                        ? Colors.white
                        : const Color(
                      0xFF53627A,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ---------------------------------------------------------------
          // TIME / DATE
          // ---------------------------------------------------------------

          Expanded(
            flex: 3,
            child: Column(
              mainAxisAlignment:
              MainAxisAlignment.center,
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  "Time: ${TimeOfDay.now().format(context)}",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                    FontWeight.w500,
                    color: isDark
                        ? Colors.white70
                        : const Color(
                      0xFF53627A,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  "Date: ${DateTime.now().toLocal().toString().split(' ')[0]}",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                    FontWeight.w500,
                    color: isDark
                        ? Colors.white70
                        : const Color(
                      0xFF53627A,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ---------------------------------------------------------------
          // CLOSE
          // ---------------------------------------------------------------

          InkWell(
            onTap: () =>
                Navigator.pop(context),
            borderRadius:
            BorderRadius.circular(20),
            child: Container(
              width: 22,
              height: 22,
              decoration:
              const BoxDecoration(
                color: Color(0xFFFF4545),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TABLE HEADER
  // ===========================================================================

  Widget _tableHeaderRow({
    bool isLeft = false,
  }) {
    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    return Container(
      height: 32,
      padding:
      const EdgeInsets.symmetric(
        horizontal: 10,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF34384F)
            : const Color(0xFF354052),
        // borderRadius:
        // const BorderRadius.only(
        //   topLeft: Radius.circular(8),
        //   topRight: Radius.circular(8),
        // ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: const Text(
              "#",
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),

          Expanded(
            flex: 4,
            child: const Text(
              "Item Name",
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),

          Expanded(
            flex: 2,
            child: Center(
              child: const Text(
                "Quantity",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                  FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          Expanded(
            flex: 2,
            child: Align(
              alignment:
              Alignment.centerRight,
              child: const Text(
                "Amount",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                  FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SMALL MINUS BUTTON
  // ===========================================================================

  Widget _smallMinusButton({
    required bool enabled,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius:
      BorderRadius.circular(4),
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: enabled
              ? const Color(0xFFFFE1E1)
              : const Color(0xFFF1F1F1),
          borderRadius:
          BorderRadius.circular(3),
        ),
        child: Icon(
          Icons.remove,
          size: 11,
          color: enabled
              ? const Color(0xFFE85D5D)
              : Colors.grey.shade400,
        ),
      ),
    );
  }

  // ===========================================================================
  // SMALL PLUS BUTTON
  // ===========================================================================

  Widget _smallPlusButton({
    required bool enabled,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius:
      BorderRadius.circular(4),
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: enabled
              ? const Color(0xFFE0F8E9)
              : const Color(0xFFF1F1F1),
          borderRadius:
          BorderRadius.circular(3),
        ),
        child: Icon(
          Icons.add,
          size: 11,
          color: enabled
              ? const Color(0xFF32A85A)
              : Colors.grey.shade400,
        ),
      ),
    );
  }

  // ===========================================================================
  // LEFT PANEL - ORIGINAL KOT
  // ===========================================================================

  Widget _leftPanel() {
    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF202433)
              : Colors.white,
          borderRadius:
          BorderRadius.circular(9),
          border: Border.all(
            color: isDark
                ? Colors.white12
                : const Color(0xFFBFC4CC),
          ),
        ),
        child: Column(
          children: [
            // -------------------------------------------------------------
            // PANEL TITLE
            // -------------------------------------------------------------

            Container(
              height: 32,
              padding:
              const EdgeInsets.symmetric(
                horizontal: 10,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF202433)
                    : const Color(0xFFF8FAFC),
                borderRadius:
                const BorderRadius.only(
                  topLeft:
                  Radius.circular(9),
                  topRight:
                  Radius.circular(9),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    "ORIGINAL KOT",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight:
                      FontWeight.w700,
                      color: isDark
                          ? Colors.lightBlueAccent
                          : const Color(
                        0xFF53698A,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    "${widget.kotNo} · Current KOT before changes",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight:
                      FontWeight.w700,
                      color: isDark
                          ? Colors.white54
                          : const Color(
                        0xFF9AA8BA,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            _tableHeaderRow(
              isLeft: true,
            ),

            // -------------------------------------------------------------
            // ITEMS
            // -------------------------------------------------------------

            Expanded(
              child: Scrollbar(
                controller: _leftScrollController,
                thumbVisibility: true,
                interactive: true,
                child: ListView.separated(
                  controller: _leftScrollController,
                  padding: EdgeInsets.zero,
                  itemCount: originalKotItems.length,

                  separatorBuilder: (_, __) => const SizedBox.shrink(),

                  itemBuilder: (context, index) {
                    final item = originalKotItems[index];

                    final amount =
                        item.originalQuantity * item.price;

                    // Alternating row background colors
                    final rowColor = isDark
                        ? (index.isEven
                        ? const Color(0xFF202433)
                        : const Color(0xFF252A38))
                        : (index.isEven
                        ? const Color(0xFFFAFBFC)
                        : const Color(0xFFF1F5F9));

                    return Container(
                      height: 42,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                      ),
                      decoration: BoxDecoration(
                        color: rowColor,
                        border: Border(
                          bottom: BorderSide(
                            color: isDark
                                ? Colors.white10
                                : const Color(0xFFF0F1F3),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          // #
                          SizedBox(
                            width: 36,
                            child: Text(
                              "${index + 1}",
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? Colors.white70
                                    : const Color(0xFF718096),
                              ),
                            ),
                          ),

                          // Item Name
                          Expanded(
                            flex: 4,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.productName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF253044),
                                  ),
                                ),

                                if (item.modifiers.isNotEmpty)
                                  Text(
                                    item.modifiers.join(", "),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 8,
                                      color: Color(0xFF3978D3),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // Quantity
                          Expanded(
                            flex: 2,
                            child: Center(
                              child: Text(
                                "${item.originalQuantity}",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF253044),
                                ),
                              ),
                            ),
                          ),

                          // Amount
                          Expanded(
                            flex: 2,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                amount.toStringAsFixed(2),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF253044),
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

            // -------------------------------------------------------------
            // LEFT TOTAL
            // -------------------------------------------------------------

            Container(
              height: 34,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2A2F3D)
                    : const Color(0xFFF8FAFC),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    "Total Items : $leftTotalItems",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? Colors.white70
                          : const Color(0xFF53627A),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    "Total Amount : ${previousKotAmount.toStringAsFixed(2)}",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? Colors.white70
                          : const Color(0xFF53627A),
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

  // ===========================================================================
  // RIGHT PANEL - PROPOSED CHANGES
  // ===========================================================================

  Widget _rightPanel() {
    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF202433)
              : Colors.white,
          borderRadius:
          BorderRadius.circular(9),
          border: Border.all(
            color: isDark
                ? Colors.white12
                : const Color(0xFFBFC4CC),
          ),
        ),
        child: Column(
          children: [
            // -------------------------------------------------------------
            // PANEL TITLE
            // -------------------------------------------------------------

            Container(
              height: 32,
              padding:
              const EdgeInsets.symmetric(
                horizontal: 10,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF202433)
                    : const Color(0xFFF8FAFC),
                borderRadius:
                const BorderRadius.only(
                  topLeft:
                  Radius.circular(9),
                  topRight:
                  Radius.circular(9),
                ),
              ),
              child: Row(
                children: [
                  const Text(
                    "PROPOSED CHANGES",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight:
                      FontWeight.w700,
                      color: Color(
                        0xFF2468D8,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    "Changes you are making",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight:
                      FontWeight.w700,
                      color: isDark
                          ? Colors.white54
                          : const Color(
                        0xFF9AA8BA,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            _tableHeaderRow(),

            // -------------------------------------------------------------
            // ITEMS
            // -------------------------------------------------------------

            Expanded(
              child: ValueListenableBuilder<
                  List<KotItem>>(
                valueListenable:
                itemsNotifier,
                builder:
                    (context, items, _) {
                  return Scrollbar(
                    controller:
                    _rightScrollController,
                    thumbVisibility: true,
                    interactive: true,
                    child:
                    ListView.separated(
                      controller:
                      _rightScrollController,
                      padding: EdgeInsets.zero,
                      itemCount: items.length,
                      separatorBuilder:
                          (_, __) => Divider(
                        height: 1,
                        color: isDark
                            ? Colors.white10
                            : const Color(
                          0xFFF0F1F3,
                        ),
                      ),
                      itemBuilder:
                          (context, index) {
                        final item =
                        items[index];

                        final originalItem =
                        originalKotItems[
                        index];

                        final originalQty =
                            originalItem
                                .originalQuantity;

                        final currentQty =
                            item.quantity;

                        final isRemoved =
                            currentQty == 0;

                        final isReduced =
                            currentQty <
                                originalQty &&
                                currentQty > 0;

                        return Container(
                          height: isRemoved
                              ? 45
                              : isReduced
                              ? 45
                              : 42,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isRemoved
                                ? (isDark
                                ? const Color(0xFF3A2024)
                                : const Color(0xFFFFF0F0))
                                : isReduced
                                ? (isDark
                                ? const Color(0xFF393522)
                                : const Color(0xFFFFFBEB))
                                : (isDark
                                ? (index.isEven
                                ? const Color(0xFF202433)
                                : const Color(0xFF252A38))
                                : (index.isEven
                                ? const Color(0xFFFAFBFC)
                                : const Color(0xFFF1F5F9))),
                            border: Border(
                              bottom: BorderSide(
                                color: isDark
                                    ? Colors.white10
                                    : const Color(0xFFF0F1F3),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              // -------------------------------------------------
                              // #
                              // -------------------------------------------------

                              SizedBox(
                                width: 36,
                                child: Text(
                                  "${index + 1}",
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? Colors.white70
                                        : const Color(0xFF718096),
                                  ),
                                ),
                              ),

                              // -------------------------------------------------
                              // ITEM NAME
                              // -------------------------------------------------

                              Expanded(
                                flex: 4,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.productName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: isRemoved
                                            ? Colors.red
                                            : isDark
                                            ? Colors.white
                                            : const Color(0xFF253044),
                                        decoration: isRemoved
                                            ? TextDecoration.lineThrough
                                            : TextDecoration.none,
                                      ),
                                    ),

                                    // MODIFIERS
                                    if (item.modifiers.isNotEmpty)
                                      Text(
                                        item.modifiers.join(", "),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w500,
                                          color: isRemoved
                                              ? Colors.red
                                              : const Color(0xFF3978D3),
                                        ),
                                      ),

                                    // REMOVED
                                    if (isRemoved)
                                      const Text(
                                        "Removed",
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.red,
                                        ),
                                      )

                                    // REDUCED
                                    else if (isReduced)
                                      const Text(
                                        "↓ Reduced",
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFFD98B00),
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                              // -------------------------------------------------
                              // QUANTITY
                              // -------------------------------------------------

                              Expanded(
                                flex: 2,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _smallMinusButton(
                                      enabled: currentQty > 0,
                                      onTap: currentQty > 0
                                          ? () {
                                        item.quantity--;

                                        item.amount =
                                            item.price * item.quantity;

                                        _refreshItems();
                                      }
                                          : null,
                                    ),

                                    const SizedBox(width: 7),

                                    SizedBox(
                                      width: 20,
                                      child: Center(
                                        child: Text(
                                          "$currentQty",
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: isRemoved
                                                ? Colors.red
                                                : isDark
                                                ? Colors.white
                                                : const Color(0xFF253044),
                                          ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(width: 7),

                                    _smallPlusButton(
                                      enabled: currentQty < originalQty,
                                      onTap: currentQty < originalQty
                                          ? () {
                                        item.quantity++;

                                        item.amount =
                                            item.price * item.quantity;

                                        _refreshItems();
                                      }
                                          : null,
                                    ),
                                  ],
                                ),
                              ),

                              // -------------------------------------------------
                              // AMOUNT
                              // -------------------------------------------------

                              Expanded(
                                flex: 2,
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    item.amount.toStringAsFixed(2),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isRemoved
                                          ? Colors.red
                                          : isDark
                                          ? Colors.white
                                          : const Color(0xFF253044),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),

            // -------------------------------------------------------------
            // RIGHT TOTAL
            // -------------------------------------------------------------
            ValueListenableBuilder<List<KotItem>>(
              valueListenable: itemsNotifier,
              builder: (context, items, _) {
                return Container(
                  height: 34,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2A2F3D)
                        : const Color(0xFFF8FAFC),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        "Total Items : $rightTotalItems",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white70
                              : const Color(0xFF53627A),
                        ),
                      ),

                      const Spacer(),

                      Text(
                        "Total Amount : ${updatedKotAmount.toStringAsFixed(2)}",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white70
                              : const Color(0xFF53627A),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // BOTTOM FOOTER
  // ===========================================================================

  Widget _bottomFooter() {
    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    return Container(
      height: 60,
      // width: 560,
      padding:
      const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF182A47)
            : const Color(0xFF203E68),
        borderRadius:
        const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          // -----------------------------------------------------------------
          // PREVIOUS KOT
          // -----------------------------------------------------------------

          Padding(
            padding:
            const EdgeInsets.symmetric(
              horizontal: 6,
            ),
            child: Column(
              mainAxisAlignment:
              MainAxisAlignment.center,
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                const Text(
                  "PREVIOUS KOT",
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(
                      0xFF8FA7C5,
                    ),
                    fontWeight:
                    FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "₹${previousKotAmount.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // -----------------------------------------------------------------
          // ARROW
          // -----------------------------------------------------------------

          const Icon(
            Icons.arrow_forward,
            size: 18,
            color: Color(0xFF6D8DB6),
          ),

          const SizedBox(width: 10),

          // -----------------------------------------------------------------
          // UPDATED KOT
          // -----------------------------------------------------------------

          Column(
            mainAxisAlignment:
            MainAxisAlignment.center,
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              const Text(
                "UPDATED KOT",
                style: TextStyle(
                  fontSize: 10,
                  color: Color(
                    0xFF8FA7C5,
                  ),
                  fontWeight:
                  FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "₹${updatedKotAmount.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(
                    0xFF65D58A,
                  ),
                  fontWeight:
                  FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(width: 16),

          // -----------------------------------------------------------------
          // CHANGES
          // -----------------------------------------------------------------
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF31557F),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              "$changeCount ${changeCount == 1 ? 'change' : 'changes'}",
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFFAEC2DC),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // const Spacer(),
          const SizedBox(width: 20),
          // -----------------------------------------------------------------
          // REASON
          // -----------------------------------------------------------------

          SizedBox(
            width: 268,
            height: 40,
            child: Container(
              padding:
              const EdgeInsets.symmetric(
                horizontal: 10,
              ),
              decoration: BoxDecoration(
                color: Color(0xFFE5EFFF),
                borderRadius:
                BorderRadius.circular(6),
                border: Border.all(
                  color: _showReasonError
                      ? Colors.red
                      : Colors.transparent,
                ),
              ),
              child:
              DropdownButtonHideUnderline(
                child:
                DropdownButton<String>(
                  value: selectedReason,
                  hint: const Text(
                    "Reason for modification",
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(
                        0xFF4B5563,
                      ),
                    ),
                  ),
                  isExpanded: true,
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    size: 18,
                    color: Color(
                      0xFF27364D,
                    ),
                  ),
                  items: voidReasons
                      .map(
                        (reason) =>
                        DropdownMenuItem<
                            String>(
                          value: reason,
                          child: Text(
                            reason,
                            style:
                            const TextStyle(
                              fontSize: 11,
                            ),
                          ),
                        ),
                  )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedReason =
                          value;
                      _showReasonError =
                      false;
                    });

                    widget.onRemark(
                      value ?? "",
                    );
                  },
                ),
              ),
            ),
          ),
          const Spacer(),
          // const SizedBox(width: 8),

          // -----------------------------------------------------------------
          // RESET
          // -----------------------------------------------------------------

          SizedBox(
            width: 75,
            height: 36,
            child: OutlinedButton(
              onPressed:
              _hasQuantityChanged
                  ? _resetChanges
                  : null,
              style:
              OutlinedButton.styleFrom(
                foregroundColor:
                Colors.white,
                disabledForegroundColor:
                Colors.white54,
                side:
                const BorderSide(
                  color: Color(
                    0xFF7892B6,
                  ),
                ),
                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(
                    6,
                  ),
                ),
                padding: EdgeInsets.zero,
              ),
              child: const Text(
                "Reset",
                style: TextStyle(
                  fontSize: 11,
                ),
              ),
            ),
          ),

          const SizedBox(width: 6),

          // -----------------------------------------------------------------
          // SAVE KOT
          // -----------------------------------------------------------------
          SizedBox(
            width: 110,
            height: 36,
            child: ElevatedButton(
              onPressed: canSave ? _saveKot : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: canSave
                    ? const Color(0xFF3978D3)
                    : Colors.grey.shade400,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade400,
                disabledForegroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: EdgeInsets.zero,
              ),
              child: const Text(
                "Save KOT",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SAVE KOT
  // ===========================================================================

  void _saveKot() {
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

    final selectedItems =
        itemsNotifier.value;

    _modifiedItems = [];

    // -------------------------------------------------------------------------
    // BUILD MODIFIED ITEMS
    // -------------------------------------------------------------------------

    for (final originalItem
    in originalKotItems) {
      final modifiedItem =
      _findCurrentItem(
        originalItem.id,
      );

      final modifiedQuantity =
          modifiedItem?.quantity ?? 0;

      final modifiedAmount =
          modifiedItem?.amount ?? 0;

      if (originalItem.originalQuantity !=
          modifiedQuantity) {
        _modifiedItems.add({
          "itemId": originalItem.id,
          "productId":
          originalItem.productId,
          "itemName":
          originalItem.productName,
          "originalQuantity":
          originalItem.originalQuantity,
          "modifiedQuantity":
          modifiedQuantity,
          "voidQuantity":
          originalItem.originalQuantity -
              modifiedQuantity,
          "amount":
          modifiedAmount,
        });
      }
    }

    // -------------------------------------------------------------------------
    // AUDIT DATA
    // -------------------------------------------------------------------------

    final auditData = {
      "pinNumber":
      widget.storedPinNumber,
      "role": widget.role,
      "modifiedAt":
      modifiedAt.toIso8601String(),
      "tableNo": widget.tableNo,
      "kotNo": widget.kotNo,
      "kotId": widget.kotId,
      "reason": selectedReason,
      "items": _modifiedItems,
    };

    debugPrint(
      "========== VOID ITEM AUDIT ==========",
    );
    debugPrint(
      "PIN: ${widget.storedPinNumber}",
    );
    debugPrint(
      "Role: ${widget.role}",
    );
    debugPrint(
      "Time: $modifiedAt",
    );
    debugPrint(
      "Table: ${widget.tableNo}",
    );
    debugPrint(
      "KOT: ${widget.kotNo}",
    );
    debugPrint(
      "Reason: $selectedReason",
    );
    debugPrint(
      "Modified Items: $_modifiedItems",
    );
    debugPrint(
      "Audit Data: $auditData",
    );
    debugPrint(
      "=====================================",
    );

    // -------------------------------------------------------------------------
    // UPDATE REQUEST
    // -------------------------------------------------------------------------

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

    debugPrint(
      "========== UPDATE KOT REQUEST ==========",
    );

    debugPrint(
      "KOT ID: ${widget.kotId}",
    );

    debugPrint(
      "Line Items: ${request.lineItems}",
    );

    debugPrint(
      "Reason: $selectedReason",
    );

    debugPrint(
      "========================================",
    );

    context.read<UpdatekotBloc>().add(
      UpdatekotPressed(
        token: widget.token,
        kotId: widget.kotId,
        request: request,
      ),
    );
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    return BlocListener<
        UpdatekotBloc,
        UpdatekotState>(
      listener: (context, state) async {
        // ---------------------------------------------------------------------
        // SUCCESS
        // ---------------------------------------------------------------------

        if (state is UpdatekotSuccess) {
          debugPrint(
            '========== KOT UPDATE SUCCESS ==========',
          );

          // ---------------------------------------------------------------
          // SEND MQTT FOR EACH MODIFIED ITEM
          // ---------------------------------------------------------------

          for (final item
          in _modifiedItems) {
            await KdsMqttPublisher
                .notifyKotItemQuantityUpdated(
              restaurantId:
              widget.restaurantId
                  .toString(),
              kotId: widget.kotId,
              kotNumber: widget.kotNo,
              itemId: item["itemId"],
              quantity:
              item["modifiedQuantity"],
              parentOrderId:
              widget.parentOrderId,
            );
          }

          debugPrint(
            "✅ QUANTITY MQTT SENT",
          );

          if (!context.mounted) {
            return;
          }

          // ---------------------------------------------------------------
          // REFRESH KOT
          // ---------------------------------------------------------------

          context.read<KotBloc>().add(
            FetchKots(
              parentOrderId:
              widget.parentOrderId,
              restaurantId:
              widget.restaurantId,
              zoneId: widget.zoneId,
              token: widget.token,
            ),
          );

          // ---------------------------------------------------------------
          // CLOSE DIALOG
          // ---------------------------------------------------------------

          Navigator.pop(
            context,
            true,
          );
        }

        // ---------------------------------------------------------------------
        // FAILURE
        // ---------------------------------------------------------------------

        if (state is UpdatekotFailure) {
          if (!context.mounted) {
            return;
          }

          ScaffoldMessenger.of(
            context,
          ).showSnackBar(
            SnackBar(
              content: Text(
                state.message ??
                    "Update failed",
              ),
              duration:
              const Duration(
                seconds: 1,
              ),
              backgroundColor:
              Colors.red,
            ),
          );
        }
      },

      // =========================================================================
      // DIALOG
      // =========================================================================

      child: Dialog(
        shape:
        RoundedRectangleBorder(
          borderRadius:
          BorderRadius.circular(12),
        ),
        insetPadding:
        const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 10,
        ),
        backgroundColor: isDark
            ? const Color(0xFF202433)
            : Colors.white,
        child: SizedBox(
          width:
          MediaQuery.of(context)
              .size
              .width *
              0.90,
          height:
          MediaQuery.of(context)
              .size
              .height *
              0.88,
          child: Column(
            children: [
              // -------------------------------------------------------------
              // HEADER
              // -------------------------------------------------------------

              _dialogHeader(
                context,
              ),

              // -------------------------------------------------------------
              // CONTENT
              // -------------------------------------------------------------

              Expanded(
                child: Padding(
                  padding:
                  const EdgeInsets
                      .fromLTRB(
                    20,
                    20,
                    20,
                    20,
                  ),
                  child: Row(
                    crossAxisAlignment:
                    CrossAxisAlignment
                        .stretch,
                    children: [
                      _leftPanel(),

                      const SizedBox(
                        width: 12,
                      ),

                      _rightPanel(),
                    ],
                  ),
                ),
              ),

              // -------------------------------------------------------------
              // FOOTER
              // -------------------------------------------------------------

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                ),
                child: _bottomFooter(),
              ),

              // -------------------------------------------------------------
              // SPACE BELOW FOOTER
              // -------------------------------------------------------------
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}