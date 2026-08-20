import 'dart:convert';

import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/material.dart';
import '../../constants/constants.dart';
import '../../models/UserPermissions.dart';
import '../../models/order/order_model.dart';
import '../../models/order_list/edit_order_list_model.dart';
import '../../models/order_list/order_list_model.dart';
import '../../repositories/cancel_order_list_repository.dart';
import '../../repositories/order_list_repository.dart';
import '../../utils/SessionManager.dart';
import '../../printer/printer_service.dart';
import 'package:pinaka_restaurant_pos/App%20flow/widgets/print_receipt.dart';
import 'package:pinaka_restaurant_pos/models/payment/payment_summary_model.dart'
    as psm;
import '../widgets/navigationhelper.dart';
import '../widgets/pin_confirmation_popup.dart';
import '../widgets/top_bar.dart';
import '../widgets/bottom_nav_bar.dart';
import 'CheckinPopup.dart';
import 'edit_order_screen.dart';
// import 'edit_kots_screen.dart';
// import 'edit_order_list.dart';

class _OrdersCache {
  static List<OrderlistModel>? cachedOrders;
  static DateTime? cachedAt;
  static String? cachedToken;
  static const validFor = Duration(seconds: 30); // tune as needed

  static bool isValid(String token) {
    return cachedOrders != null &&
        cachedToken == token &&
        cachedAt != null &&
        DateTime.now().difference(cachedAt!) < validFor;
  }

  static void invalidate() {
    cachedOrders = null;
    cachedAt = null;
  }
}

class OrdersDetailsScreen extends StatefulWidget {
  final String token;
  final String pin;
  final String restaurantId;
  final String restaurantName;
  final int orderId; //  Pass selected order ID
  final OrderlistModel? initialOrder; // Pass clicked order for instant load
  final UserPermissions? userPermissions;
  final Function(UserPermissions)? onPermissionsReceived;

  const OrdersDetailsScreen({
    super.key,
    required this.token,
    required this.pin,
    required this.restaurantId,
    required this.restaurantName,
    required this.orderId,
    this.initialOrder,
    this.userPermissions,
    this.onPermissionsReceived,
    Map<String, dynamic>? selectedUser,
  });

  @override
  State<OrdersDetailsScreen> createState() => _OrdersDetailsScreenState();
}

class _OrdersDetailsScreenState extends State<OrdersDetailsScreen> {
  UserPermissions? _userPermissions;
  int _selectedIndex = 4;
  final OrderstatusRepository _orderRepo = OrderstatusRepository();
  Future<List<OrderlistModel>>? _ordersFuture;
  int? selectedKotId;
  bool _justUpdated = false;
  UserPermissions? _permissions;
  double? _oldNetPayable;
  String? _oldEditReason;
  VoidedItemsResponse? voidedItemsResponse;
  bool isVoidedLoading = false;
  int? selectedKotOrderId;
  String _currency = "₹";
  final Map<int, VoidedItemsResponse> _voidedItemsCache = {}; // add as field

  void _onKotSelected(int kotId) {
    setState(() {
      selectedKotId = kotId;
      isVoidedLoading = true;
      voidedItemsResponse = null;
    });

    loadVoidedItems(kotId);
  }
  KotRevision _buildOriginalRevision(KotOrder kot) {
    final originalItems = List<LineItem>.from(
      kot.initialKotItems ?? kot.lineItems ?? [],
    );

    final items = originalItems.map((item) {
      final originalQty =
          item.originalQuantity ??
              item.quantity ??
              0;

      final price = item.itemPrice ?? 0;

      return LineItem(
        lineItemId: item.lineItemId,
        itemId: item.itemId,
        name: item.name,

        // IMPORTANT:
        // Original quantity must be used here.
        quantity: originalQty,

        originalQuantity: originalQty,

        itemPrice: price,

        amount: price * originalQty,

        totalWoTax: price * originalQty,

        total: price * originalQty,

        voidedQuantity: 0,
        voidedAmount: 0,

        modifierAmount: item.modifierAmount,
        modifiers: item.modifiers,
        tax: item.tax,
        kotRemarks: item.kotRemarks,
      );
    }).toList();

    final total = items.fold<num>(
      0,
          (sum, item) => sum + (item.totalWoTax ?? 0),
    );

    return KotRevision(
      revisionNumber: 0,
      items: items,
      total: total,
      reason: "Original order",
      modifiedBy: kot.placedByName,
      modifiedOn: null,
    );
  }
  KotOrder? _getSelectedKot() {
    if (selectedKotId == null) return null;

    final orders = _OrdersCache.cachedOrders ?? [];

    for (final order in orders) {
      final kots = order.kotOrders ?? [];

      for (final kot in kots) {
        if (kot.kotOrderId == selectedKotId) {
          return kot;
        }
      }
    }

    return null;
  }

  String _formatCurrency(num value) {
    return "$_currency${value.toStringAsFixed(2)}";
  }

  List<Map<String, dynamic>> _getRemovedItems({
    required KotRevision revision,
    required KotRevision? previousRevision,
  }) {
    final result = <Map<String, dynamic>>[];

    if (previousRevision == null) {
      debugPrint("❌ _getRemovedItems: previousRevision is NULL");
      return result;
    }

    debugPrint("========== GET REMOVED ITEMS ==========");
    debugPrint(
      "Previous revision items: ${previousRevision.items.length}",
    );
    debugPrint(
      "Current revision items: ${revision.items.length}",
    );

    for (final currentItem in revision.items) {
      debugPrint(
        "🔵 CURRENT: "
            "itemId=${currentItem.itemId}, "
            "lineItemId=${currentItem.lineItemId}, "
            "name=${currentItem.name}, "
            "qty=${currentItem.quantity}",
      );

      // Find matching previous item.
      final previousItem = previousRevision.items.firstWhere(
            (item) {
          // FIRST compare lineItemId
          if (item.lineItemId != null &&
              currentItem.lineItemId != null) {
            final match =
                item.lineItemId.toString() ==
                    currentItem.lineItemId.toString();

            if (match) {
              debugPrint(
                "✅ MATCH BY lineItemId: "
                    "${item.lineItemId}",
              );
            }

            return match;
          }

          // FALLBACK compare itemId
          if (item.itemId != null &&
              currentItem.itemId != null) {
            final match =
                item.itemId.toString() ==
                    currentItem.itemId.toString();

            if (match) {
              debugPrint(
                "✅ MATCH BY itemId: "
                    "${item.itemId}",
              );
            }

            return match;
          }

          return false;
        },
        orElse: () => LineItem(),
      );

      if (previousItem.itemId == null &&
          previousItem.lineItemId == null) {
        debugPrint(
          "❌ NO MATCH for current item: ${currentItem.name}",
        );
        continue;
      }

      final oldQty = previousItem.quantity ?? 0;
      final newQty = currentItem.quantity ?? 0;

      debugPrint(
        "📦 ${currentItem.name}: "
            "oldQty=$oldQty, newQty=$newQty",
      );

      if (newQty < oldQty) {
        final removedQty = oldQty - newQty;

        final price =
            currentItem.itemPrice ??
                previousItem.itemPrice ??
                0;

        final removedAmount = removedQty * price;

        debugPrint(
          "🔴 REMOVED: "
              "${removedQty} × ${currentItem.name} "
              "= $removedAmount",
        );

        result.add({
          "name": currentItem.name ??
              previousItem.name ??
              "-",
          "removedQty": removedQty,
          "amount": removedAmount,
        });
      }
    }

    debugPrint(
      "========== REMOVED RESULT ==========",
    );
    debugPrint(result.toString());

    return result;
  }
  @override
  void initState() {
    super.initState();
    _userPermissions = widget.userPermissions;
    _ordersFuture = _getOrdersFuture(); // <-- changed
    _loadPermissions();
    _loadCurrency();
  }

  Future<List<OrderlistModel>> _getOrdersFuture() async {
    if (widget.initialOrder != null) {
      return [widget.initialOrder!];
    }
    final cached = _orderRepo.findCachedOrder(widget.orderId);
    if (cached != null) {
      return [cached];
    }
    if (_OrdersCache.isValid(widget.token)) {
      return _OrdersCache.cachedOrders!;
    }
    final orders = await _orderRepo.fetchOrders(
      widget.token,
      restaurantId: widget.restaurantId,
    );
    _OrdersCache.cachedOrders = orders;
    _OrdersCache.cachedAt = DateTime.now();
    _OrdersCache.cachedToken = widget.token;
    return orders;
  }

  List<KotRevision> buildKotRevisions(KotOrder kot) {
    debugPrint("========== BUILD KOT REVISIONS ==========");
    debugPrint("KOT ID: ${kot.kotOrderId}");

    debugPrint("placedByName: ${kot.placedByName}");
    debugPrint("placedByFirstName: ${kot.placedByFirstName}");
    debugPrint("placedByLastName: ${kot.placedByLastName}");

    debugPrint("initialKotItems count: ${kot.initialKotItems?.length ?? 0}");

    debugPrint("lineItems count: ${kot.lineItems?.length ?? 0}");

    debugPrint("voidedItems count: ${kot.voidedItems?.length ?? 0}");

    final revisions = <KotRevision>[];
    print("========== BUILD KOT REVISIONS ==========");
    print("KOT ID: ${kot.kotOrderId}");

    print("placedByName: ${kot.placedByName}");
    print("placedByFirstName: ${kot.placedByFirstName}");
    print("placedByLastName: ${kot.placedByLastName}");

    print("initialKotItems count: ${kot.initialKotItems?.length ?? 0}");
    print("lineItems count: ${kot.lineItems?.length ?? 0}");
    print("voidedItems count: ${kot.voidedItems?.length ?? 0}");

    print("========== VOIDED ITEMS ==========");
    for (final v in kot.voidedItems ?? []) {
      print("""
itemId: ${v.itemId}
newQty: ${v.newQty}
remarks: ${v.remarks}
voidedAt: ${v.voidedAt}
""");
    }

    print("========== BASE ITEMS ==========");
    for (final item in kot.initialKotItems ?? kot.lineItems ?? []) {
      print("""
id: ${item.itemId}
lineItemId: ${item.lineItemId}
name: ${item.name}
quantity: ${item.quantity}
originalQuantity: ${item.originalQuantity}
price: ${item.itemPrice}
amount: ${item.amount}
""");
    }
    // ==========================================================
    // BASE / ORIGINAL ITEMS
    // ==========================================================

    final originalItems = List<LineItem>.from(
      kot.initialKotItems ?? kot.lineItems ?? [],
    );

    // ==========================================================
    // VOIDED / MODIFICATION HISTORY
    // ==========================================================

    final voidedItems = List<VoidedItem>.from(kot.voidedItems ?? []);

    if (voidedItems.isEmpty) {
      return revisions;
    }

    // ==========================================================
    // GROUP BY MODIFICATION TIME
    // ==========================================================

    final grouped = <String, List<VoidedItem>>{};

    for (final voided in voidedItems) {
      final key = voided.voidedAt?.toIso8601String() ?? '';

      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(voided);
    }

    // ==========================================================
    // SORT CHRONOLOGICALLY
    // ==========================================================

    final sortedKeys =
    grouped.keys.toList()..sort((a, b) {
      final dateA = DateTime.tryParse(a);
      final dateB = DateTime.tryParse(b);

      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return -1;
      if (dateB == null) return 1;

      return dateA.compareTo(dateB);
    });

    // ==========================================================
    // START FROM ORIGINAL ITEMS
    // ==========================================================

    var currentItems =
    originalItems
        .map(
          (item) => LineItem(
        lineItemId: item.lineItemId,
        itemId: item.itemId,
        name: item.name,

        // IMPORTANT:
        // Use originalQuantity as the starting quantity.
        quantity:
        item.originalQuantity ??
            item.quantity ??
            0,

        originalQuantity:
        item.originalQuantity ??
            item.quantity ??
            0,

        voidedQuantity: item.voidedQuantity,
        voidedAmount: item.voidedAmount,
        itemPrice: item.itemPrice,

        amount:
        (item.itemPrice ?? 0) *
            (item.originalQuantity ??
                item.quantity ??
                0),

        totalWoTax:
        (item.itemPrice ?? 0) *
            (item.originalQuantity ??
                item.quantity ??
                0),

        total:
        (item.itemPrice ?? 0) *
            (item.originalQuantity ??
                item.quantity ??
                0),

        modifierAmount: item.modifierAmount,
        modifiers: item.modifiers,
        tax: item.tax,
        kotRemarks: item.kotRemarks,
      ),
    )
        .toList();
    // ==========================================================
    // REVISION 1 = FIRST MODIFICATION
    // ==========================================================

    int revisionNumber = 1;

    for (final key in sortedKeys) {
      final modifications = grouped[key]!;

      // Clone previous revision
      final revisionItems =
      currentItems
          .map(
            (item) => LineItem(
          lineItemId: item.lineItemId,
          itemId: item.itemId,
          name: item.name,
          quantity: item.quantity,
          originalQuantity: item.originalQuantity,
          voidedQuantity: item.voidedQuantity,
          voidedAmount: item.voidedAmount,
          itemPrice: item.itemPrice,
          amount: item.amount,
          totalWoTax: item.totalWoTax,
          total: item.total,
          modifierAmount: item.modifierAmount,
          modifiers: item.modifiers,
          tax: item.tax,
          kotRemarks: item.kotRemarks,
        ),
      )
          .toList();

      // ========================================================
      // APPLY MODIFICATIONS
      // ========================================================

      for (final modification in modifications) {
        final modificationId = modification.itemId?.toString();

        debugPrint(
          "🔎 Finding modification ID: $modificationId",
        );

        final index = revisionItems.indexWhere((item) {
          final itemId = item.itemId?.toString();
          final lineItemId = item.lineItemId?.toString();

          final match =
              lineItemId == modificationId ||
                  itemId == modificationId;

          debugPrint(
            "   ${item.name}: "
                "itemId=$itemId, "
                "lineItemId=$lineItemId, "
                "match=$match",
          );

          return match;
        });
        if (index == -1) continue;

        final oldItem = revisionItems[index];

        final newQty = modification.newQty ?? 0;
        final itemPrice = oldItem.itemPrice ?? 0;

        revisionItems[index] = LineItem(
          lineItemId: oldItem.lineItemId,
          itemId: oldItem.itemId,
          name: oldItem.name,

          quantity: newQty,

          originalQuantity: oldItem.originalQuantity ?? oldItem.quantity,

          voidedQuantity:
          (oldItem.originalQuantity ?? oldItem.quantity ?? 0) - newQty,

          itemPrice: itemPrice,

          amount: itemPrice * newQty,

          totalWoTax: itemPrice * newQty,

          total: itemPrice * newQty,

          modifierAmount: oldItem.modifierAmount,

          modifiers: oldItem.modifiers,

          tax: oldItem.tax,

          kotRemarks: modification.remarks,
        );
      }

      // ========================================================
      // CALCULATE REVISION TOTAL
      // ========================================================

      final revisionTotal = revisionItems.fold<num>(0, (sum, item) {
        return sum + (item.totalWoTax ?? 0);
      });

      // ========================================================
      // ADD REVISION
      // ========================================================

      revisions.add(
        KotRevision(
          revisionNumber: revisionNumber,
          items: revisionItems,
          total: revisionTotal,

          reason: modifications
              .map((e) => e.remarks)
              .whereType<String>()
              .where((e) => e.trim().isNotEmpty)
              .join(', '),

          modifiedBy:
          kot.placedByName?.trim().isNotEmpty == true
              ? kot.placedByName!.trim()
              : [kot.placedByFirstName, kot.placedByLastName]
              .whereType<String>()
              .where((e) => e.trim().isNotEmpty)
              .join(' '),

          modifiedOn: modifications.first.voidedAt?.toString(),
        ),
      );

      // This revision becomes the base for the next one
      currentItems = revisionItems;

      revisionNumber++;
    }

    return revisions;
  }

  Future<void> _loadCurrency() async {
    final currency = await SessionManager.getCurrencySymbol();

    if (mounted) {
      setState(() {
        _currency = currency ?? "₹";
      });
    }
  }

  void _onItemTapped(int index) {
    // NavigationHelper.handleNavigation(
    //   context,
    //   _selectedIndex,
    //   index,
    //   widget.pin,
    //   widget.token,
    //   widget.restaurantId,
    //   widget.restaurantName,
    //   widget.userPermissions,
    // );

    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _loadPermissions() async {
    final savedPermissions = await SessionManager.loadPermissions();
    if (savedPermissions != null) {
      setState(() {
        _userPermissions = savedPermissions;
      });
    }
  }

  Color _statusColor(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case "completed":
        return Colors.green;
      case "processing":
        return Colors.orange;
      case "cancelled":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _handlePermissions(UserPermissions permissions) {
    setState(() {
      _permissions = permissions; // store locally if needed
      // _userPermissions = permissions;
    });
    widget.onPermissionsReceived?.call(
      permissions,
    ); // optional callback to parent
  }

  Future<void> loadVoidedItems(int kotOrderId) async {
    if (_voidedItemsCache.containsKey(kotOrderId)) {
      setState(() {
        voidedItemsResponse = _voidedItemsCache[kotOrderId];
        isVoidedLoading = false;
      });
      return;
    }

    setState(() => isVoidedLoading = true);
    try {
      final result = await OrderstatusRepository().fetchVoidedItems(
        kotOrderId: kotOrderId,
        token: widget.token,
      );
      _voidedItemsCache[kotOrderId] = result; // <-- cache it
      setState(() {
        voidedItemsResponse = result;
      });
    } catch (e) {
      debugPrint("Voided fetch error: $e");
    } finally {
      setState(() => isVoidedLoading = false);
    }
  }

  void _showModificationHistory(OrderlistModel orderModel) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Modification History',
      barrierColor: Colors.black.withOpacity(0.25),
      transitionDuration: const Duration(milliseconds: 300),

      pageBuilder: (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
          ) {
        return const SizedBox.shrink();
      },

      transitionBuilder: (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
          Widget child,
          ) {
        final slideAnimation = Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        );

        return SlideTransition(
          position: slideAnimation,
          child: Align(
            alignment: Alignment.centerRight,
            child: Material(
              color: Colors.transparent,
              child: SizedBox(
                // IMPORTANT
                width: 420,
                height: MediaQuery.of(context).size.height,
                child: _buildModificationHistoryPanel(orderModel),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModificationHistoryPanel(OrderlistModel orderModel) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final selectedKot = _getSelectedKot();

    if (selectedKot == null) {
      return Material(
        color: isDark ? const Color(0xFF202433) : Colors.white,
        child: const Center(child: Text("No KOT selected")),
      );
    }

    final revisions = buildKotRevisions(selectedKot);
    // Original KOT is the "previous revision" for Revision 1.
    final originalRevision = _buildOriginalRevision(selectedKot);
    return Material(
      color: isDark ? const Color(0xFF202433) : Colors.white,
      elevation: 12,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==========================================
            // HEADER
            // ==========================================
            Container(
              height: 70,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF202433) : Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? Colors.white12 : const Color(0xFFE5E7EB),
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Back button
                  SizedBox(
                    height: 40,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF263653),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7),
                        ),
                        elevation: 0,
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.arrow_back, size: 16, color: Colors.white),
                          SizedBox(width: 5),
                          Text(
                            "Back",
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Title
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Modification History",
                          style: TextStyle(
                            color:
                            isDark ? Colors.white : const Color(0xFF1E293B),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Order #${widget.orderId}",
                          style: TextStyle(
                            color:
                            isDark
                                ? Colors.white54
                                : const Color(0xFF64748B),
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ==========================================
            // HISTORY CONTENT
            // ==========================================
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    for (int i = 0; i < revisions.length; i++) ...[
                      _buildKotRevisionCard(
                        revision: revisions[i],
                        orderModel: orderModel,
                        // IMPORTANT:
                        // Revision 1 compares against ORIGINAL KOT.
                        // Revision 2+ compares against previous modification.
                        previousRevision:
                        i == 0
                            ? originalRevision
                            : revisions[i - 1],

                        current: i == revisions.length - 1,
                      ),

                      if (i < revisions.length - 1)
                        const SizedBox(height: 20),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildKotRevisionCard({
    required KotRevision revision,
    required KotRevision? previousRevision,
    required bool current,
    required OrderlistModel orderModel,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Use the actual order previous total from backend.
    final previousTotal = orderModel.orderPrevTotal ?? 0;

    final updatedTotal = orderModel.netPayable ?? 0;

    // Calculate from the actual previous and updated totals.
    final difference = updatedTotal - previousTotal;

    final modifiedBy =
    revision.modifiedBy?.trim().isNotEmpty == true
        ? revision.modifiedBy!.trim()
        : "-";

    final reason =
    revision.reason?.trim().isNotEmpty == true
        ? revision.reason!.trim()
        : "-";

    final date =
    revision.modifiedOn?.trim().isNotEmpty == true
        ? revision.modifiedOn!
        : "-";

    final removedItems = _getRemovedItems(
      revision: revision,
      previousRevision: previousRevision,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF202433) : Colors.white,
        border: Border.all(
          color: const Color(0xFF2563EB),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // =====================================================
          // REVISION + DATE
          // =====================================================
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    "REVISION ${revision.revisionNumber}",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color:
                      isDark
                          ? Colors.white
                          : const Color(0xFF1E293B),
                    ),
                  ),

                  if (current) ...[
                    const SizedBox(width: 7),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: const Text(
                        "CURRENT",
                        style: TextStyle(
                          fontSize: 7,
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              Text(
                date,
                style: TextStyle(
                  fontSize: 8,
                  color:
                  isDark
                      ? Colors.white54
                      : const Color(0xFF64748B),
                ),
              ),
            ],
          ),

          const SizedBox(height: 9),

          // =====================================================
          // MODIFIED BY / REASON
          // =====================================================
          Row(
            children: [
              Expanded(
                child: _historyInfo(
                  "Modified by",
                  modifiedBy,
                ),
              ),
              Expanded(
                child: _historyInfo(
                  "Reason",
                  reason,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // =====================================================
          // REMOVED / REDUCED ITEMS
          // =====================================================
          Text(
            "REMOVED / REDUCED ITEMS",
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: Colors.red.shade400,
            ),
          ),

          const SizedBox(height: 5),

          if (removedItems.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 7,
                vertical: 6,
              ),
              color:
              isDark
                  ? Colors.white.withOpacity(0.05)
                  : const Color(0xFFF8FAFC),
              child: const Text(
                "No items removed",
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey,
                ),
              ),
            )
          else
            Column(
              children:
              removedItems.map((item) {
                final name =
                    item["name"]?.toString() ?? "-";
                final removedQty =
                    item["removedQty"] ?? 0;
                final amount =
                    (item["amount"] as num?) ?? 0;

                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 3),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 6,
                  ),
                  color:
                  isDark
                      ? Colors.red.withOpacity(0.10)
                      : const Color(0xFFFFF1F2),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          "$removedQty × $name",
                          style: const TextStyle(
                            fontSize: 9,
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      Text(
                        "-${_formatCurrency(amount)}",
                        style: const TextStyle(
                          fontSize: 9,
                          color: Colors.red,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

          const SizedBox(height: 9),

          // =====================================================
          // TOTALS
          // =====================================================
          _historyAmountRow(
            "Previous Total",
            _formatCurrency(previousTotal),
          ),

          const SizedBox(height: 5),

          _historyAmountRow(
            "Updated Total",
            _formatCurrency(updatedTotal),
          ),

          const SizedBox(height: 5),

          _historyAmountRow(
            "Difference",
            _formatCurrency(difference),
            valueColor:
            difference < 0
                ? Colors.red
                : difference > 0
                ? Colors.green
                : Colors.grey,
            bold: true,
          ),
        ],
      ),
    );
  }

  Widget _historyInfo(String title, String value) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 8,
            color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildRevisionOne() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
          ),
          bottom: BorderSide(
            color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "REVISION 1",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              Text(
                "11 Aug 2026 · 10:00 AM",
                style: TextStyle(
                  fontSize: 8,
                  color: isDark ? Colors.white54 : const Color(0xFF64748B),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(child: _historyInfo("Created by", "Cashier")),
              Expanded(child: _historyInfo("Reason", "Original order created")),
            ],
          ),

          const SizedBox(height: 10),

          Divider(
            color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
            height: 1,
          ),

          const SizedBox(height: 8),

          _historyAmountRow("Original Total", "₹1650.00", bold: true),
        ],
      ),
    );
  }

  Widget _historyAmountRow(
      String title,
      String amount, {
        Color? valueColor,
        bool bold = false,
      }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 8,
            color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: 9,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color:
            valueColor ?? (isDark ? Colors.white : const Color(0xFF1E293B)),
          ),
        ),
      ],
    );
  }

  //
  // Future<void> cancelOrder(OrderlistModel orderModel) async {
  //   final orderId = orderModel.orderId!;
  //   final restaurantId = orderModel.restaurantId!;
  //   final zoneId = orderModel.zoneId!;
  //
  //   print("🟥 CANCEL FLOW STARTED");
  //   print("📌 Order ID: $orderId");
  //   print("🏪 Restaurant ID: $restaurantId");
  //   print("📍 Zone ID: $zoneId");
  //
  //   final repo = CancelOrderRepository();
  //
  //   if (orderModel.kotOrders != null && orderModel.kotOrders!.isNotEmpty) {
  //     print("🍽 Total KOTs: ${orderModel.kotOrders!.length}");
  //
  //     for (final kot in orderModel.kotOrders!) {
  //       if (kot.kotOrderId != null) {
  //         print("🔄 Cancelling KOT: ${kot.kotOrderId}");
  //
  //         await repo.cancelKot(
  //           kotOrderId: kot.kotOrderId!,
  //           restaurantId: restaurantId,
  //           zoneId: zoneId,
  //           token: widget.token,
  //         );
  //       }
  //     }
  //   }
  //
  //   print("🎯 All KOTs cancelled → Cancelling Parent Order");
  //
  //   await repo.cancelOrder(
  //     orderId: orderId,
  //     restaurantId: restaurantId,
  //     zoneId: zoneId,
  //     token: widget.token,
  //   );
  //
  //   print("🎉 FULL ORDER CANCELLED SUCCESSFULLY");
  // }

  void _reloadAfterEdit() {
    _refreshOrdersInBackground();

    if (selectedKotId != null) {
      _voidedItemsCache.remove(selectedKotId);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        loadVoidedItems(selectedKotId!);
      });
    }
  }

  Future<void> _refreshOrdersInBackground() async {
    OrderstatusRepository.invalidateCache();
    try {
      final freshOrders = await _orderRepo.fetchOrders(
        widget.token,
        forceRefresh: true,
      );
      if (!mounted) return;
      setState(() {
        _ordersFuture = Future.value(
          freshOrders,
        ); // already resolved — no waiting state
      });
    } catch (e) {
      debugPrint("Background orders refresh failed: $e");
      // Old data stays on screen; nothing to clean up.
    }
  }

  Future<void> _cancelCompletedOrder(OrderlistModel orderModel) async {
    if (orderModel.orderId == null) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          final isDark =
              Theme.of(dialogContext).brightness == Brightness.dark; // ADDED
          return Dialog(
            backgroundColor:
            isDark
                ? const Color(
              0xFF202433,
            ) // ADDED: dark dialog background, no more white flash
                : Colors.white,
            child: const Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          );
        },
      );

      final repo = CancelOrderRepository();

      // =================== Step 1: Cancel child KOTs ===================
      if (orderModel.kotOrders != null && orderModel.kotOrders!.isNotEmpty) {
        for (var kot in orderModel.kotOrders!) {
          if (kot.status != "cancelled") {
            print("📌 Attempting to cancel KOT → ID: ${kot.kotOrderId}");
            print("📌 KOT Status: ${kot.status}");
            print("📌 Endpoint: ${AppConstants.cancelOrder(kot.kotOrderId!)}");
            print(
              "📌 Payload: ${jsonEncode({"flag_type": "update_kot_status", "status": "cancelled", "restaurant_id": orderModel.restaurantId, "zone_id": orderModel.zoneId})}",
            );

            await repo.cancelKot(
              parentOrderId:
              orderModel.orderId!, // endpoint now uses parent order
              kotOrderId: kot.kotOrderId!, // optional for backend reference
              restaurantId: orderModel.restaurantId!,
              zoneId: orderModel.zoneId!,
              token: widget.token,
            );

            print("✅ KOT Cancelled → ID: ${kot.kotOrderId}");
            kot.status = "cancelled"; // update local state
          }
        }
      }

      // =================== Step 2: Cancel parent order ===================
      print("📌 Attempting to cancel parent order → ID: ${orderModel.orderId}");
      print(
        "📌 Parent Endpoint: ${AppConstants.cancelOrder(orderModel.orderId!)}",
      );
      print(
        "📌 Parent Payload: ${jsonEncode({"flag_type": "cancel_parent_order", "restaurant_id": orderModel.restaurantId, "zone_id": orderModel.zoneId})}",
      );

      final response = await repo.cancelOrder(
        orderId: orderModel.orderId!,
        restaurantId: orderModel.restaurantId!,
        zoneId: orderModel.zoneId!,
        token: widget.token,
      );

      Navigator.pop(context); // close loader

      print("✅ Parent Order Cancelled → ID: ${orderModel.orderId}");
      print("📥 Response: ${response.message}");

      OrderstatusRepository.invalidateCache(); // ADDED: force fresh data after cancel

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response.message.isNotEmpty
                ? response.message
                : "✅ Order cancelled successfully",
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );

      // =================== Step 3: Update parent order status ===================
      setState(() {
        orderModel.status = "cancelled";
      });
    } catch (e) {
      Navigator.pop(context); // close loader if error
      print("❌ Failed to cancel order: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Failed to cancel order: $e"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  List<String> extractModifierNames(Map<String, dynamic> item) {
    debugPrint("🟡 FULL ITEM MAP → $item");

    dynamic raw =
        item['modifiers'] ??
            item['modifier'] ??
            item['addons'] ??
            item['item_modifiers'] ??
            item['modifier_details'] ??
            item['modifiers_json'];

    debugPrint("🟠 RAW MODIFIER DATA → $raw");

    if (raw == null) {
      debugPrint("🔴 No modifier field found");
      return [];
    }

    List modifiersList = [];

    try {
      if (raw is String) {
        debugPrint("🔵 RAW TYPE → String");
        modifiersList = List<dynamic>.from(jsonDecode(raw));
      } else if (raw is List) {
        debugPrint("🔵 RAW TYPE → List");
        modifiersList = raw;
      } else if (raw is Map) {
        debugPrint("🔵 RAW TYPE → Map");
        modifiersList = raw.values.toList();
      }
    } catch (e) {
      debugPrint("❌ Modifier parse error: $e");
      modifiersList = [];
    }

    debugPrint("🟢 PARSED MODIFIER LIST → $modifiersList");

    final names =
    modifiersList
        .map<String>((m) {
      if (m is String) return m;
      if (m is Map) {
        return m['name']?.toString() ??
            m['modifier_name']?.toString() ??
            m['title']?.toString() ??
            '';
      }
      return '';
    })
        .where((e) => e.isNotEmpty)
        .toList();

    debugPrint("✅ FINAL MODIFIER NAMES → $names");

    return names;
  }

  @override
  Widget build(BuildContext context) {
    final blockHeight = MediaQuery.of(context).size.height * 0.9;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      // backgroundColor: const Color(0xFFE5EFFF),
      backgroundColor:
      isDark
          ? const Color(0xFF161A26)
          : const Color(0xFFF6F6F6), //0xFFF6F6F6
      appBar: TopBar(
        token: widget.token,
        pin: widget.pin,
        restaurantId: widget.restaurantId,
        restaurantName: widget.restaurantName,

        userPermissions: _userPermissions,
        onPermissionsReceived: (permissions) {
          setState(() {
            _userPermissions = permissions;
          });
        },
      ),

      // BODY
      body: FutureBuilder<List<OrderlistModel>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No Orders Found"));
          }

          //  Pick the correct order by ID
          final orderModel = snapshot.data!.firstWhere(
                (o) => o.orderId == widget.orderId,
            orElse: () => snapshot.data!.first,
          );

          final order = orderModel.toMapForView();
          final kots = (order["kots"] as List<dynamic>?) ?? [];

          // Initialize selected KOT if null
          if (selectedKotId == null && kots.isNotEmpty) {
            selectedKotId = kots.first["kotNo"];

            //  Fetch void items  (before dropdown selection)
            WidgetsBinding.instance.addPostFrameCallback((_) {
              loadVoidedItems(selectedKotId!);
            });
          }

          Map<String, dynamic>? selectedKot = kots
              .cast<Map<String, dynamic>?>()
              .firstWhere(
                (kot) => kot?["kotNo"] == selectedKotId,
            orElse: () => null,
          );

          String kotReason = "-"; // default
          if (selectedKot != null && selectedKot["meta_data"] != null) {
            final metaData = (selectedKot["meta_data"] as List<dynamic>);
            final reasonMeta = metaData.firstWhere(
                  (m) => m["key"] == "kot_reason",
              orElse: () => {"value": "-"},
            );
            kotReason = reasonMeta["value"] ?? "-";
          }
          final String role = (_userPermissions?.role ?? '').toLowerCase();

          final bool canEditOrder =
              (_userPermissions?.canEditOrder ?? false) &&
                  (role == 'administrator' ||
                      role == 'manager' ||
                      role == 'merchant');
          return Center(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(4, 2, 0, 2),
              padding: const EdgeInsets.fromLTRB(4, 2, 4, 2),

              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.20 : 0.12),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Flexible(
                    flex: 1,
                    child: Container(
                      height: blockHeight,
                      margin: const EdgeInsets.all(4),
                      // decoration: BoxDecoration(
                      //   color:
                      //       isDark
                      //           ? const Color(0xFF202433)
                      //           : const Color(0xFFF6F6F6),
                      //   borderRadius: BorderRadius.circular(12),
                      // ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Left: Back button
                                GestureDetector(
                                  onTap: () => Navigator.pop(context, true),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: ShapeDecoration(
                                      color: const Color(0xFF3B4259),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      shadows: const [
                                        BoxShadow(
                                          color: Color(0x19000000),
                                          blurRadius: 4,
                                          offset: Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(
                                          Icons.arrow_back,
                                          size: 20,
                                          color: Colors.white,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          "Back",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 16),

                                Text(
                                  "Order #${orderModel.orderId ?? '-'}",
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: theme.textTheme.bodyLarge?.color,
                                  ),
                                ),

                                const Spacer(),
                                // Right buttons: Edit Order + Cancel Order
                                Row(
                                  children: [
                                    // Edit Order Button
                                    if ((orderModel.status ?? '')
                                        .toLowerCase() ==
                                        'completed')
                                      ElevatedButton(
                                        onPressed:
                                        !canEditOrder
                                            ? null
                                            : () async {
                                          // -----------------------------------------
                                          // 1. MERCHANT DISCOUNT CHECK
                                          // -----------------------------------------
                                          if ((orderModel
                                              .merchantDiscount ??
                                              0) >
                                              0) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Order with Merchant Discount is not editable',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                duration: Duration(
                                                  seconds: 1,
                                                ),
                                                backgroundColor:
                                                Colors.redAccent,
                                              ),
                                            );
                                            return;
                                          }

                                          // -----------------------------------------
                                          // 2. ROLE + PERMISSION CHECK
                                          // -----------------------------------------
                                          final String role =
                                          (_userPermissions?.role ??
                                              '')
                                              .toLowerCase();

                                          if (!((_userPermissions
                                              ?.canEditOrder ??
                                              false) &&
                                              (role ==
                                                  'administrator' ||
                                                  role == 'manager' ||
                                                  role ==
                                                      'merchant'))) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Only administrators, managers, and merchants can edit orders',
                                                ),
                                                duration: Duration(
                                                  seconds: 1,
                                                ),
                                                backgroundColor:
                                                Colors.red,
                                              ),
                                            );
                                            return;
                                          }

                                          // -----------------------------------------
                                          // 3. SHOW PIN CONFIRMATION POPUP
                                          // -----------------------------------------

                                          // -----------------------------------------
                                          // 3. VERIFY TOP-BAR LOGIN PIN
                                          // -----------------------------------------
                                          //
                                          // widget.pin = PIN used for the current
                                          // employee/top-bar login session.
                                          //
                                          final bool pinMatched =
                                          await PinConfirmationPopup.show(
                                            context: context,
                                            expectedPin: widget.pin,
                                          );

                                          if (!pinMatched) {
                                            // User cancelled OR entered the wrong PIN.
                                            return;
                                          }

                                          // -----------------------------------------
                                          // 4. PIN MATCHED → OPEN EDIT ORDER
                                          // -----------------------------------------
                                          final bool?
                                          updated = await Navigator.push<
                                              bool
                                          >(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (
                                                  context,
                                                  ) => EditOrdersListScreen(
                                                token: widget.token,

                                                // Use the verified/current login PIN.
                                                pin: widget.pin,

                                                restaurantId:
                                                widget
                                                    .restaurantId,

                                                restaurantName:
                                                widget
                                                    .restaurantName,

                                                userPermissions:
                                                _permissions,

                                                orderId:
                                                orderModel
                                                    .orderId!,
                                              ),
                                            ),
                                          );

                                          // -----------------------------------------
                                          // 5. RELOAD AFTER EDIT
                                          // -----------------------------------------
                                          if (updated == true &&
                                              mounted) {
                                            _reloadAfterEdit();
                                          }

                                          // await PinConfirmationPopup.show(
                                          //   context: context,
                                          //
                                          //   onProceed: (
                                          //     enteredPin,
                                          //   ) async {
                                          //     debugPrint(
                                          //       'PIN entered in confirmation popup: $enteredPin',
                                          //     );
                                          //
                                          //     // TODO:
                                          //     // Verify enteredPin against your backend/API
                                          //     // before allowing the edit.
                                          //
                                          //     final bool?
                                          //     updated = await Navigator.push<
                                          //       bool
                                          //     >(
                                          //       context,
                                          //       MaterialPageRoute(
                                          //         builder:
                                          //             (
                                          //               context,
                                          //             ) => EditOrdersListScreen(
                                          //               token:
                                          //                   widget
                                          //                       .token,
                                          //               pin: enteredPin,
                                          //               restaurantId:
                                          //                   widget
                                          //                       .restaurantId,
                                          //               restaurantName:
                                          //                   widget
                                          //                       .restaurantName,
                                          //               userPermissions:
                                          //                   _permissions,
                                          //               orderId:
                                          //                   orderModel
                                          //                       .orderId!,
                                          //             ),
                                          //       ),
                                          //     );
                                          //
                                          //     if (updated == true &&
                                          //         mounted) {
                                          //       _reloadAfterEdit();
                                          //     }
                                          //   },
                                          // );
                                        },

                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF4C5F7D,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 8,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Image.asset(
                                              'assets/editorder.png',
                                              width: 18,
                                              height: 18,
                                              color: Colors.white,
                                            ),
                                            const SizedBox(width: 6),
                                            const Text(
                                              "Edit Order",
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                    const SizedBox(width: 12),

                                    // Cancel Order Button
                                    // Cancel Order Button
                                    if ((orderModel.status ?? '')
                                        .toLowerCase() ==
                                        'completed')
                                      ElevatedButton(
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            barrierDismissible: false,
                                            builder:
                                                (context) => Dialog(
                                              backgroundColor:
                                              theme.cardColor,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                BorderRadius.circular(
                                                  16,
                                                ),
                                              ),
                                              child: SizedBox(
                                                width: 400,
                                                child: Padding(
                                                  padding:
                                                  const EdgeInsets.all(
                                                    20,
                                                  ),
                                                  child: Column(
                                                    mainAxisSize:
                                                    MainAxisSize.min,
                                                    children: [
                                                      Image.asset(
                                                        'assets/cancelorder.png',
                                                        height: 90,
                                                      ),
                                                      const SizedBox(
                                                        height: 16,
                                                      ),

                                                      Text(
                                                        'Cancel Order?',
                                                        textAlign:
                                                        TextAlign
                                                            .center,
                                                        style: theme
                                                            .textTheme
                                                            .titleLarge
                                                            ?.copyWith(
                                                          fontSize: 22,
                                                          fontWeight:
                                                          FontWeight
                                                              .w600,
                                                        ),
                                                      ),

                                                      const SizedBox(
                                                        height: 10,
                                                      ),

                                                      Text(
                                                        'Are you sure you want to cancel the order?',
                                                        textAlign:
                                                        TextAlign
                                                            .center,
                                                        style: theme
                                                            .textTheme
                                                            .bodyMedium
                                                            ?.copyWith(
                                                          fontSize: 16,
                                                          color:
                                                          isDark
                                                              ? Colors
                                                              .white70
                                                              : Colors
                                                              .black54,
                                                        ),
                                                      ),

                                                      const SizedBox(
                                                        height: 24,
                                                      ),

                                                      Row(
                                                        mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                        children: [
                                                          SizedBox(
                                                            width: 110,
                                                            child: OutlinedButton(
                                                              onPressed:
                                                                  () => Navigator.pop(
                                                                context,
                                                              ),
                                                              style: OutlinedButton.styleFrom(
                                                                minimumSize:
                                                                const Size(
                                                                  110,
                                                                  40,
                                                                ),
                                                                backgroundColor:
                                                                isDark
                                                                    ? const Color(
                                                                  0xFF2A2F3D,
                                                                )
                                                                    : Colors.white,
                                                                side: BorderSide(
                                                                  color:
                                                                  theme
                                                                      .dividerColor,
                                                                ),
                                                                shape: RoundedRectangleBorder(
                                                                  borderRadius:
                                                                  BorderRadius.circular(
                                                                    8,
                                                                  ),
                                                                ),
                                                              ),
                                                              child: Text(
                                                                'Back',
                                                                style: TextStyle(
                                                                  color:
                                                                  theme
                                                                      .textTheme
                                                                      .bodyLarge
                                                                      ?.color,
                                                                ),
                                                              ),
                                                            ),
                                                          ),

                                                          const SizedBox(
                                                            width: 14,
                                                          ),

                                                          SizedBox(
                                                            width: 130,
                                                            child: ElevatedButton(
                                                              onPressed: () {
                                                                Navigator.pop(
                                                                  context,
                                                                );
                                                                _cancelCompletedOrder(
                                                                  orderModel,
                                                                );
                                                              },
                                                              style: ElevatedButton.styleFrom(
                                                                backgroundColor:
                                                                const Color(
                                                                  0xFFFE6464,
                                                                ),
                                                                minimumSize:
                                                                const Size(
                                                                  130,
                                                                  40,
                                                                ),
                                                                shape: RoundedRectangleBorder(
                                                                  borderRadius:
                                                                  BorderRadius.circular(
                                                                    8,
                                                                  ),
                                                                ),
                                                              ),
                                                              child: const Text(
                                                                'Yes, Done',
                                                                style: TextStyle(
                                                                  color:
                                                                  Colors
                                                                      .white,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        },

                                        // 🎨 Button UI
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                          Theme.of(context).cardColor,
                                          elevation: 2,
                                          shadowColor: const Color(0x554C5F7D),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 9,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            side: const BorderSide(
                                              width: 0.9,
                                              color: Color(0xFFFE6464),
                                            ),
                                          ),
                                        ),

                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.close,
                                              size: 20,
                                              color: Color(0xFFFE6464),
                                            ),
                                            SizedBox(width: 6),
                                            Text(
                                              'Cancel Order',
                                              style: TextStyle(
                                                color: Color(0xFFFE6464),
                                                fontSize: 14,
                                                fontWeight: FontWeight.w400,
                                                height: 0.75,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    const SizedBox(width: 12),

                                    // Modification History Button
                                    SizedBox(
                                      width: 100,
                                      height: 45,
                                      child: OutlinedButton(
                                        onPressed: () {
                                          _showModificationHistory(orderModel);
                                        },
                                        style: OutlinedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFFF8FAFC,
                                          ),
                                          side: const BorderSide(
                                            width: 0.8,
                                            color: Color(0xFF8F9193),
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 10,
                                          ),
                                        ),
                                        child: const Text(
                                          '🕐  Mod. History',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Color(0xFF475569),
                                            fontSize: 11,
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w600,
                                            height: 1.22,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                children: [
                                  //order details
                                  // Row(
                                  //   children: [
                                  //     Expanded(
                                  //       child: Container(
                                  //         height: 130,
                                  //         padding: const EdgeInsets.all(12),
                                  //         decoration: BoxDecoration(
                                  //           color: theme.cardColor,
                                  //           borderRadius: BorderRadius.circular(
                                  //             10,
                                  //           ),
                                  //         ),
                                  //         child: Column(
                                  //           crossAxisAlignment:
                                  //               CrossAxisAlignment.start,
                                  //           children: [
                                  //             Row(
                                  //               mainAxisAlignment:
                                  //                   MainAxisAlignment
                                  //                       .spaceBetween,
                                  //               children: [
                                  //                 Text(
                                  //                   "Order Details",
                                  //                   style: TextStyle(
                                  //                     fontWeight:
                                  //                         FontWeight.bold,
                                  //                   ),
                                  //                 ),
                                  //
                                  //                 // Text(
                                  //                 //   "#${orderModel.orderId ?? '-'}",
                                  //                 //   style: const TextStyle(
                                  //                 //     fontWeight:
                                  //                 //     FontWeight.bold,
                                  //                 //     fontSize: 16,
                                  //                 //   ),
                                  //                 // ),
                                  //                 Text(
                                  //                   orderModel.date ?? "-",
                                  //                   style: theme
                                  //                       .textTheme
                                  //                       .bodySmall
                                  //                       ?.copyWith(
                                  //                         fontWeight:
                                  //                             FontWeight.w700,
                                  //                         fontSize: 13,
                                  //                         color:
                                  //                             isDark
                                  //                                 ? Colors
                                  //                                     .white70
                                  //                                 : const Color(
                                  //                                   0xFF555555,
                                  //                                 ),
                                  //                       ),
                                  //                 ),
                                  //               ],
                                  //             ),
                                  //             const SizedBox(height: 6),
                                  //             // const Text(
                                  //             //   "Order Details",
                                  //             //   style: TextStyle(
                                  //             //     fontWeight: FontWeight.bold,
                                  //             //   ),
                                  //             // ),
                                  //             RichText(
                                  //               text: TextSpan(
                                  //                 children: [
                                  //                   TextSpan(
                                  //                     text: "Order ID : ",
                                  //                     style: Theme.of(
                                  //                       context,
                                  //                     ).textTheme.bodyMedium?.copyWith(
                                  //                       fontWeight:
                                  //                           FontWeight.w400,
                                  //                       fontSize: 14,
                                  //                       color:
                                  //                           Theme.of(
                                  //                                     context,
                                  //                                   ).brightness ==
                                  //                                   Brightness
                                  //                                       .dark
                                  //                               ? Colors.white70
                                  //                               : Colors.grey,
                                  //                     ),
                                  //                   ),
                                  //                   TextSpan(
                                  //                     text:
                                  //                         "${orderModel.orderId ?? '-'}",
                                  //                     style: Theme.of(
                                  //                       context,
                                  //                     ).textTheme.bodyMedium?.copyWith(
                                  //                       fontWeight:
                                  //                           FontWeight.bold,
                                  //                       fontSize: 14,
                                  //                       color:
                                  //                           Theme.of(
                                  //                                     context,
                                  //                                   ).brightness ==
                                  //                                   Brightness
                                  //                                       .dark
                                  //                               ? Colors.white
                                  //                               : const Color(
                                  //                                 0xFF4C5F7D,
                                  //                               ),
                                  //                     ),
                                  //                   ),
                                  //                 ],
                                  //               ),
                                  //             ),
                                  //             const SizedBox(height: 6),
                                  //
                                  //             // Order Details (Order Type + Table)
                                  //             RichText(
                                  //               text: TextSpan(
                                  //                 style: const TextStyle(
                                  //                   fontSize: 14,
                                  //                   color:
                                  //                       Colors
                                  //                           .grey, // default for label
                                  //                 ),
                                  //                 children: [
                                  //                   const TextSpan(
                                  //                     text: "Order Type : ",
                                  //                   ),
                                  //                   TextSpan(
                                  //                     text:
                                  //                         "${orderModel.orderType ?? '-'}"
                                  //                         "${(orderModel.tableName != null && orderModel.tableName!.trim().isNotEmpty) ? ', ${orderModel.tableName}' : ''}",
                                  //                     style: Theme.of(
                                  //                       context,
                                  //                     ).textTheme.bodyMedium?.copyWith(
                                  //                       fontWeight:
                                  //                           FontWeight.w400,
                                  //                       color:
                                  //                           Theme.of(
                                  //                                     context,
                                  //                                   ).brightness ==
                                  //                                   Brightness
                                  //                                       .dark
                                  //                               ? Colors.white
                                  //                               : Colors.black,
                                  //                     ),
                                  //                   ),
                                  //                 ],
                                  //               ),
                                  //             ),
                                  //
                                  //             const SizedBox(height: 6),
                                  //
                                  //             // Additional Info: first KOT items names (like your screenshot)
                                  //             // if (orderModel.kotOrders != null && orderModel.kotOrders!.isNotEmpty)
                                  //             //   Text(
                                  //             //     "Additional Info: ${orderModel.kotOrders!.first.lineItems!.map((e) => e.name).join(', ')}",
                                  //             //     style: const TextStyle(color: Colors.grey),
                                  //             //     overflow: TextOverflow.ellipsis,
                                  //             //   ),
                                  //             // const SizedBox(height: 8),
                                  //
                                  //             // Payment Type
                                  //             RichText(
                                  //               text: TextSpan(
                                  //                 style: const TextStyle(
                                  //                   fontSize: 14,
                                  //                   color:
                                  //                       Colors
                                  //                           .grey, // label color
                                  //                 ),
                                  //                 children: [
                                  //                   const TextSpan(
                                  //                     text: "Payment Type : ",
                                  //                   ),
                                  //                   TextSpan(
                                  //                     text:
                                  //                         orderModel
                                  //                             .paymentType ??
                                  //                         '-',
                                  //                     style: Theme.of(
                                  //                       context,
                                  //                     ).textTheme.bodyMedium?.copyWith(
                                  //                       fontWeight:
                                  //                           FontWeight.w400,
                                  //                       color:
                                  //                           Theme.of(
                                  //                                     context,
                                  //                                   ).brightness ==
                                  //                                   Brightness
                                  //                                       .dark
                                  //                               ? Colors.white
                                  //                               : Colors.black,
                                  //                     ),
                                  //                   ),
                                  //                 ],
                                  //               ),
                                  //             ),
                                  //           ],
                                  //         ),
                                  //       ),
                                  //     ),
                                  //
                                  //     const SizedBox(width: 12),
                                  //
                                  //     // customer details
                                  //     Expanded(
                                  //       child: Container(
                                  //         height: 130,
                                  //         padding: const EdgeInsets.all(12),
                                  //         decoration: BoxDecoration(
                                  //           color: theme.cardColor,
                                  //           borderRadius: BorderRadius.circular(
                                  //             10,
                                  //           ),
                                  //         ),
                                  //         child: Column(
                                  //           crossAxisAlignment:
                                  //               CrossAxisAlignment.start,
                                  //           children: [
                                  //             Row(
                                  //               crossAxisAlignment:
                                  //                   CrossAxisAlignment.start,
                                  //               children: [
                                  //                 // LEFT → Customer Details
                                  //                 const Text(
                                  //                   "Customer Details",
                                  //                   style: TextStyle(
                                  //                     fontWeight:
                                  //                         FontWeight.bold,
                                  //                   ),
                                  //                 ),
                                  //
                                  //                 const Spacer(),
                                  //
                                  //                 // RIGHT → Status badge
                                  //                 Container(
                                  //                   padding:
                                  //                       const EdgeInsets.symmetric(
                                  //                         horizontal: 8,
                                  //                         vertical: 4,
                                  //                       ),
                                  //                   decoration: BoxDecoration(
                                  //                     color: _statusColor(
                                  //                       orderModel.status,
                                  //                     ),
                                  //                     borderRadius:
                                  //                         BorderRadius.circular(
                                  //                           5,
                                  //                         ),
                                  //                   ),
                                  //                   child: Text(
                                  //                     orderModel.status ?? '-',
                                  //                     style: const TextStyle(
                                  //                       color: Colors.white,
                                  //                       fontWeight:
                                  //                           FontWeight.bold,
                                  //                       fontSize: 12,
                                  //                     ),
                                  //                   ),
                                  //                 ),
                                  //               ],
                                  //             ),
                                  //
                                  //             // const SizedBox(height: 8),
                                  //             const SizedBox(height: 4),
                                  //
                                  //             // Customer Name
                                  //             Row(
                                  //               // mainAxisAlignment:
                                  //               // MainAxisAlignment
                                  //               //     .spaceBetween,
                                  //               children: [
                                  //                 const Text(
                                  //                   "Customer Name :",
                                  //                   style: TextStyle(
                                  //                     color: Colors.grey,
                                  //                   ),
                                  //                 ),
                                  //                 const SizedBox(width: 8),
                                  //                 Text(
                                  //                   orderModel.customerName !=
                                  //                               null &&
                                  //                           orderModel
                                  //                               .customerName!
                                  //                               .trim()
                                  //                               .isNotEmpty
                                  //                       ? orderModel
                                  //                           .customerName!
                                  //                       : "Guest", // fallback if empty
                                  //                   style: const TextStyle(
                                  //                     fontWeight:
                                  //                         FontWeight.w700,
                                  //                   ),
                                  //                 ),
                                  //               ],
                                  //             ),
                                  //
                                  //             const SizedBox(height: 4),
                                  //
                                  //             // Customer Phone
                                  //             Row(
                                  //               // mainAxisAlignment:
                                  //               // MainAxisAlignment
                                  //               //     .spaceBetween,
                                  //               children: [
                                  //                 const Text(
                                  //                   "Contact Number :",
                                  //                   style: TextStyle(
                                  //                     color: Colors.grey,
                                  //                   ),
                                  //                 ),
                                  //                 const SizedBox(width: 8),
                                  //                 Text(
                                  //                   orderModel.customerPhone !=
                                  //                               null &&
                                  //                           orderModel
                                  //                               .customerPhone!
                                  //                               .trim()
                                  //                               .isNotEmpty
                                  //                       ? orderModel
                                  //                           .customerPhone!
                                  //                       : "-", // fallback if empty
                                  //                   style: const TextStyle(
                                  //                     fontWeight:
                                  //                         FontWeight.w700,
                                  //                   ),
                                  //                 ),
                                  //               ],
                                  //             ),
                                  //           ],
                                  //         ),
                                  //       ),
                                  //     ),
                                  //   ],
                                  // ),
                                  // ================= ORDER INFORMATION =================
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: theme.cardColor,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color:
                                        isDark
                                            ? Colors.white12
                                            : const Color(0xFFE1E4EA),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "ORDER INFORMATION",
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color:
                                            isDark
                                                ? Colors.white70
                                                : const Color(0xFF60708D),
                                            letterSpacing: 0.3,
                                          ),
                                        ),

                                        const SizedBox(height: 14),

                                        Row(
                                          children: [
                                            Expanded(
                                              child: _orderInfoRow(
                                                "Order ID",
                                                "#${orderModel.orderId ?? '-'}",
                                                isDark,
                                              ),
                                            ),

                                            Expanded(
                                              child: _orderInfoRow(
                                                "Order Type",
                                                "${orderModel.orderType ?? '-'}"
                                                    "${orderModel.tableName != null && orderModel.tableName!.trim().isNotEmpty ? ', ${orderModel.tableName}' : ''}",
                                                isDark,
                                              ),
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 12),

                                        Row(
                                          children: [
                                            Expanded(
                                              child: _orderInfoRow(
                                                "Payment Type",
                                                orderModel.paymentType ?? "-",
                                                isDark,
                                              ),
                                            ),

                                            Expanded(
                                              child: Row(
                                                children: [
                                                  Text(
                                                    "Order Status",
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color:
                                                      isDark
                                                          ? Colors.white54
                                                          : const Color(
                                                        0xFF8490A5,
                                                      ),
                                                    ),
                                                  ),

                                                  const SizedBox(width: 12),

                                                  Container(
                                                    padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 4,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                        0xFFDFF7E8,
                                                      ),
                                                      borderRadius:
                                                      BorderRadius.circular(
                                                        20,
                                                      ),
                                                    ),
                                                    child: Text(
                                                      orderModel.status ?? "-",
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        fontWeight:
                                                        FontWeight.w600,
                                                        color: Color(
                                                          0xFF24A148,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  // payment summary
                                  Flexible(
                                    fit: FlexFit.tight,
                                    child: Container(
                                      width: double.infinity,
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      padding: const EdgeInsets.fromLTRB(
                                        12,
                                        10,
                                        12,
                                        12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme.cardColor,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color:
                                          isDark
                                              ? Colors.white12
                                              : const Color(0xFFE1E4EA),
                                        ),
                                      ),
                                      child: SingleChildScrollView(
                                        physics: const ClampingScrollPhysics(),
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            // =========================================================
                                            // PAYMENT DETAILS HEADER
                                            // =========================================================
                                            Row(
                                              mainAxisAlignment:
                                              MainAxisAlignment
                                                  .spaceBetween,
                                              children: [
                                                Text(
                                                  "PAYMENT DETAILS",
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                    letterSpacing: 0.4,
                                                    color:
                                                    isDark
                                                        ? Colors.white70
                                                        : const Color(
                                                      0xFF60708D,
                                                    ),
                                                  ),
                                                ),

                                                if (orderModel.isUpdated
                                                    ?.toLowerCase() ==
                                                    'yes')
                                                  Row(
                                                    mainAxisSize:
                                                    MainAxisSize.min,
                                                    children: [
                                                      Image.asset(
                                                        'assets/refreshicon.png',
                                                        width: 11,
                                                        height: 11,
                                                        color: Colors.orange,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      const Text(
                                                        "Updated",
                                                        style: TextStyle(
                                                          color: Colors.orange,
                                                          fontWeight:
                                                          FontWeight.w600,
                                                          fontSize: 10,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                              ],
                                            ),

                                            const SizedBox(height: 10),

                                            // =========================================================
                                            // GROSS TOTAL
                                            // =========================================================
                                            paymentRow(
                                              "Gross Total",
                                              "$_currency${(orderModel.grossTotal ?? 0).toDouble().toStringAsFixed(2)}",
                                              fontWeight: FontWeight.w500,
                                              fontSize: 11,
                                            ),

                                            // =========================================================
                                            // COUPON / DISCOUNTS
                                            // =========================================================
                                            paymentRow(
                                              "Coupon / Discounts",
                                              "-$_currency${orderModel.totalCouponDiscount.toDouble().toStringAsFixed(2)}",
                                              color: Colors.green,
                                              fontSize: 11,
                                            ),

                                            const SizedBox(height: 4),

                                            // =========================================================
                                            // DIVIDER
                                            // =========================================================
                                            ShaderMask(
                                              shaderCallback: (Rect bounds) {
                                                final baseColor =
                                                isDark
                                                    ? Colors.white
                                                    : Colors.black;

                                                return LinearGradient(
                                                  begin: Alignment.centerLeft,
                                                  end: Alignment.centerRight,
                                                  colors: [
                                                    baseColor.withOpacity(0.1),
                                                    baseColor.withOpacity(0.7),
                                                    baseColor.withOpacity(0.1),
                                                  ],
                                                  stops: const [0.0, 0.5, 1.0],
                                                ).createShader(bounds);
                                              },
                                              blendMode: BlendMode.srcIn,
                                              child: DottedLine(
                                                dashLength: 6,
                                                dashGapLength: 4,
                                                lineThickness: 1,
                                                direction: Axis.horizontal,
                                                dashColor:
                                                isDark
                                                    ? Colors.white
                                                    : Colors.black,
                                              ),
                                            ),

                                            const SizedBox(height: 4),

                                            // =========================================================
                                            // SUB TOTAL
                                            // =========================================================
                                            paymentRow(
                                              "Sub Total",
                                              "$_currency${(orderModel.subTotal ?? 0).toDouble().toStringAsFixed(2)}",
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                            ),

                                            const SizedBox(height: 3),

                                            // =========================================================
                                            // TAX FOOD
                                            // =========================================================
                                            paymentRow(
                                              "Tax @5% Food",
                                              "",
                                              color:
                                              isDark
                                                  ? Colors.white54
                                                  : const Color(0xFF8190A8),
                                              fontSize: 10,
                                              fontWeight: FontWeight.w500,
                                            ),

                                            // =========================================================
                                            // CGST
                                            // =========================================================
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                left: 18,
                                              ),
                                              child: paymentRow(
                                                "CGST 2.5%",
                                                "$_currency${((orderModel.totalTax ?? 0) / 2).toStringAsFixed(2)}",
                                                fontSize: 9,
                                                color:
                                                isDark
                                                    ? Colors.white54
                                                    : const Color(
                                                  0xFF8190A8,
                                                ),
                                              ),
                                            ),

                                            // =========================================================
                                            // SGST
                                            // =========================================================
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                left: 18,
                                              ),
                                              child: paymentRow(
                                                "SGST 2.5%",
                                                "$_currency${((orderModel.totalTax ?? 0) / 2).toStringAsFixed(2)}",
                                                fontSize: 9,
                                                color:
                                                isDark
                                                    ? Colors.white54
                                                    : const Color(
                                                  0xFF8190A8,
                                                ),
                                              ),
                                            ),

                                            // =========================================================
                                            // ALCOHOL TAX
                                            // =========================================================
                                            paymentRow(
                                              "Tax Alcohol @Nil",
                                              "${_currency}0.00",
                                              fontSize: 10,
                                              color:
                                              isDark
                                                  ? Colors.white54
                                                  : const Color(0xFF8190A8),
                                              fontWeight: FontWeight.w500,
                                            ),

                                            const SizedBox(height: 4),

                                            // =========================================================
                                            // DIVIDER
                                            // =========================================================
                                            ShaderMask(
                                              shaderCallback: (Rect bounds) {
                                                final baseColor =
                                                isDark
                                                    ? Colors.white
                                                    : Colors.black;

                                                return LinearGradient(
                                                  begin: Alignment.centerLeft,
                                                  end: Alignment.centerRight,
                                                  colors: [
                                                    baseColor.withOpacity(0.1),
                                                    baseColor.withOpacity(0.7),
                                                    baseColor.withOpacity(0.1),
                                                  ],
                                                  stops: const [0.0, 0.5, 1.0],
                                                ).createShader(bounds);
                                              },
                                              blendMode: BlendMode.srcIn,
                                              child: DottedLine(
                                                dashLength: 6,
                                                dashGapLength: 4,
                                                lineThickness: 1,
                                                direction: Axis.horizontal,
                                                dashColor:
                                                isDark
                                                    ? Colors.white
                                                    : Colors.black,
                                              ),
                                            ),
                                            const SizedBox(height: 4),

                                            // =========================================================
                                            // TOTAL TAX
                                            // =========================================================
                                            paymentRow(
                                              "Total Tax",
                                              "$_currency${(orderModel.totalTax ?? 0).toDouble().toStringAsFixed(2)}",
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                            ),

                                            const SizedBox(height: 4),

                                            // =========================================================
                                            // DIVIDER
                                            // =========================================================
                                            ShaderMask(
                                              shaderCallback: (Rect bounds) {
                                                final baseColor =
                                                isDark
                                                    ? Colors.white
                                                    : Colors.black;

                                                return LinearGradient(
                                                  begin: Alignment.centerLeft,
                                                  end: Alignment.centerRight,
                                                  colors: [
                                                    baseColor.withOpacity(0.1),
                                                    baseColor.withOpacity(0.7),
                                                    baseColor.withOpacity(0.1),
                                                  ],
                                                  stops: const [0.0, 0.5, 1.0],
                                                ).createShader(bounds);
                                              },
                                              blendMode: BlendMode.srcIn,
                                              child: DottedLine(
                                                dashLength: 6,
                                                dashGapLength: 4,
                                                lineThickness: 1,
                                                direction: Axis.horizontal,
                                                dashColor:
                                                isDark
                                                    ? Colors.white
                                                    : Colors.black,
                                              ),
                                            ),

                                            const SizedBox(height: 4),

                                            // =========================================================
                                            // NET TOTAL
                                            // =========================================================
                                            paymentRow(
                                              "Net Total",
                                              "$_currency${(orderModel.netTotal ?? 0).toStringAsFixed(2)}",
                                              fontWeight: FontWeight.w600,
                                              fontSize: 11,
                                            ),

                                            // =========================================================
                                            // MERCHANT DISCOUNT
                                            // =========================================================
                                            paymentRow(
                                              "Merchant Discount",
                                              "-$_currency${(orderModel.merchantDiscount ?? 0).toDouble().toStringAsFixed(2)}",
                                              color: Colors.blue,
                                              fontSize: 10,
                                            ),

                                            // =========================================================
                                            // TIP
                                            // =========================================================
                                            if ((orderModel.tipAmount ?? 0) > 0)
                                              paymentRow(
                                                "Tip Amount",
                                                "$_currency${(orderModel.tipAmount ?? 0).toDouble().toStringAsFixed(2)}",
                                                color: Colors.green,
                                                fontSize: 10,
                                              ),

                                            // =========================================================
                                            // SERVICE CHARGE
                                            // =========================================================
                                            if ((orderModel
                                                .serviceChargeValue ??
                                                0) >
                                                0)
                                              paymentRow(
                                                "Service Charges",
                                                "$_currency${(orderModel.serviceChargeValue ?? 0).toDouble().toStringAsFixed(2)}",
                                                color: Colors.blue,
                                                fontSize: 10,
                                              ),

                                            // =========================================================
                                            // ROUND OFF
                                            // =========================================================
                                            paymentRow(
                                              "Round Off",
                                              "${(orderModel.roundOff ?? 0) >= 0 ? '+' : '-'}₹${(orderModel.roundOff ?? 0).abs().toStringAsFixed(2)}",
                                              color:
                                              isDark
                                                  ? Colors.white54
                                                  : const Color(0xFF8190A8),
                                              fontSize: 10,
                                            ),

                                            const SizedBox(height: 4),

                                            // =========================================================
                                            // FINAL DIVIDER
                                            // =========================================================
                                            ShaderMask(
                                              shaderCallback: (Rect bounds) {
                                                final baseColor =
                                                isDark
                                                    ? Colors.white
                                                    : Colors.black;

                                                return LinearGradient(
                                                  begin: Alignment.centerLeft,
                                                  end: Alignment.centerRight,
                                                  colors: [
                                                    baseColor.withOpacity(0.1),
                                                    baseColor.withOpacity(0.7),
                                                    baseColor.withOpacity(0.1),
                                                  ],
                                                  stops: const [0.0, 0.5, 1.0],
                                                ).createShader(bounds);
                                              },
                                              blendMode: BlendMode.srcIn,
                                              child: DottedLine(
                                                dashLength: 6,
                                                dashGapLength: 4,
                                                lineThickness: 1,
                                                direction: Axis.horizontal,
                                                dashColor:
                                                isDark
                                                    ? Colors.white
                                                    : Colors.black,
                                              ),
                                            ),

                                            const SizedBox(height: 7),

                                            // =========================================================
                                            // NET PAYABLE
                                            // =========================================================
                                            paymentRow(
                                              "Net Payable",
                                              "$_currency${(orderModel.netPayable ?? 0).toDouble().toStringAsFixed(2)}",
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: 4,
                                      bottom: 4,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        SizedBox(
                                          width: 155,
                                          height: 40,
                                          child: OutlinedButton(
                                            onPressed: () {
                                              // your existing Add Tip logic
                                            },
                                            style: OutlinedButton.styleFrom(
                                              backgroundColor: Colors.white,
                                              side: const BorderSide(
                                                color: Color(0xFFD5DCE8),
                                                width: 1,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                BorderRadius.circular(8),
                                              ),
                                              padding: EdgeInsets.zero,
                                            ),
                                            child: const Text(
                                              "Add Tip",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF3B4259),
                                              ),
                                            ),
                                          ),
                                        ),

                                        const SizedBox(width: 14),

                                        SizedBox(
                                          width: 155,
                                          height: 40,
                                          child: ElevatedButton.icon(
                                            onPressed: () async {
                                              try {
                                                Map<
                                                    String,
                                                    Map<String, dynamic>
                                                >
                                                consolidated = {};
                                                if (orderModel.kotOrders !=
                                                    null) {
                                                  for (var kot
                                                  in orderModel
                                                      .kotOrders!) {
                                                    if (kot.lineItems != null) {
                                                      for (var lineItem
                                                      in kot.lineItems!) {
                                                        final name =
                                                            lineItem.name ?? '';
                                                        final modifiers =
                                                            lineItem
                                                                .modifiers ??
                                                                [];
                                                        final key =
                                                            "$name-${modifiers.join(',')}";
                                                        if (consolidated
                                                            .containsKey(key)) {
                                                          final existing =
                                                          consolidated[key]!;
                                                          final currentQty =
                                                              int.tryParse(
                                                                existing['qty']
                                                                    .toString(),
                                                              ) ??
                                                                  0;
                                                          final addedQty =
                                                              lineItem
                                                                  .quantity ??
                                                                  0;
                                                          final newQty =
                                                              currentQty +
                                                                  addedQty;
                                                          existing['qty'] =
                                                              newQty;
                                                          existing['amount'] =
                                                              (double.tryParse(
                                                                existing['price']
                                                                    .toString(),
                                                              ) ??
                                                                  0.0) *
                                                                  newQty;
                                                        } else {
                                                          consolidated[key] = {
                                                            "name": name,
                                                            "qty":
                                                            lineItem
                                                                .quantity ??
                                                                0,
                                                            "price":
                                                            lineItem
                                                                .itemPrice ??
                                                                0.0,
                                                            "amount":
                                                            lineItem
                                                                .amount ??
                                                                0.0,
                                                            "modifiers":
                                                            modifiers,
                                                          };
                                                        }
                                                      }
                                                    }
                                                  }
                                                }

                                                final paymentSummaryObj = psm.PaymentSummary(
                                                  restaurantId:
                                                  orderModel.restaurantId ??
                                                      0,
                                                  orderId:
                                                  orderModel.orderId ?? 0,
                                                  grossTotal:
                                                  (orderModel.grossTotal ??
                                                      0)
                                                      .toDouble(),
                                                  tax:
                                                  (orderModel.totalTax ?? 0)
                                                      .toDouble(),
                                                  fees: 0.0,
                                                  discount:
                                                  (orderModel.merchantDiscount ??
                                                      0)
                                                      .toDouble(),
                                                  coupons:
                                                  orderModel
                                                      .totalCouponDiscount
                                                      .toDouble(),
                                                  tipAmount:
                                                  (orderModel.tipAmount ??
                                                      0)
                                                      .toDouble(),
                                                  netTotal:
                                                  (orderModel.netPayable ??
                                                      orderModel
                                                          .netTotal ??
                                                      0)
                                                      .toDouble(),
                                                  lineItems:
                                                  consolidated.values.map((
                                                      item,
                                                      ) {
                                                    return psm.LineItem(
                                                      productId: 0,
                                                      variationId: 0,
                                                      name:
                                                      item['name']
                                                          .toString(),
                                                      qty:
                                                      int.tryParse(
                                                        item['qty']
                                                            .toString(),
                                                      ) ??
                                                          0,
                                                      price:
                                                      double.tryParse(
                                                        item['price']
                                                            .toString(),
                                                      ) ??
                                                          0.0,
                                                      total:
                                                      double.tryParse(
                                                        item['amount']
                                                            .toString(),
                                                      ) ??
                                                          0.0,
                                                      tax: 0.0,
                                                      taxClass: 'food',
                                                      modifiers: List<
                                                          String
                                                      >.from(
                                                        item['modifiers'] ??
                                                            [],
                                                      ),
                                                      modifierAmount: 0.0,
                                                    );
                                                  }).toList(),
                                                  tableId:
                                                  orderModel.tableId ?? 0,
                                                  tableName:
                                                  orderModel.tableName ??
                                                      "",
                                                  zoneId:
                                                  orderModel.zoneId ?? 0,
                                                  modifiersTaxable: false,
                                                  isNoCharge: false,
                                                  couponDetails:
                                                  orderModel.couponDetails?.map((
                                                      e,
                                                      ) {
                                                    return psm.CouponDetail(
                                                      code: e.code ?? "",
                                                      value:
                                                      (e.value ?? 0)
                                                          .toDouble(),
                                                    );
                                                  }).toList() ??
                                                      [],
                                                  serviceChargePercentage:
                                                  (orderModel.serviceChargePercentage ??
                                                      0)
                                                      .toDouble(),
                                                  serviceChargeValue:
                                                  (orderModel.serviceChargeValue ??
                                                      0)
                                                      .toDouble(),
                                                  roundOff:
                                                  (orderModel.roundOff ?? 0)
                                                      .toDouble(),
                                                );

                                                showDialog(
                                                  context: context,
                                                  barrierDismissible: false,
                                                  builder:
                                                      (context) => Dialog(
                                                    backgroundColor:
                                                    Colors.transparent,
                                                    insetPadding:
                                                    EdgeInsets.zero,
                                                    child: Align(
                                                      alignment:
                                                      Alignment
                                                          .centerLeft,
                                                      child: Padding(
                                                        padding:
                                                        const EdgeInsets.only(
                                                          left: 330,
                                                          top: 60,
                                                          bottom: 60,
                                                        ),
                                                        child: PrintRecipt(
                                                          loadedTables:
                                                          const [],
                                                          pin: widget.pin,
                                                          token:
                                                          widget.token,
                                                          restaurantId:
                                                          widget
                                                              .restaurantId,
                                                          restaurantName:
                                                          widget
                                                              .restaurantName,
                                                          zoneId:
                                                          orderModel
                                                              .zoneId,
                                                          paymentSummary:
                                                          paymentSummaryObj,
                                                          cashierName:
                                                          widget
                                                              .userPermissions
                                                              ?.displayName ??
                                                              'Admin',
                                                          isTakeAway:
                                                          orderModel
                                                              .orderType
                                                              ?.toLowerCase()
                                                              .contains(
                                                            "take",
                                                          ) ??
                                                              false,
                                                          isFromOrderDetails:
                                                          true,
                                                          isCopy: true,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              } catch (e) {
                                                debugPrint(
                                                  "Print Bill Error: $e",
                                                );
                                              }
                                            },
                                            icon: const Icon(
                                              Icons.print,
                                              size: 14,
                                              color: Colors.white,
                                            ),
                                            label: const Text(
                                              "Print Bill",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                              ),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(
                                                0xFF173B6B,
                                              ),
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                BorderRadius.circular(8),
                                              ),
                                              padding: EdgeInsets.zero,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // SizedBox(
                                  //   width: double.infinity,
                                  //   height: 40,
                                  //   child: ElevatedButton(
                                  //     style: ElevatedButton.styleFrom(
                                  //       backgroundColor: const Color(
                                  //         0xFF3F65A1,
                                  //       ),
                                  //       shape: RoundedRectangleBorder(
                                  //         borderRadius: BorderRadius.circular(
                                  //           10,
                                  //         ),
                                  //       ),
                                  //     ),
                                  //     onPressed: () async {
                                  //       try {
                                  //         Map<String, Map<String, dynamic>>
                                  //         consolidated = {};
                                  //         if (orderModel.kotOrders != null) {
                                  //           for (var kot
                                  //               in orderModel.kotOrders!) {
                                  //             if (kot.lineItems != null) {
                                  //               for (var lineItem
                                  //                   in kot.lineItems!) {
                                  //                 final name =
                                  //                     lineItem.name ?? '';
                                  //                 final modifiers =
                                  //                     lineItem.modifiers ?? [];
                                  //                 final key =
                                  //                     "$name-${modifiers.join(',')}";
                                  //                 if (consolidated.containsKey(
                                  //                   key,
                                  //                 )) {
                                  //                   final existing =
                                  //                       consolidated[key]!;
                                  //                   final currentQty =
                                  //                       int.tryParse(
                                  //                         existing['qty']
                                  //                             .toString(),
                                  //                       ) ??
                                  //                       0;
                                  //                   final addedQty =
                                  //                       lineItem.quantity ?? 0;
                                  //                   final newQty =
                                  //                       currentQty + addedQty;
                                  //                   existing['qty'] = newQty;
                                  //                   existing['amount'] =
                                  //                       (double.tryParse(
                                  //                             existing['price']
                                  //                                 .toString(),
                                  //                           ) ??
                                  //                           0.0) *
                                  //                       newQty;
                                  //                 } else {
                                  //                   consolidated[key] = {
                                  //                     "name": name,
                                  //                     "qty":
                                  //                         lineItem.quantity ??
                                  //                         0,
                                  //                     "price":
                                  //                         lineItem.itemPrice ??
                                  //                         0.0,
                                  //                     "amount":
                                  //                         lineItem.amount ??
                                  //                         0.0,
                                  //                     "modifiers": modifiers,
                                  //                   };
                                  //                 }
                                  //               }
                                  //             }
                                  //           }
                                  //         }
                                  //
                                  //         final paymentSummaryObj = psm.PaymentSummary(
                                  //           restaurantId:
                                  //               orderModel.restaurantId ?? 0,
                                  //           orderId: orderModel.orderId ?? 0,
                                  //           grossTotal:
                                  //               (orderModel.grossTotal ?? 0)
                                  //                   .toDouble(),
                                  //           tax:
                                  //               (orderModel.totalTax ?? 0)
                                  //                   .toDouble(),
                                  //           fees: 0.0,
                                  //           discount:
                                  //               (orderModel.merchantDiscount ??
                                  //                       0)
                                  //                   .toDouble(),
                                  //           coupons:
                                  //               orderModel.totalCouponDiscount
                                  //                   .toDouble(),
                                  //           tipAmount:
                                  //               (orderModel.tipAmount ?? 0)
                                  //                   .toDouble(),
                                  //           netTotal:
                                  //               (orderModel.netPayable ??
                                  //                       orderModel.netTotal ??
                                  //                       0)
                                  //                   .toDouble(),
                                  //           lineItems:
                                  //               consolidated.values.map((item) {
                                  //                 return psm.LineItem(
                                  //                   productId: 0,
                                  //                   variationId: 0,
                                  //                   name:
                                  //                       item['name'].toString(),
                                  //                   qty:
                                  //                       int.tryParse(
                                  //                         item['qty']
                                  //                             .toString(),
                                  //                       ) ??
                                  //                       0,
                                  //                   price:
                                  //                       double.tryParse(
                                  //                         item['price']
                                  //                             .toString(),
                                  //                       ) ??
                                  //                       0.0,
                                  //                   total:
                                  //                       double.tryParse(
                                  //                         item['amount']
                                  //                             .toString(),
                                  //                       ) ??
                                  //                       0.0,
                                  //                   tax: 0.0,
                                  //                   taxClass: 'food',
                                  //                   modifiers:
                                  //                       List<String>.from(
                                  //                         item['modifiers'] ??
                                  //                             [],
                                  //                       ),
                                  //                   modifierAmount: 0.0,
                                  //                 );
                                  //               }).toList(),
                                  //           tableId: orderModel.tableId ?? 0,
                                  //           tableName:
                                  //               orderModel.tableName ?? "",
                                  //           zoneId: orderModel.zoneId ?? 0,
                                  //           modifiersTaxable: false,
                                  //           isNoCharge: false,
                                  //           couponDetails:
                                  //               orderModel.couponDetails?.map((
                                  //                 e,
                                  //               ) {
                                  //                 return psm.CouponDetail(
                                  //                   code: e.code ?? "",
                                  //                   value:
                                  //                       (e.value ?? 0)
                                  //                           .toDouble(),
                                  //                 );
                                  //               }).toList() ??
                                  //               [],
                                  //           serviceChargePercentage:
                                  //               (orderModel.serviceChargePercentage ??
                                  //                       0)
                                  //                   .toDouble(),
                                  //           serviceChargeValue:
                                  //               (orderModel.serviceChargeValue ??
                                  //                       0)
                                  //                   .toDouble(),
                                  //           roundOff:
                                  //               (orderModel.roundOff ?? 0)
                                  //                   .toDouble(),
                                  //         );
                                  //
                                  //         showDialog(
                                  //           context: context,
                                  //           barrierDismissible: false,
                                  //           builder:
                                  //               (context) => Dialog(
                                  //                 backgroundColor:
                                  //                     Colors.transparent,
                                  //                 insetPadding: EdgeInsets.zero,
                                  //                 child: Align(
                                  //                   alignment:
                                  //                       Alignment.centerLeft,
                                  //                   child: Padding(
                                  //                     padding:
                                  //                         const EdgeInsets.only(
                                  //                           left: 330,
                                  //                           top: 60,
                                  //                           bottom: 60,
                                  //                         ),
                                  //                     child: PrintRecipt(
                                  //                       loadedTables: const [],
                                  //                       pin: widget.pin,
                                  //                       token: widget.token,
                                  //                       restaurantId:
                                  //                           widget.restaurantId,
                                  //                       restaurantName:
                                  //                           widget
                                  //                               .restaurantName,
                                  //                       zoneId:
                                  //                           orderModel.zoneId,
                                  //                       paymentSummary:
                                  //                           paymentSummaryObj,
                                  //                       cashierName:
                                  //                           widget
                                  //                               .userPermissions
                                  //                               ?.displayName ??
                                  //                           'Admin',
                                  //                       isTakeAway:
                                  //                           orderModel.orderType
                                  //                               ?.toLowerCase()
                                  //                               .contains(
                                  //                                 "take",
                                  //                               ) ??
                                  //                           false,
                                  //                       isFromOrderDetails:
                                  //                           true,
                                  //                       isCopy: true,
                                  //                     ),
                                  //                   ),
                                  //                 ),
                                  //               ),
                                  //         );
                                  //       } catch (e) {
                                  //         debugPrint("Print Bill Error: $e");
                                  //       }
                                  //     },
                                  //     child: const Row(
                                  //       mainAxisAlignment:
                                  //           MainAxisAlignment.center,
                                  //       children: [
                                  //         Icon(
                                  //           Icons.print,
                                  //           color: Colors.white,
                                  //           size: 18,
                                  //         ),
                                  //         SizedBox(width: 8),
                                  //         Text(
                                  //           "Print Bill",
                                  //           style: TextStyle(
                                  //             fontSize: 16,
                                  //             fontWeight: FontWeight.bold,
                                  //             color: Colors.white,
                                  //           ),
                                  //         ),
                                  //       ],
                                  //     ),
                                  //   ),
                                  // ),
                                ],
                              ),
                            ),
                          ),

                          // const SizedBox(height: 4),

                          // Container(
                          //   margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                          //
                          //   child: SizedBox(
                          //     width: double.infinity,
                          //     height: 36,
                          //     child: ElevatedButton(
                          //       style: ElevatedButton.styleFrom(
                          //         backgroundColor: const  Color(0xFFF7C127),
                          //         shape: RoundedRectangleBorder(
                          //           borderRadius: BorderRadius.circular(10),
                          //         ),
                          //       ),
                          //       onPressed: () {
                          //
                          //       },
                          //       child: const Text(
                          //         "Print Bill",
                          //         style: TextStyle(
                          //           fontSize: 16,
                          //           fontWeight: FontWeight.bold,
                          //           color: Colors.white,
                          //         ),
                          //       ),
                          //     ),
                          //   ),
                          // ),
                        ],
                      ),
                    ),
                  ),

                  /// 🔹 RIGHT BLOCK (KOTs)
                  Flexible(
                    flex: 1,
                    child: Container(
                      height: blockHeight,
                      margin: const EdgeInsets.all(6),
                      padding: const EdgeInsets.all(12),
                      // decoration: BoxDecoration(
                      //   color:
                      //       isDark
                      //           ? const Color(0xFF202433)
                      //           : const Color(0xFFF6F6F6),
                      //   borderRadius: BorderRadius.circular(12),
                      // ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ==========================================
                          // MODIFICATION SUMMARY
                          // ONLY SHOW AFTER AN UPDATE
                          // ==========================================
                          if (orderModel.isUpdated?.toLowerCase() == 'yes')
                            _buildModificationSummary(orderModel),

                          const SizedBox(height: 12),

                          // KOT TABLE
                          Expanded(
                            child: buildSelectedKotCard(order, orderModel),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),

      /// 🔹 BOTTOM NAV BAR
      // bottomNavigationBar: BottomNavBar(
      //   selectedIndex: 4,
      //   userPermissions: _userPermissions,
      //   onItemTapped: (int index) {
      //     NavigationHelper.handleNavigation(
      //       context,
      //       4,
      //       index,
      //       widget.pin,
      //       widget.token,
      //       widget.restaurantId,
      //       widget.restaurantName,
      //       _userPermissions,
      //     );
      //   },
      // ),
    );
  }

  Widget _buildModificationSummary(OrderlistModel orderModel) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final previousTotal = orderModel.orderPrevTotal ?? 0;

    // Current amount after modification
    final currentTotal = orderModel.netPayable ?? 0;

    final difference = currentTotal - previousTotal;

    final refundDue = difference < 0 ? difference.abs() : 0;
    final additionalDue = difference > 0 ? difference : 0;

    final modifiedBy =
    orderModel.placedByName?.trim().isNotEmpty == true
        ? orderModel.placedByName!
        : orderModel.completedByUserId?.trim().isNotEmpty == true
        ? orderModel.completedByUserId!
        : '-';

    final modifiedOn =
    orderModel.date?.trim().isNotEmpty == true ? orderModel.date! : '-';

    final reason =
    orderModel.updated_remarks?.trim().isNotEmpty == true
        ? orderModel.updated_remarks!
        : '-';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF332A17) : const Color(0xFFFFFBEB),
        border: Border.all(color: const Color(0xFFF59E0B), width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // =========================================================
          // HEADER
          // =========================================================
          _buildModificationHeader(orderModel),

          const SizedBox(height: 14),

          // =========================================================
          // ALL INFORMATION IN ONE ROW
          // =========================================================
          LayoutBuilder(
            builder: (context, constraints) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Modified by
                  Expanded(
                    flex: 2,
                    child: _buildModificationInfo(
                      label: 'Modified by',
                      value: modifiedBy,
                    ),
                  ),

                  const SizedBox(width: 30),

                  // Modified on
                  Expanded(
                    flex: 2,
                    child: _buildModificationInfo(
                      label: 'Modified on',
                      value: modifiedOn,
                    ),
                  ),

                  const SizedBox(width: 30),

                  // Reason
                  Expanded(
                    flex: 3,
                    child: _buildModificationInfo(
                      label: 'Reason',
                      value: reason,
                    ),
                  ),

                  const SizedBox(width: 30),

                  // Amount
                  Expanded(
                    flex: 2,
                    child: _buildAmountSection(
                      previousTotal: previousTotal,
                      currentTotal: currentTotal,
                      difference: difference,
                      refundDue: refundDue,
                      additionalDue: additionalDue,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildModificationInfo({
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 3),

        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF1E293B),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildAmountSection({
    required num previousTotal,
    required num currentTotal,
    required num difference,
    required num refundDue,
    required num additionalDue,
  }) {
    final isRefund = refundDue > 0;

    return Container(
      constraints: const BoxConstraints(minWidth: 210),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            isRefund
                ? 'Refund Due $_currency${refundDue.toStringAsFixed(2)}'
                : additionalDue > 0
                ? 'Additional Due $_currency${additionalDue.toStringAsFixed(2)}'
                : 'No Amount Change',
            textAlign: TextAlign.right,
            style: TextStyle(
              color:
              isRefund ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            '$_currency${previousTotal.toStringAsFixed(2)}'
                ' → '
                '$_currency${currentTotal.toStringAsFixed(2)}',
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModificationHeader(OrderlistModel orderModel) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'MODIFICATION SUMMARY',
            style: TextStyle(
              color: Color(0xFFB45309),
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            '✏️ Modified',
            style: TextStyle(
              color: Color(0xFFB45309),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _modificationInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _verticalDivider() {
    return Container(
      width: 1,
      height: 42,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      color: const Color(0xFFE5E7EB),
    );
  }

  Widget buildSelectedKotCard(
      Map<String, dynamic> order,
      OrderlistModel orderModel,
      ) {
    final kots = (order["kots"] as List<dynamic>?) ?? [];

    //  Auto select first KOT if not selected
    if (selectedKotId == null && kots.isNotEmpty) {
      selectedKotId = kots.first["kotNo"];

      //  LOAD VOIDED ITEMS INITIALLY
      WidgetsBinding.instance.addPostFrameCallback((_) {
        loadVoidedItems(selectedKotId!);
      });
    }

    final selectedKot = kots.cast<Map<String, dynamic>?>().firstWhere(
          (kot) => kot?["kotNo"] == selectedKotId,
      orElse: () => null,
    );

    if (selectedKot == null) {
      return const Center(
        child: Text("No KOT Selected", style: TextStyle(color: Colors.grey)),
      );
    }

    return buildKOTCard(selectedKot, kots, orderModel);
  }

  Widget buildKOTCard(
      Map<String, dynamic> selectedKot,
      List<dynamic> kots,
      OrderlistModel orderModel,
      ) {
    final items = (selectedKot["items"] as List<dynamic>?) ?? [];

    final bool showVoided = orderModel.isUpdated?.toLowerCase() == 'yes';

    final List<Map<String, dynamic>> normalItems =
    items.whereType<Map<String, dynamic>>().toList();

    final List<VoidedItem> voidedItems =
    (showVoided && !isVoidedLoading && voidedItemsResponse != null)
        ? voidedItemsResponse!.items
        : [];

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // ============================================================
    // KOT TOTAL
    // ============================================================

    double kotTotal = 0.0;

    // Prefer total coming from API if available
    final dynamic apiKotTotal = selectedKot["total"];

    if (apiKotTotal != null) {
      kotTotal = double.tryParse(apiKotTotal.toString()) ?? 0.0;
    } else {
      // Otherwise calculate from items
      for (final item in normalItems) {
        final amount =
            double.tryParse(item["amount"]?.toString() ?? "0") ?? 0.0;

        kotTotal += amount;
      }
    }

    // ============================================================
    // KOT NUMBER
    // ============================================================

    final kotNumber = selectedKot["kotNo"]?.toString() ?? "-";

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE1E4EA),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.12 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ========================================================
          // KOT HEADER
          // ========================================================
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // KOT's
              Text(
                "KOT’s",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF252A3A),
                ),
              ),

              // ====================================================
              // KOT DROPDOWN
              // ====================================================
              Container(
                height: 36,
                padding: const EdgeInsets.only(left: 12, right: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF125BCE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: selectedKotId,

                    hint: const Text(
                      "Select KOT",
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),

                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white,
                      size: 20,
                    ),

                    dropdownColor: const Color(0xFF125BCE),

                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),

                    borderRadius: BorderRadius.circular(8),

                    items:
                    kots.map((kot) {
                      return DropdownMenuItem<int>(
                        value: kot["kotNo"],
                        child: Text(
                          "${kot["kotNumber"]}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      );
                    }).toList(),

                    onChanged: (value) {
                      if (value == null) return;

                      setState(() {
                        selectedKotId = value;
                      });

                      loadVoidedItems(value);
                    },
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ========================================================
          // TABLE HEADER
          // ========================================================
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF34384F) : const Color(0xFF999393),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(7),
                topRight: Radius.circular(7),
              ),
            ),

            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: const [
                // #
                Expanded(
                  flex: 1,
                  child: Text(
                    "#",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),

                // ITEM NAME
                Expanded(
                  flex: 4,
                  child: Text(
                    "Item Name",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),

                // QUANTITY
                Expanded(
                  flex: 2,
                  child: Text(
                    "Quantity",
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),

                // AMOUNT
                Expanded(
                  flex: 2,
                  child: Text(
                    "Amount",
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ========================================================
          // ITEMS
          // ========================================================
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: isDark ? Colors.white12 : const Color(0xFFE1E4EA),
                  ),
                  right: BorderSide(
                    color: isDark ? Colors.white12 : const Color(0xFFE1E4EA),
                  ),
                ),
              ),

              child:
              isVoidedLoading && showVoided
                  ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
                  : ListView.builder(
                padding: EdgeInsets.zero,

                itemCount: normalItems.length + voidedItems.length,

                itemBuilder: (context, index) {
                  // ==========================================
                  // NORMAL ITEM
                  // ==========================================

                  if (index < normalItems.length) {
                    final item = normalItems[index];

                    return Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),

                      decoration: BoxDecoration(
                        color:
                        isDark
                            ? const Color(0xFF202433)
                            : Colors.white,

                        border: Border(
                          bottom: BorderSide(
                            color:
                            isDark
                                ? Colors.white12
                                : const Color(0xFFE1E4EA),
                          ),
                        ),
                      ),

                      child: _buildNormalRow(item, index),
                    );
                  }

                  // ==========================================
                  // VOIDED ITEM
                  // ==========================================

                  final voidedIndex = index - normalItems.length;

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),

                    decoration: BoxDecoration(
                      color:
                      isDark
                          ? const Color(0xFF2A2F3D)
                          : Colors.grey.shade200,

                      border: Border(
                        bottom: BorderSide(
                          color:
                          isDark
                              ? Colors.white12
                              : const Color(0xFFE1E4EA),
                        ),
                      ),
                    ),

                    child: _buildVoidedRow(
                      voidedItems[voidedIndex],
                      index,
                    ),
                  );
                },
              ),
            ),
          ),

          // ========================================================
          // KOT TOTAL FOOTER
          // ========================================================
          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),

            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF202433) : const Color(0xFFF8FAFC),

              border: Border(
                left: BorderSide(
                  color: isDark ? Colors.white12 : const Color(0xFFE1E4EA),
                ),
                right: BorderSide(
                  color: isDark ? Colors.white12 : const Color(0xFFE1E4EA),
                ),
                bottom: BorderSide(
                  color: isDark ? Colors.white12 : const Color(0xFFE1E4EA),
                ),
              ),

              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(7),
                bottomRight: Radius.circular(7),
              ),
            ),

            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // LEFT
                Text(
                  "KOT #$kotNumber — Total",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF252A3A),
                  ),
                ),

                // RIGHT
                Text(
                  "$_currency${kotTotal.toStringAsFixed(2)}",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF125BCE),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // payment summary
  Widget paymentRow(
      String title,
      String amount, {
        Color? color,
        double fontSize = 14,
        FontWeight fontWeight = FontWeight.normal,
      }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final textColor = color ?? (isDark ? Colors.white : Colors.black);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: textColor,
              fontSize: fontSize,
              fontWeight: fontWeight,
            ),
          ),
          Text(
            amount,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: textColor,
              fontSize: fontSize,
              fontWeight: fontWeight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNormalRow(Map<String, dynamic> item, int index) {
    final modifierNames = extractModifierNames(item);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Text(
            "${index + 1}",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item['name'] ?? "-",
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              if (modifierNames.isNotEmpty)
                Text(
                  modifierNames.join(", "),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.grey,
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            "${item['qty']} x $_currency${(item['item_price'] ?? 0).toStringAsFixed(2)}",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Text(
            item['total_wo_tax'] != null
                ? "$_currency${item['total_wo_tax'].toStringAsFixed(2)}"
                : "-",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVoidedRow(VoidedItem item, int index) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final voidColor = isDark ? Colors.white54 : const Color(0xFFB9B9B9);

    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Text(
            "${index + 1}",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: voidColor,
              // decoration: TextDecoration.lineThrough,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            item.product,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: voidColor,
              // decoration: TextDecoration.lineThrough,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            "${item.origQty}",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: voidColor,
              // decoration: TextDecoration.lineThrough,
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Text(
            item.itemTotal.toStringAsFixed(2),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: voidColor,
              // decoration: TextDecoration.lineThrough,
            ),
          ),
        ),
      ],
    );
  }

  Widget _orderInfoRow(String label, String value, bool isDark) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.white54 : const Color(0xFF8490A5),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF263248),
            ),
          ),
        ),
      ],
    );
  }
}
