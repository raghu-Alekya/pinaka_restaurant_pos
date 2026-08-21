import 'dart:convert';

import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/material.dart';
import 'package:pinaka_restaurant_pos/App%20flow/ui/view_order_details_screen.dart';
import '../../constants/constants.dart';
import '../../models/UserPermissions.dart';
import '../../models/order_list/edit_order_list_model.dart';
import '../../models/order_list/order_list_model.dart';
// import '../../repositories/edit_orderlist_repository.dart';
import '../../repositories/edit_order_repository.dart';
import '../../repositories/order_list_repository.dart';
import '../../utils/SessionManager.dart';
import '../widgets/navigationhelper.dart';
import '../widgets/top_bar.dart';
import '../widgets/bottom_nav_bar.dart';

class EditOrdersListScreen extends StatefulWidget {
  final String token;
  final String pin;
  final String restaurantId;
  final String restaurantName;
  final int orderId;
  final UserPermissions? userPermissions;

  const EditOrdersListScreen({
    super.key,
    required this.token,
    required this.pin,
    required this.restaurantId,
    required this.restaurantName,
    required this.orderId,
    this.userPermissions,
  });

  @override
  State<EditOrdersListScreen> createState() => _EditOrdersListScreenState();
}

class _EditOrdersListScreenState extends State<EditOrdersListScreen> {
  final OrderstatusRepository _orderRepo = OrderstatusRepository();
  List<String> kot_remarks = [
    "Wrong Item Added",
    "Customer requested item change",
    "Quantity Correction",
    "Item Preparation Error",
    "Unavailable Item Replacement",
    "Wrong Table or Order Mapped",
    "Manual Entry Mistakes",
  ];

  double _fixedTotalTax = 0.0;
  bool _justUpdated = false;
  double? _previousNetPayable;
  bool _kotUpdatedOnce = false;
  String _currency = "₹";
  String? selectedReason;
  final TextEditingController _remarksController = TextEditingController();
  String _formatCurrency(num value) {
    return "$_currency${value.toStringAsFixed(2)}";
  }
  UserPermissions? _userPermissions;
  int _selectedIndex = 4;
  bool _isUpdateEnabled = false; // initially disabled
  OrderlistModel? _updatedOrder;
  DateTime? _modifiedAt;
  Future<List<OrderlistModel>>? _ordersFuture;

  int? _selectedKotId;
  KotOrder? _selectedKot;
  double _dynamicNetPayable = 0.0;
  bool _netPayableInitialized = false;
  bool _isUpdatingKot = false;
  String? _updateMessage; // null when no message
  bool _kotUpdated = false;

  VoidedItemsResponse? _voidedItemsResponse;
  late final OrderstatusRepository _orderStatusRepo;
  // Step 1: Just fetch net payable (no calculation)
  String getNetPayable(OrderlistModel order) {
    double netPayable = (order.netPayable ?? 0).toDouble();
    return "₹${netPayable.toStringAsFixed(2)}";
  }

  List<LineItem> _leftPanelItems = [];
  double _selectedKotOriginalTotal = 0.0;
  List<VoidedItem> _currentVoidedItems = [];
  List<VoidedItem> _voidedItems = [];
  bool _isVoidedLoading = false;
  int? _lastFetchedKotId;
  final Map<int, List<VoidedItem>> _voidedCache = {};

  // EDITABLE PER KOT (persisted)
  final Map<int, List<LineItem>> _editedKotItems = {};
  @override
  void initState() {
    super.initState();
    _userPermissions = widget.userPermissions;
    _ordersFuture = _orderRepo.fetchOrders(widget.token);
    _orderStatusRepo = OrderstatusRepository();
    _loadPermissions();
    _loadCurrency(); // <-- Add this
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadPermissions(),
      _loadCurrency(),
    ]);

    if (!mounted) return;

    setState(() {
      _ordersFuture = _orderRepo.fetchOrders(widget.token);
    });
  }
  Future<void> _loadCurrency() async {
    final currency = await SessionManager.getCurrencySymbol();

    if (mounted) {
      setState(() {
        _currency = currency ?? "₹";
      });
    }
  }

  Future<void> _loadVoidedItemsForKot(KotOrder kot) async {
    if (_lastFetchedKotId == kot.kotOrderId) return;

    _lastFetchedKotId = kot.kotOrderId;

    setState(() {
      _isVoidedLoading = true;
      _currentVoidedItems = [];
    });

    try {
      final response = await OrderstatusRepository().fetchVoidedItems(
        kotOrderId: kot.kotOrderId!,
        token: widget.token,
      );

      debugPrint("🔴 Voided items fetched: ${response.items.length}");

      setState(() {
        _currentVoidedItems = response.items;
      });
    } catch (e) {
      debugPrint("❌ Voided items error: $e");
    } finally {
      setState(() {
        _isVoidedLoading = false;
      });
    }
  }

  Future<void> _loadPermissions() async {
    final savedPermissions = await SessionManager.loadPermissions();
    if (savedPermissions != null) {
      setState(() {
        _userPermissions = savedPermissions;
      });
    }
  }

  void _showVoidedItemsDialog(List<VoidedItem> items) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text("Voided Items"),
          content: SizedBox(
            width: 420,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final item = items[index];
                return ListTile(
                  title: Text(item.product),
                  subtitle: Text(
                    'Qty ${item.origQty} → ${item.newQty}\n'
                        'Reason: ${item.remarks}',
                  ),
                  trailing: Text(
                    '$_currency${item.itemTotal.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }
  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return months[month - 1];
  }

  String _formatTime(DateTime time) {
    final hour = time.hour == 0
        ? 12
        : time.hour > 12
        ? time.hour - 12
        : time.hour;

    final minute = time.minute.toString().padLeft(2, '0');

    final period = time.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }
  double _calculateRefundDue(OrderlistModel order) {
    final previous = order.orderPrevTotal?.toDouble() ?? 0;
    final current = order.netPayable?.toDouble() ?? 0;

    final refund = previous - current;

    return refund > 0 ? refund : 0;
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
    setState(() => _selectedIndex = index);
  }

  // Central KOT selection handler
  void _onKotSelected(int kotId, List<KotOrder> kots) {
    setState(() {
      _selectedKotId = kotId;
      _selectedKot = kots.firstWhere((k) => k.kotOrderId == kotId);

      _selectedKotOriginalTotal = (_selectedKot?.lineItems ?? []).fold(
        0.0,
            (sum, i) => sum + (i.totalWoTax ?? 0),
      );

      // LEFT PANEL (always original snapshot)
      _leftPanelItems =
          (_selectedKot?.lineItems ?? []).map((item) {
            final qty = item.quantity ?? 1;
            final totalWoTax = item.totalWoTax ?? 0.0;

            return LineItem(
              lineItemId: item.lineItemId,
              itemId: item.itemId,
              name: item.name,
              quantity: qty,
              maxQty: qty,
              totalWoTax: totalWoTax,
              amount: item.amount,
              unitPrice: qty > 0 ? totalWoTax / qty : 0.0,
              modifiers: parseModifiers(item.modifiers),
            );
          }).toList();

      //  RIGHT PANEL (restore edits OR create editable copy)
      _editedKotItems.putIfAbsent(
        kotId,
            () =>
            _selectedKot!.lineItems!.map((item) {
              final qty = item.quantity ?? 1;
              final totalWoTax = item.totalWoTax ?? 0.0;

              return LineItem(
                lineItemId: item.lineItemId,
                itemId: item.itemId,
                name: item.name,
                quantity: qty,
                maxQty: qty,
                totalWoTax: totalWoTax,
                amount: item.amount,
                unitPrice: qty > 0 ? totalWoTax / qty : 0.0,
                modifiers: parseModifiers(item.modifiers),
              );
            }).toList(),
      );
    });
  }

  VoidedItem? _getVoidedItemByItemId(int? itemId) {
    if (itemId == null) return null;

    try {
      return _voidedItems.firstWhere((v) => v.itemId == itemId);
    } catch (_) {
      return null;
    }
  }

  List<String> parseModifiers(dynamic raw) {
    if (raw == null) return [];

    if (raw is List) {
      // List of strings or objects
      return raw
          .map<String>((m) {
        if (m is String) return m;
        if (m is Map) return m['name']?.toString() ?? '';
        return '';
      })
          .where((e) => e.isNotEmpty)
          .toList();
    }

    if (raw is String) {
      // Possibly JSON string
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded
              .map<String>((m) {
            if (m is String) return m;
            if (m is Map) return m['name']?.toString() ?? '';
            return '';
          })
              .where((e) => e.isNotEmpty)
              .toList();
        }
      } catch (e) {
        // Not JSON, just raw string
        return [raw];
      }
    }

    return [];
  }

  Future<void> _refreshOrders() async {
    OrderstatusRepository.invalidateCache(); // ADDED: force fresh data after KOT update
    final orders = await _orderRepo.fetchOrders(widget.token);

    final updatedLeftPanelItems = <LineItem>[];
    for (final order in orders) {
      for (final kot in order.kotOrders ?? []) {
        for (final item in kot.lineItems ?? []) {
          if ((item.quantity ?? 0) > 0) {
            updatedLeftPanelItems.add(item);
          }
        }
      }
    }

    if (!mounted) return;

    setState(() {
      _leftPanelItems = updatedLeftPanelItems;
      _ordersFuture = Future.value(orders);
    });
  }

  Future<void> _updateKot() async {
    if (_selectedKot == null) return;

    if (selectedReason == null || selectedReason!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a reason"),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() {
      _isUpdatingKot = true; // 🔹 START LOADER
      _updateMessage = null; // clear old success
    });
    final repo = EditOrderlistRepository(
      baseUrl: AppConstants.baseApiPath,
      token: widget.token,
    );

    final int kotId = _selectedKot!.kotOrderId!;

    try {
      // 1️⃣ Validate order & KOT
      final order = await repo.fetchOrder(widget.orderId);

      order.kotOrders?.firstWhere(
            (k) => k.kotOrderId == kotId,
        orElse: () => throw Exception("Selected KOT not found"),
      );

      // 2️⃣ Edited items
      final items = _editedKotItems[_selectedKotId];
      if (items == null || items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("⚠️ No items to update"),
            duration: Duration(seconds: 1),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // 3️⃣ Build payload
      final List<Map<String, dynamic>> lineItemsPayload = [];
      print("🔴 ===== KOT UPDATE ID DEBUG =====");
      print("🔴 widget.orderId      = ${widget.orderId}");
      print("🔴 kotId               = $kotId");
      print("🔴 selectedKotId       = $_selectedKotId");
      print("🔴 edited items count  = ${items.length}");

      for (final item in items) {
        print(
          "🔴 ITEM => "
              "product/itemId=${item.itemId}, "
              "lineItemId=${item.lineItemId}, "
              "quantity=${item.quantity}",
        );
      }

      print("🔴 ===============================");
      for (final item in items) {
        final qty = item.quantity ?? 0;

        if (item.lineItemId != null) {
          lineItemsPayload.add({
            "id": item.lineItemId,
            "quantity": qty, // qty = 0 → remove
          });
        } else if (item.itemId != null && qty > 0) {
          lineItemsPayload.add({"product_id": item.itemId, "quantity": qty});
        }
      }

      if (lineItemsPayload.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("⚠️ No valid items to update"),
            duration: Duration(seconds: 1),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final payload = {
        "line_items": lineItemsPayload,
        "meta_data": [
          if (_remarksController.text.trim().isNotEmpty)
            {"key": "kot_remarks", "value": _remarksController.text.trim()},
          {"key": "kot_remarks", "value": selectedReason},
        ],
      };

      // 4️⃣ Handle completed KOT
      final originalStatus = _selectedKot?.status ?? "processing";
      if (originalStatus == "completed") {
        await repo.updateOrderRaw(
          orderId: widget.orderId,
          kotOrderId: kotId,
          payload: {"status": "processing"},
        );
      }

      // 5️⃣ Update KOT
      final success = await repo.updateOrderRaw(
        orderId: widget.orderId,
        kotOrderId: kotId,
        payload: payload,
      );

      if (!success) throw Exception("Update failed");

      // 🔥 IMPORTANT: clear stale IDs for qty = 0
      final editedItems = _editedKotItems[_selectedKotId];
      if (editedItems != null) {
        for (final item in editedItems) {
          if ((item.quantity ?? 0) == 0) {
            item.lineItemId = null;
          }
        }
      }

      // 6️⃣ Restore status
      if (originalStatus == "completed") {
        await repo.updateOrderRaw(
          orderId: widget.orderId,
          kotOrderId: kotId,
          payload: {"status": "completed"},
        );
      }

      // 7️⃣ REFRESH FIRST
      await _refreshOrders();

      // 8️⃣ FETCH VOIDED AFTER REFRESH
      await _fetchVoidedItemsAfterUpdate(kotId);
// Get the freshly updated order
      final refreshedOrders = await _orderRepo.fetchOrders(widget.token);

      OrderlistModel? updatedOrder;

      try {
        updatedOrder = refreshedOrders.firstWhere(
              (o) => o.orderId == widget.orderId,
        );
      } catch (_) {
        updatedOrder = null;
      }

      if (!mounted) return;

      setState(() {
        _isUpdatingKot = false;
        _kotUpdated = true;
        _updatedOrder = updatedOrder;
        _modifiedAt = DateTime.now();
      });

// Show success popup
      if (updatedOrder != null && mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: _orderModifiedPopup(
                context,
                updatedOrder!,
              ),
            );
          },
        );
      }
    } catch (e) {
      print("❌ KOT Update Failed => $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Update failed: $e"),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _fetchVoidedItemsAfterUpdate(int kotId) async {
    print("🟡 [VOID FETCH] START");
    print("📌 KOT ID: $kotId");
    print("🔐 Token present: ${widget.token.isNotEmpty}");

    try {
      print("🌐 Calling fetchVoidedItems API...");

      final response = await _orderStatusRepo.fetchVoidedItems(
        kotOrderId: kotId,
        token: widget.token,
      );

      print("✅ API call success");
      print("📦 Voided items count: ${response.items.length}");

      if (!mounted) {
        print("⚠️ Widget not mounted, aborting UI update");
        return;
      }

      setState(() {
        _voidedItemsResponse = response;
      });

      print("🧾 Stored voided items in state");

      // if (response.items.isNotEmpty) {
      //   print("📢 Showing voided items dialog");
      //
      //   for (final item in response.items) {
      //     print(
      //       "🧾 Item: ${item.product}, "
      //           "Qty: ${item.origQty} → ${item.newQty}, "
      //           "Total: ${item.itemTotal}, "
      //           "Reason: ${item.remarks}",
      //     );
      //   }
      //
      //   _showVoidedItemsDialog(response.items);
      // } else {
      //   print("ℹ️ No voided items returned from API");
      // }

      print("🟢 [VOID FETCH] END SUCCESS");
    } catch (e, stackTrace) {
      print("❌ [VOID FETCH] FAILED");
      print("❌ Error: $e");
      print("📍 StackTrace:\n$stackTrace");
    }
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      // backgroundColor: const Color(0xFFF1F1F3),
        backgroundColor:
        isDark ? const Color(0xFF161A26) : const Color(0xFFF6F6F6),

        appBar: TopBar(
          token: widget.token,
          pin: widget.pin,
          userPermissions: _userPermissions,
          restaurantId: widget.restaurantId,
          restaurantName: widget.restaurantName,
          onPermissionsReceived: (p) => setState(() => _userPermissions = p),
        ),

        body: Stack(
            children: [
              FutureBuilder<List<OrderlistModel>>(
                future: _ordersFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final order = snapshot.data!.firstWhere(
                        (o) => o.orderId == widget.orderId,
                  );
                  if (!_netPayableInitialized) {
                    _fixedTotalTax = order.totalTax?.toDouble() ?? 0.0; //  LOCK TAX
                    _dynamicNetPayable = order.netPayable?.toDouble() ?? 0.0;
                    _netPayableInitialized = true;
                  }

                  final kots = order.kotOrders ?? [];

                  // Initialize default KOT
                  if (_selectedKotId == null && kots.isNotEmpty) {
                    _selectedKotId = kots.first.kotOrderId;
                    _selectedKot = kots.first;

                    // Populate left panel items for default KOT
                    _leftPanelItems =
                        (_selectedKot?.lineItems ?? []).map((item) {
                          final qty = item.quantity ?? 1;
                          final totalWoTax = item.totalWoTax ?? 0.0;

                          return LineItem(
                            lineItemId: item.lineItemId,
                            itemId: item.itemId,
                            name: item.name,
                            quantity: qty,
                            maxQty: qty,
                            totalWoTax: totalWoTax,
                            amount: item.amount,
                            unitPrice: qty > 0 ? totalWoTax / qty : 0.0, //  SAME LOGIC
                            modifiers: parseModifiers(item.modifiers),
                          );
                        }).toList();
                    if (_selectedKot != null) {
                      final kotId = _selectedKot!.kotOrderId!;

                      _editedKotItems.putIfAbsent(
                        kotId,
                            () =>
                            _selectedKot!.lineItems!.map((item) {
                              final qty = item.quantity ?? 1;
                              final totalWoTax = item.totalWoTax ?? 0.0;

                              return LineItem(
                                lineItemId: item.lineItemId,
                                itemId: item.itemId,
                                name: item.name,
                                quantity: qty,
                                maxQty: qty,
                                totalWoTax: totalWoTax,
                                amount: item.amount,
                                unitPrice: qty > 0 ? totalWoTax / qty : 0.0,
                                modifiers: parseModifiers(item.modifiers),
                              );
                            }).toList(),
                      );

                      // Initialize dynamic net payable for the right panel
                      // _dynamicNetPayable = _editedKotItems[kotId]!
                      //     .fold(0.0, (sum, i) => sum + (i.totalWoTax ?? 0));
                    }
                  }
                  int _getChangeCount(List<LineItem> items) {
                    return items.where((item) {
                      final originalQty = item.originalQuantity ?? item.quantity ?? 0;
                      final currentQty = item.quantity ?? 0;

                      return originalQty != currentQty;
                    }).length;
                  }
                  final editedItems = _editedKotItems[_selectedKotId] ?? [];

                  final changeCount = _getChangeCount(editedItems);
                  return Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const SizedBox(width: 10),
                              SizedBox(
                                width: 110, // button width
                                child:GestureDetector(
                                  onTap: () {
                                    Navigator.pop(context, _kotUpdated);
                                  },
                                  child: Container(
                                    width: 110,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 10,
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
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: const [
                                        Icon(
                                          Icons.arrow_back,
                                          size: 20,
                                          color: Colors.white,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          "Edit Order",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 16),

                              // 🧾 Order ID label
                              Text(
                                "Order ID :",
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color:
                                  isDark
                                      ? Colors.white70
                                      : const Color(0xFF7A7A7A),
                                ),
                              ),

                              const SizedBox(width: 6),

                              //  Order ID value
                              Text(
                                "${widget.orderId}",
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color:
                                  isDark
                                      ? Colors.white
                                      : const Color(0xFF4C5F7D),
                                ),
                              ),
                              const Spacer(),
                              if (kots.isNotEmpty)
                                Container(
                                  height: 40,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                    isDark
                                        ? const Color(0xFF2A2F3D)
                                        : const Color(0xFF125BCE),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<int>(
                                      value: _selectedKotId,
                                      icon: Icon(
                                        Icons.keyboard_arrow_down,
                                        color: Colors.white,
                                      ),
                                      dropdownColor:
                                      isDark
                                          ? const Color(0xFF2A2F3D)
                                          : const Color(0xFF125BCE),
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: Colors.white,
                                      ),
                                      items:
                                      kots.map((kot) {
                                        return DropdownMenuItem<int>(
                                          value: kot.kotOrderId,
                                          child: Text(
                                            "${kot.kotNumber}",
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(color: Colors.white),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        if (value != null)
                                          _onKotSelected(value, kots);
                                      },
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 12),
                            ],
                          ),


                          const SizedBox(height: 10),

                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF202433)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: isDark
                                        ? Colors.black45
                                        : Colors.black12,
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(width: 42),

                                  // const SizedBox(height: 10),

                                  // Panels
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Flexible(
                                          flex: 1,
                                          child: Container(
                                            margin: const EdgeInsets.only(
                                              left: 2,
                                              right: 2,
                                              top: 0,
                                              bottom: 8,
                                            ),
                                            // decoration: BoxDecoration(
                                            //   color:
                                            //       isDark
                                            //           ? const Color(0xFF2A2F3D)
                                            //           : const Color(0xFFF6F6F6),
                                            //   borderRadius: BorderRadius.circular(12),
                                            // ),
                                            child: Stack(
                                              children: [
                                                // Left panel content
                                                Padding(
                                                  padding: const EdgeInsets.only(
                                                    top: 0,
                                                    left: 0,
                                                    right: 0,
                                                    bottom:
                                                    20, // leave space for overlay summary
                                                  ),
                                                  child:
                                                  _selectedKot == null
                                                      ? Center(
                                                    child: Text(
                                                      "Select a KOT",
                                                      style: theme
                                                          .textTheme
                                                          .bodyLarge
                                                          ?.copyWith(
                                                        color:
                                                        isDark
                                                            ? Colors.white70
                                                            : Colors
                                                            .black87,
                                                      ),
                                                    ),
                                                  )
                                                      : _buildLeftPanel(
                                                    order,
                                                    kots,
                                                  ), // your existing left panel content
                                                ),

                                                // Overlay summary inside the container
                                                if (_selectedKot != null)
                                                  Positioned(
                                                    left: 8,
                                                    right: 8,
                                                    bottom: 0,
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(
                                                        vertical: 0,
                                                        horizontal: 0,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        border: Border.all(
                                                          color: const Color(0xFFE2E8F0),
                                                          width: 1,
                                                        ),
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                      child: _summaryRow(
                                                        "KOT #${_selectedKot?.kotOrderId ?? '-'} - Amount",
                                                        "$_currency${(_selectedKot?.lineItems ?? []).fold<double>(
                                                          0.0,
                                                              (sum, item) => sum + (item.totalWoTax ?? 0),
                                                        ).toStringAsFixed(2)}",
                                                        bold: true,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),

                                        const SizedBox(width: 0),
                                        Flexible(
                                          flex: 1,
                                          child: Container(
                                            margin: const EdgeInsets.only(
                                              left: 2,
                                              right: 2,
                                              top: 0,
                                              bottom: 8,
                                            ),
                                            // decoration: BoxDecoration(
                                            //   color:
                                            //       isDark
                                            //           ? const Color(0xFF2A2F3D)
                                            //           : const Color(0xFFF6F6F6),
                                            //   borderRadius: BorderRadius.circular(12),
                                            // ),
                                            child: Stack(
                                              children: [
                                                // KOT Card content
                                                Padding(
                                                  padding: const EdgeInsets.only(
                                                    top: 8,
                                                    left: 12,
                                                    right: 12,
                                                    bottom:
                                                    30, // leave space for overlay summary inside the container
                                                  ),
                                                  child:
                                                  _selectedKot == null
                                                      ? const Center(
                                                    child: Text("Select a KOT"),
                                                  )
                                                      : buildSelectedKotCard(
                                                    _selectedKot!,
                                                  ),
                                                ),

                                                // Overlay summary row inside the container
                                                if (_selectedKot != null)
                                                  Positioned(
                                                    left: 10,
                                                    right: 10,
                                                    bottom: 0,
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(
                                                        vertical: 0,
                                                        horizontal: 0,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.transparent,
                                                        border: Border.all(
                                                          color: const Color(0xFFE2E8F0),
                                                          width: 1,
                                                        ),
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                      child: _summaryRow(
                                                        "KOT #${_selectedKot?.kotOrderId ?? '-'} - Updated Amount",
                                                        "$_currency${(_editedKotItems[_selectedKotId] ?? []).fold<double>(
                                                          0.0,
                                                              (sum, i) => sum + (i.totalWoTax ?? 0),
                                                        ).toStringAsFixed(2)}",
                                                        bold: true,
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

                                  // const SizedBox(height: 10),
                                  // _infoRow(
                                  //   "Net Payable",
                                  //   "₹${order.netPayable ?? 0}",
                                  //   bold: true,
                                  // ),
                                  // ============================================================
// BOTTOM SUMMARY / ACTION BAR
// ============================================================
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF1E3A5F)
                                          : const Color(0xFF1E3A5F),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: const Color(0xFFE2E8F0),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        final isSmall = constraints.maxWidth < 900;

                                        // --------------------------------------------------------
                                        // SMALL SCREEN
                                        // --------------------------------------------------------
                                        if (isSmall) {
                                          return Column(
                                            crossAxisAlignment: CrossAxisAlignment.stretch,
                                            children: [
                                              // Previous + Updated Total
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: _bottomAmountItem(
                                                      title: "PREVIOUS TOTAL",
                                                      amount:
                                                      "$_currency${(order.orderPrevTotal ?? 0).toStringAsFixed(2)}",
                                                      amountColor: Colors.white,
                                                    ),
                                                  ),

                                                  const Padding(
                                                    padding: EdgeInsets.symmetric(horizontal: 12),
                                                    child: Text(
                                                      "→",
                                                      style: TextStyle(
                                                        color: Color(0xFF7F8EA3),
                                                        fontSize: 28,
                                                      ),
                                                    ),
                                                  ),

                                                  Expanded(
                                                    child: _bottomAmountItem(
                                                      title: "UPDATED TOTAL",
                                                      amount:
                                                      "$_currency${_dynamicNetPayable.toStringAsFixed(2)}",
                                                      amountColor: const Color(0xFF86EFAC),
                                                    ),
                                                  ),
                                                ],
                                              ),

                                              const SizedBox(height: 14),

                                              // Reason
                                              if (kot_remarks.isNotEmpty)
                                                _reasonDropdown(),

                                              if (kot_remarks.isNotEmpty)
                                                const SizedBox(height: 14),

                                              // Success message
                                              // if (_isUpdatingKot || _updateMessage != null)
                                              //   Padding(
                                              //     padding: const EdgeInsets.only(bottom: 14),
                                              //     child: _updateStatus(),
                                              //   ),

                                              // Buttons
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: _resetButton(),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: _updateButton(),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          );
                                        }

                                        // --------------------------------------------------------
                                        // LARGE SCREEN
                                        // --------------------------------------------------------
                                        return Row(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            // =====================================================
                                            // PREVIOUS TOTAL
                                            // =====================================================
                                            _bottomAmountItem(
                                              title: "PREVIOUS TOTAL",
                                              amount:
                                              "$_currency${(order.orderPrevTotal ?? 0).toStringAsFixed(2)}",
                                              amountColor: Colors.white,
                                            ),

                                            const SizedBox(width: 25),

                                            // =====================================================
                                            // ARROW
                                            // =====================================================
                                            const Text(
                                              "→",
                                              style: TextStyle(
                                                color: Color(0xFF7F8EA3),
                                                fontSize: 30,
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),

                                            const SizedBox(width: 45),

                                            // =====================================================
                                            // UPDATED TOTAL
                                            // =====================================================
                                            _bottomAmountItem(
                                              title: "UPDATED TOTAL",
                                              amount:
                                              "$_currency${_dynamicNetPayable.toStringAsFixed(2)}",
                                              amountColor: const Color(0xFF86EFAC),
                                            ),

                                            const SizedBox(width: 15),

                                            // =====================================================
                                            // CHANGE COUNT
                                            // =====================================================

                                            Container(
                                              height: 40,
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 18,
                                                vertical: 8,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF2D4E75),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              alignment: Alignment.center,
                                              child: Text(
                                                '$changeCount ${changeCount == 1 ? 'change' : 'changes'}',
                                                style: const TextStyle(
                                                  color: Color(0xFF94A3B8),
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),

                                            const SizedBox(width: 10),

                                            // =====================================================
                                            // REASON
                                            // =====================================================
                                            if (kot_remarks.isNotEmpty)
                                              Expanded(
                                                child: _reasonDropdown(),
                                              ),

                                            const SizedBox(width: 20),

                                            // =====================================================
                                            // SUCCESS / UPDATING MESSAGE
                                            // =====================================================
                                            // if (_isUpdatingKot || _updateMessage != null)
                                            //   Flexible(
                                            //     child: _updateStatus(),
                                            //   ),

                                            const SizedBox(width: 60),

                                            // =====================================================
                                            // RESET
                                            // =====================================================
                                            SizedBox(
                                              height: 40,
                                              child: OutlinedButton(
                                                onPressed: _isUpdatingKot
                                                    ? null
                                                    : () {
                                                  setState(() {
                                                    selectedReason = null;
                                                  });
                                                },
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: const Color(0xFFCBD5E1),
                                                  side: const BorderSide(
                                                    color: Color(0xFF8BA3C4),
                                                    width: 1.6,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 24,
                                                  ),
                                                ),
                                                child: const Text(
                                                  "Reset",
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ),

                                            const SizedBox(width: 10),

                                            // =====================================================
                                            // UPDATE KOT
                                            // =====================================================
                                            _updateButton(),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                  //
                                  // Row(
                                  //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  //   children: [
                                  //     const SizedBox(width: 15),
                                  //
                                  //     Expanded(
                                  //       child: _infoRow(
                                  //         "Order Net Payable",
                                  //         "$_currency${(order.orderPrevTotal ?? 0).toStringAsFixed(2)}",
                                  //         bold: true,
                                  //         labelFontWeight: FontWeight.w600,
                                  //         valueFontWeight: FontWeight.w600,
                                  //       ),
                                  //     ),
                                  //     const SizedBox(width: 34),
                                  //
                                  //     Expanded(
                                  //       child: _infoRow(
                                  //         "Order Updated Net Payable",
                                  //         "$_currency${_dynamicNetPayable.toStringAsFixed(2)}",
                                  //         bold: true,
                                  //         labelFontWeight: FontWeight.w700,
                                  //         valueFontWeight: FontWeight.w700,
                                  //       ),
                                  //     ),
                                  //   ],
                                  // ),
                                  //
                                  // Row(
                                  //   crossAxisAlignment: CrossAxisAlignment.center,
                                  //   children: [
                                  //     //  Enter Reason
                                  //     if (kot_remarks.isNotEmpty) ...[
                                  //       const SizedBox(width: 10),
                                  //       Container(
                                  //         padding: const EdgeInsets.fromLTRB(24, 8, 8, 8),
                                  //         decoration: BoxDecoration(
                                  //           color:
                                  //               isDark
                                  //                   ? const Color(0xFF2A2F3D)
                                  //                   : const Color(0xFFE5EFFF),
                                  //           borderRadius: BorderRadius.circular(8),
                                  //           border: Border.all(
                                  //             color:
                                  //                 isDark
                                  //                     ? theme.dividerColor
                                  //                     : const Color(0xFFE5EFFF),
                                  //           ),
                                  //         ),
                                  //         child: Row(
                                  //           children: [
                                  //             Text(
                                  //               "Enter Reason:",
                                  //               style: theme.textTheme.bodyLarge?.copyWith(
                                  //                 fontSize: 16,
                                  //                 fontWeight: FontWeight.w600,
                                  //                 color:
                                  //                     isDark
                                  //                         ? Colors.white
                                  //                         : const Color(0xFF393A3B),
                                  //               ),
                                  //             ),
                                  //             const SizedBox(width: 20),
                                  //
                                  //             SizedBox(
                                  //               width: 430,
                                  //               height: 30,
                                  //               child: Container(
                                  //                 padding: const EdgeInsets.symmetric(
                                  //                   horizontal: 12,
                                  //                 ),
                                  //                 decoration: BoxDecoration(
                                  //                   color: theme.cardColor,
                                  //                   borderRadius: BorderRadius.circular(6),
                                  //                   border: Border.all(
                                  //                     color: theme.dividerColor,
                                  //                   ),
                                  //                 ),
                                  //                 child: DropdownButtonHideUnderline(
                                  //                   child: DropdownButton<String>(
                                  //                     value: selectedReason,
                                  //                     isExpanded: true,
                                  //                     dropdownColor: theme.cardColor,
                                  //                     icon: Icon(
                                  //                       Icons.keyboard_arrow_down,
                                  //                       color: theme.iconTheme.color,
                                  //                     ),
                                  //                     hint: Text(
                                  //                       "Select Reason",
                                  //                       style: theme.textTheme.bodySmall
                                  //                           ?.copyWith(
                                  //                             fontSize: 12,
                                  //                             color:
                                  //                                 isDark
                                  //                                     ? Colors.white54
                                  //                                     : const Color(
                                  //                                       0xFF9E9E9E,
                                  //                                     ),
                                  //                           ),
                                  //                     ),
                                  //                     style: theme.textTheme.bodySmall
                                  //                         ?.copyWith(
                                  //                           fontSize: 12,
                                  //                           color:
                                  //                               isDark
                                  //                                   ? Colors.white
                                  //                                   : const Color(
                                  //                                     0xFF212121,
                                  //                                   ),
                                  //                         ),
                                  //                     items:
                                  //                         kot_remarks.map((reason) {
                                  //                           return DropdownMenuItem<String>(
                                  //                             value: reason,
                                  //                             child: Text(
                                  //                               reason,
                                  //                               style: theme
                                  //                                   .textTheme
                                  //                                   .bodySmall
                                  //                                   ?.copyWith(
                                  //                                     fontSize: 12,
                                  //                                     color:
                                  //                                         isDark
                                  //                                             ? Colors.white
                                  //                                             : const Color(
                                  //                                               0xFF212121,
                                  //                                             ),
                                  //                                   ),
                                  //                             ),
                                  //                           );
                                  //                         }).toList(),
                                  //                     onChanged: (value) {
                                  //                       setState(() {
                                  //                         selectedReason = value;
                                  //                       });
                                  //                     },
                                  //                   ),
                                  //                 ),
                                  //               ),
                                  //             ),
                                  //           ],
                                  //         ),
                                  //       ),
                                  //     ],
                                  //
                                  //     //  Spacer only if no success message
                                  //     if (_updateMessage == null) const Spacer(),
                                  //
                                  //     // Success message (Flexible)
                                  //     if (_isUpdatingKot || _updateMessage != null) ...[
                                  //       const SizedBox(width: 12),
                                  //
                                  //       Flexible(
                                  //         child: Row(
                                  //           children: [
                                  //             if (_isUpdatingKot)
                                  //               const SizedBox(
                                  //                 width: 18,
                                  //                 height: 18,
                                  //                 child: CircularProgressIndicator(
                                  //                   strokeWidth: 2,
                                  //                 ),
                                  //               )
                                  //             else
                                  //               Image.asset(
                                  //                 "assets/success_tick.png",
                                  //                 width: 20,
                                  //                 height: 20,
                                  //               ),
                                  //
                                  //             const SizedBox(width: 6),
                                  //
                                  //             Flexible(
                                  //               child: Text(
                                  //                 _isUpdatingKot
                                  //                     ? "Updating KOT, please wait..."
                                  //                     : _updateMessage!,
                                  //                 style: Theme.of(
                                  //                   context,
                                  //                 ).textTheme.bodyMedium?.copyWith(
                                  //                   color:
                                  //                       _isUpdatingKot
                                  //                           ? Colors.orange
                                  //                           : Colors.green,
                                  //                   fontWeight: FontWeight.w600,
                                  //                 ),
                                  //                 overflow: TextOverflow.ellipsis,
                                  //               ),
                                  //             ),
                                  //           ],
                                  //         ),
                                  //       ),
                                  //
                                  //       const SizedBox(width: 12),
                                  //     ],
                                  //
                                  //     //  Update KOT button
                                  //     ElevatedButton(
                                  //       onPressed: _isUpdatingKot ? null : _updateKot,
                                  //       style: ElevatedButton.styleFrom(
                                  //         backgroundColor: const Color(0xFF4C5F7D),
                                  //         padding: const EdgeInsets.symmetric(
                                  //           horizontal: 26,
                                  //           vertical: 18,
                                  //         ),
                                  //         shape: RoundedRectangleBorder(
                                  //           borderRadius: BorderRadius.circular(8),
                                  //         ),
                                  //       ),
                                  //       child:
                                  //           _isUpdatingKot
                                  //               ? const SizedBox(
                                  //                 width: 18,
                                  //                 height: 18,
                                  //                 child: CircularProgressIndicator(
                                  //                   strokeWidth: 2,
                                  //                   color: Colors.white,
                                  //                 ),
                                  //               )
                                  //               : const Text(
                                  //                 "Update KOT",
                                  //                 style: TextStyle(
                                  //                   fontSize: 14, //  SAME font size
                                  //                   fontWeight: FontWeight.w600,
                                  //                   color: Colors.white,
                                  //                 ),
                                  //               ),
                                  //     ),
                                  //
                                  //     const SizedBox(width: 10),
                                  //   ],
                                  // ),
                                ],
                              ),
                            ),
                          ),
                        ]),
                  );
                },

              ),
              if (_isUpdatingKot || _updateMessage != null)
                Positioned(
                  top: 12,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: _updateStatus(),
                  ),
                ),
              // BOTTOM NAV
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
            ]));
  }
  Widget _bottomAmountItem({
    required String title,
    required String amount,
    required Color amountColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.66,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          amount,
          style: TextStyle(
            color: amountColor,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
  Widget _reasonDropdown() {
    return Container(
      height: 40,
      padding: const EdgeInsets.only(
        left: 20,
        right: 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFE5EFFF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Text(
            "Reason for modification",
            style: TextStyle(
              color: Color(0xFF39393A),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(width: 20),

          Expanded(
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFD1D5DB),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedReason,
                  isExpanded: true,
                  dropdownColor: Colors.white,

                  hint: const Text(
                    "Select Reason",
                    style: TextStyle(
                      color: Color(0xFF9E9E9E),
                      fontSize: 13,
                    ),
                  ),

                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Color(0xFF64748B),
                  ),

                  style: const TextStyle(
                    color: Color(0xFF212121),
                    fontSize: 13,
                  ),

                  items: kot_remarks.map((reason) {
                    return DropdownMenuItem<String>(
                      value: reason,
                      child: Text(
                        reason,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),

                  onChanged: (value) {
                    setState(() {
                      selectedReason = value;
                    });
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _updateStatus() {
    final bool isUpdating = _isUpdatingKot;

    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 420,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isUpdating
              ? const Color(0xFFFFFBEB)
              : const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isUpdating
                ? const Color(0xFFF59E0B)
                : const Color(0xFF86EFAC),
            width: 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isUpdating)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFFF59E0B),
                ),
              )
            else
              Image.asset(
                "assets/success_tick.png",
                width: 20,
                height: 20,
              ),

            const SizedBox(width: 9),

            Flexible(
              child: Text(
                isUpdating
                    ? "Updating KOT, please wait..."
                    : (_updateMessage ?? ""),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isUpdating
                      ? const Color(0xFFB45309)
                      : const Color(0xFF15803D),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _updateButton() {
    final bool isReasonSelected =
        selectedReason != null &&
            selectedReason!.trim().isNotEmpty;

    return SizedBox(
      width: 145, // fixed width
      height: 40,
      child: ElevatedButton(
        onPressed: (_isUpdatingKot || !isReasonSelected)
            ? null
            : _updateKot,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3B6FD4),
          disabledBackgroundColor: const Color(0xFFD1D5DB),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: _isUpdatingKot
            ? const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Update KOT",
              style: TextStyle(
                color: isReasonSelected
                    ? Colors.white
                    : const Color(0xFF9CA3AF),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              "→",
              style: TextStyle(
                color: isReasonSelected
                    ? Colors.white
                    : const Color(0xFF9CA3AF),
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _resetButton() {
    return OutlinedButton(
      onPressed: _isUpdatingKot
          ? null
          : () {
        if (_selectedKotId == null) {
          return;
        }

        // Get the original KOT items.
        final originalItems =
            _selectedKot?.lineItems ?? [];

        // Create a fresh editable list ONLY for
        // the right panel.
        final resetItems = originalItems.map((item) {
          final qty = item.quantity ?? 0;
          final unitPrice =
          (item.itemPrice ?? 0).toDouble();

          return LineItem(
            lineItemId: item.lineItemId,
            itemId: item.itemId,
            name: item.name,

            quantity: qty,
            originalQuantity:
            item.originalQuantity ?? qty,
            maxQty: qty,

            itemPrice: unitPrice,
            unitPrice: unitPrice,

            amount: item.amount,
            totalWoTax: item.totalWoTax,
            modifierAmount: item.modifierAmount,
            tax: item.tax,
            total: item.total,

            modifiers:
            parseModifiers(item.modifiers),

            kotRemarks: item.kotRemarks,
            voidedAt: item.voidedAt,
          );
        }).toList();

        setState(() {
          // ONLY update the RIGHT PANEL.
          _editedKotItems[_selectedKotId!] =
              resetItems;

          // Reset Updated Amount.
          _dynamicNetPayable =
              resetItems.fold<double>(
                0.0,
                    (sum, item) =>
                sum +
                    (item.totalWoTax ?? 0)
                        .toDouble(),
              );

          // Clear change-related state.
          selectedReason = null;
          _updateMessage = null;
        });
      },

      style: OutlinedButton.styleFrom(
        foregroundColor:
        const Color(0xFFCBD5E1),

        side: const BorderSide(
          color: Color(0xFF8BA3C4),
          width: 1.6,
        ),

        minimumSize: const Size(
          double.infinity,
          48,
        ),

        shape: RoundedRectangleBorder(
          borderRadius:
          BorderRadius.circular(10),
        ),
      ),

      child: const Text(
        "Reset",
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
  // =========================================================
  // LEFT PANEL (Order info + KOT selector) - STATIC VIEW
  // =========================================================
  Widget _buildLeftPanel(
      OrderlistModel order,
      List<KotOrder> kots,
      ) {
    final kot = _selectedKot;

    final theme = Theme.of(context);
    final bool isDark =
        theme.brightness == Brightness.dark;

    // ------------------------------------------------------------
    // COLORS
    // ------------------------------------------------------------

    final Color panelBackground =
    isDark
        ? const Color(0xFF202433)
        : Colors.white;

    final Color headerBackground =
    isDark
        ? const Color(0xFF202433)
        : const Color(0xFFF8FAFC);

    final Color tableHeaderBackground =
    isDark
        ? const Color(0xFF374151)
        : const Color(0xFF344054);

    final Color primaryText =
    isDark
        ? Colors.white
        : const Color(0xFF172033);

    final Color secondaryText =
    isDark
        ? Colors.white54
        : const Color(0xFF70809A);

    final Color borderColor =
    isDark
        ? const Color(0xFF3A4050)
        : const Color(0xFFD8DEE8);

    final Color rowBorderColor =
    isDark
        ? const Color(0xFF303644)
        : const Color(0xFFEDF0F4);

    // ------------------------------------------------------------
    // ITEMS
    // ------------------------------------------------------------

    final allItems =
        kot?.lineItems ?? [];

    final normalItems =
    allItems.where((item) {
      return _getVoidedItemByItemId(
        item.itemId,
      ) ==
          null;
    }).toList();

    final voidedItems =
        _currentVoidedItems;

    // ------------------------------------------------------------
    // LOAD VOIDED ITEMS
    // ------------------------------------------------------------

    if (kot != null) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) {
        if (mounted) {
          _loadVoidedItemsForKot(kot);
        }
      });
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(8),
      clipBehavior: Clip.antiAlias,

      decoration: BoxDecoration(
        color: panelBackground,

        border: Border.all(
          color: borderColor,
          width: 1,
        ),

        borderRadius:
        BorderRadius.circular(6),
      ),

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [

          // ======================================================
          // ORIGINAL ORDER HEADER
          // ======================================================

          Container(
            height: 44,

            padding:
            const EdgeInsets.symmetric(
              horizontal: 12,
            ),

            color: headerBackground,

            child: Row(
              crossAxisAlignment:
              CrossAxisAlignment.center,

              children: [

                // ------------------------------------------------
                // ORIGINAL ORDER
                // ------------------------------------------------

                Text(
                  "ORIGINAL ORDER",

                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                    FontWeight.w700,
                    letterSpacing: 0.25,
                    color: isDark
                        ? Colors.white70
                        : const Color(0xFF526174),
                  ),
                ),

                const Spacer(),

                // ------------------------------------------------
                // KOT INFORMATION
                // ------------------------------------------------

                Flexible(
                  child: Text(
                    "KOT: #${kot?.kotOrderId ?? '-'} · Current order before changes",

                    maxLines: 1,
                    overflow:
                    TextOverflow.ellipsis,

                    textAlign:
                    TextAlign.right,

                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                      FontWeight.w400,
                      color: isDark
                          ? Colors.white38
                          : const Color(0xFF9AA8BA),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ======================================================
          // TABLE HEADER
          // ======================================================

          Container(
            height: 38,

            padding:
            const EdgeInsets.symmetric(
              horizontal: 10,
            ),

            color: tableHeaderBackground,

            child: Row(
              children: [

                // #
                SizedBox(
                  width: 40,
                  child: _leftHeaderText("#"),
                ),

                // ITEM NAME
                Expanded(
                  flex: 5,
                  child:
                  _leftHeaderText(
                    "Item Name",
                  ),
                ),

                // QUANTITY
                SizedBox(
                  width: 105,
                  child:
                  _leftHeaderText(
                    "Quantity",
                  ),
                ),

                // AMOUNT
                SizedBox(
                  width: 95,
                  child:
                  _leftHeaderText(
                    "Amount",
                    right: true,
                  ),
                ),
              ],
            ),
          ),

          // ======================================================
          // ITEM LIST
          // ======================================================

          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,

              itemCount:
              normalItems.length +
                  voidedItems.length,

              itemBuilder:
                  (context, index) {

                // ==================================================
                // NORMAL ITEM
                // ==================================================

                if (index <
                    normalItems.length) {
                  final item =
                  normalItems[index];

                  return _buildNormalRowUI(
                    item,
                    index,
                  );
                }

                // ==================================================
                // VOIDED ITEM
                // ==================================================

                final voidedIndex =
                    index -
                        normalItems.length;

                return _buildVoidedRowUI(
                  voidedItems[
                  voidedIndex],
                  index,
                );
              },
            ),
          ),

          // ======================================================
          // BOTTOM AMOUNT
          // ======================================================

          // Container(
          //   height: 48,
          //
          //   padding:
          //   const EdgeInsets.symmetric(
          //     horizontal: 12,
          //   ),
          //
          //   decoration: BoxDecoration(
          //     color: isDark
          //         ? const Color(0xFF202433)
          //         : const Color(0xFFF8FAFC),
          //
          //     border: Border(
          //       top: BorderSide(
          //         color: borderColor,
          //         width: 1,
          //       ),
          //     ),
          //   ),
          //
          //   child: Row(
          //     crossAxisAlignment:
          //     CrossAxisAlignment.center,
          //
          //     children: [
          //
          //       Expanded(
          //         child: Text(
          //           "KOT #${kot?.kotOrderId ?? '-'} — Amount",
          //
          //           style: TextStyle(
          //             fontSize: 14,
          //             fontWeight:
          //             FontWeight.w700,
          //             color: isDark
          //                 ? Colors.white70
          //                 : const Color(0xFF526174),
          //           ),
          //         ),
          //       ),
          //
          //       Text(
          //         "$_currency${(kot?.lineItems ?? []).fold<double>(
          //           0.0,
          //               (sum, item) =>
          //           sum +
          //               (item.totalWoTax ?? 0),
          //         ).toStringAsFixed(2)}",
          //
          //         style: TextStyle(
          //           fontSize: 14,
          //           fontWeight:
          //           FontWeight.w700,
          //           color: isDark
          //               ? Colors.white
          //               : const Color(0xFF173B6D),
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }
  Widget _leftHeaderText(
      String text, {
        bool center = false,
        bool right = false,
      }) {
    return Text(
      text,

      maxLines: 1,
      overflow: TextOverflow.ellipsis,

      textAlign: right
          ? TextAlign.right
          : center
          ? TextAlign.center
          : TextAlign.left,

      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    );
  }
  Widget _buildNormalRowUI(
      LineItem item,
      int index,
      ) {
    final theme = Theme.of(context);
    final isDark =
        theme.brightness == Brightness.dark;

    final modifiers =
    parseModifiers(item.modifiers);

    // ============================================================
    // COLORS
    // ============================================================

    final Color rowColor =
    index.isEven
        ? (isDark
        ? const Color(0xFF202433)
        : Colors.white)
        : (isDark
        ? const Color(0xFF252A36)
        : const Color(0xFFF8FAFC));

    final Color borderColor =
    isDark
        ? const Color(0xFF303644)
        : const Color(0xFFEDF0F4);

    final Color numberColor =
    isDark
        ? Colors.white38
        : const Color(0xFF8A9AB5);

    final Color itemColor =
    isDark
        ? Colors.white
        : const Color(0xFF172033);

    final Color quantityColor =
    isDark
        ? Colors.white54
        : const Color(0xFF70809A);

    final Color amountColor =
    isDark
        ? Colors.white
        : const Color(0xFF172033);

    return Container(
      constraints: BoxConstraints(
        minHeight:
        modifiers.isNotEmpty ? 44 : 40,
      ),

      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),

      decoration: BoxDecoration(
        color: rowColor,

        border: Border(
          bottom: BorderSide(
            color: borderColor,
            width: 0.7,
          ),
        ),
      ),

      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.center,

        children: [

          // ======================================================
          // #
          // ======================================================

          SizedBox(
            width: 40,

            child: Text(
              "${index + 1}",

              style: TextStyle(
                fontSize: 11,
                fontWeight:
                FontWeight.w400,
                color: numberColor,
              ),
            ),
          ),

          // ======================================================
          // ITEM NAME + MODIFIERS
          // ======================================================

          Expanded(
            flex: 5,

            child: Padding(
              padding:
              const EdgeInsets.only(
                right: 8,
              ),

              child: Column(
                mainAxisAlignment:
                MainAxisAlignment.center,

                crossAxisAlignment:
                CrossAxisAlignment.start,

                children: [

                  Text(
                    item.name ?? "-",

                    maxLines: 1,
                    overflow:
                    TextOverflow.ellipsis,

                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                      FontWeight.w500,
                      color: itemColor,
                    ),
                  ),

                  if (modifiers.isNotEmpty)
                    Padding(
                      padding:
                      const EdgeInsets.only(
                        top: 1,
                      ),

                      child: Text(
                        modifiers.join(", "),

                        maxLines: 1,
                        overflow:
                        TextOverflow.ellipsis,

                        style: TextStyle(
                          fontSize: 9,
                          fontWeight:
                          FontWeight.w400,
                          color: isDark
                              ? const Color(
                            0xFF72A7F0,
                          )
                              : const Color(
                            0xFF5276C7,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ======================================================
          // QUANTITY
          // ======================================================

          SizedBox(
            width: 105,

            child: Text(
              "${item.originalQuantity ?? 0} × ${(item.itemPrice ?? 0).toStringAsFixed(0)}",

              maxLines: 1,
              overflow:
              TextOverflow.ellipsis,

              style: TextStyle(
                fontSize: 11,
                fontWeight:
                FontWeight.w400,
                color: quantityColor,
              ),
            ),
          ),

          // ======================================================
          // SMALL GAP
          // ======================================================

          const SizedBox(
            width: 10,
          ),

          // ======================================================
          // AMOUNT
          // ======================================================

          SizedBox(
            width: 85,

            child: Text(
              "$_currency${(item.totalWoTax ?? 0).toStringAsFixed(2)}",

              maxLines: 1,
              overflow:
              TextOverflow.ellipsis,

              textAlign:
              TextAlign.right,

              style: TextStyle(
                fontSize: 12,
                fontWeight:
                FontWeight.w700,
                color: amountColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoidedRowUI(
      VoidedItem item,
      int index,
      ) {
    final theme = Theme.of(context);
    final bool isDark =
        theme.brightness == Brightness.dark;

    // ============================================================
    // VOIDED COLORS
    // ============================================================

    final Color voidText =
    isDark
        ? Colors.white38
        : const Color(0xFF9AA3AF);

    final Color voidBackground =
    isDark
        ? const Color(0xFF2A2930)
        : const Color(0xFFF2F2F2);

    final Color voidBorder =
    isDark
        ? const Color(0xFF383640)
        : const Color(0xFFE5E7EB);

    final Color deletedColor =
    isDark
        ? const Color(0xFFFF7777)
        : const Color(0xFFD64545);

    return Container(
      constraints: const BoxConstraints(
        minHeight: 42,
      ),

      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),

      decoration: BoxDecoration(
        color: voidBackground,

        border: Border(
          bottom: BorderSide(
            color: voidBorder,
            width: 0.7,
          ),
        ),
      ),

      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.center,

        children: [

          // ======================================================
          // #
          // ======================================================

          SizedBox(
            width: 40,
            child: Text(
              "${index + 1}",
              style: TextStyle(
                fontSize: 11,
                fontWeight:
                FontWeight.w400,
                color: voidText,
              ),
            ),
          ),

          // ======================================================
          // ITEM NAME + DELETED
          // ======================================================

          Expanded(
            flex: 5,
            child: Padding(
              padding:
              const EdgeInsets.only(
                right: 8,
              ),
              child: Column(
                mainAxisAlignment:
                MainAxisAlignment.center,
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [

                  Text(
                    item.product,

                    maxLines: 1,
                    overflow:
                    TextOverflow.ellipsis,

                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                      FontWeight.w500,
                      color: voidText,
                    ),
                  ),

                  const SizedBox(height: 1),

                  Text(
                    "Item Deleted",

                    maxLines: 1,

                    style: TextStyle(
                      fontSize: 9,
                      fontWeight:
                      FontWeight.w600,
                      color: deletedColor,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ======================================================
          // QUANTITY
          // ======================================================

          SizedBox(
            width: 105,
            child: Text(
              "${item.origQty} → ${item.newQty}",

              maxLines: 1,
              overflow:
              TextOverflow.ellipsis,

              style: TextStyle(
                fontSize: 11,
                fontWeight:
                FontWeight.w400,
                color: voidText,
              ),
            ),
          ),

          // ======================================================
          // GAP
          // ======================================================

          const SizedBox(
            width: 10,
          ),

          // ======================================================
          // AMOUNT
          // ======================================================

          SizedBox(
            width: 85,
            child: Text(
              "$_currency${item.itemTotal.toStringAsFixed(2)}",

              maxLines: 1,
              overflow:
              TextOverflow.ellipsis,

              textAlign:
              TextAlign.right,

              style: TextStyle(
                fontSize: 12,
                fontWeight:
                FontWeight.w600,
                color: voidText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
      String label,
      String value, {
        bool bold = false,
        Color? labelColor,
        Color? valueColor,
        FontWeight labelFontWeight = FontWeight.normal,
        FontWeight valueFontWeight = FontWeight.normal,
      }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
      child: Row(
        children: [
          const SizedBox(width: 20),

          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: labelFontWeight,
              fontSize: 14,
              color: labelColor ?? (isDark ? Colors.white70 : Colors.black87),
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: valueFontWeight,
                fontSize: 16,
                color: valueColor ?? (isDark ? Colors.white : Colors.black87),
              ),
            ),
          ),

          const SizedBox(width: 65),
        ],
      ),
    );
  }

  // =========================================================
  // RIGHT PANEL (Editable KOT)
  Widget buildSelectedKotCard(KotOrder kot) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Use the editable copy
    final items =
        _editedKotItems[_selectedKotId] ?? [];

    return StatefulBuilder(
      builder: (context, setInnerState) {
        return Container(
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF202433)
                : Colors.white,

            borderRadius:
            BorderRadius.circular(6),

            border: Border.all(
              color: isDark
                  ? const Color(0xFF3A4050)
                  : const Color(0xFFD8DEE8),
              width: 1,
            ),
          ),

          clipBehavior:
          Clip.antiAlias,

          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,

            children: [

              // ======================================================
              // PROPOSED CHANGES HEADER
              // ======================================================

              Container(
                height: 42,

                padding:
                const EdgeInsets.symmetric(
                  horizontal: 12,
                ),

                color: isDark
                    ? const Color(0xFF202433)
                    : const Color(0xFFF8FAFC),

                child: Row(
                  crossAxisAlignment:
                  CrossAxisAlignment.center,

                  children: [

                    Text(
                      "PROPOSED CHANGES",

                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                        FontWeight.w700,
                        letterSpacing: 0.25,
                        color: isDark
                            ? const Color(
                          0xFF72A7F0,
                        )
                            : const Color(
                          0xFF3978D3,
                        ),
                      ),
                    ),

                    const Spacer(),

                    Text(
                      "Changes you are making",

                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                        FontWeight.w400,
                        color: isDark
                            ? Colors.white38
                            : const Color(
                          0xFF9AA8BA,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ======================================================
              // TABLE HEADER
              // ======================================================

              Container(
                height: 38,

                padding:
                const EdgeInsets.symmetric(
                  horizontal: 10,
                ),

                color: isDark
                    ? const Color(0xFF374151)
                    : const Color(0xFF344054),

                child: Row(
                  children: [

                    // #
                    SizedBox(
                      width: 40,
                      child: _leftHeaderText(
                        "#",
                      ),
                    ),

                    // ITEM
                    Expanded(
                      flex: 5,
                      child: _leftHeaderText(
                        "Item Name",
                      ),
                    ),

                    // QUANTITY
                    SizedBox(
                      width: 125,
                      child: _leftHeaderText(
                        "Quantity",
                      ),
                    ),

                    // AMOUNT
                    SizedBox(
                      width: 95,
                      child: _leftHeaderText(
                        "Amount",
                        right: true,
                      ),
                    ),
                  ],
                ),
              ),

              // ======================================================
              // ITEMS
              // ======================================================

              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.zero,

                  itemCount:
                  items.length,

                  itemBuilder:
                      (context, index) {

                    final item =
                    items[index];

                    final modifiers =
                    parseModifiers(
                      item.modifiers,
                    );

                    final voidedItem =
                    _getVoidedItemByItemId(
                      item.itemId,
                    );

                    final isVoided =
                        voidedItem != null;

                    final isRemoved =
                        !isVoided &&
                            (item.quantity ?? 0) ==
                                0;

                    final isReduced =
                        !isVoided &&
                            (item.quantity ?? 0) <
                                (item.maxQty ?? 0);

                    final isReducedkot =
                        !isVoided &&
                            (item.quantity ?? 0) >
                                0 &&
                            (item.quantity ?? 0) <
                                (item.maxQty ?? 0);

                    // ==================================================
                    // ROW BACKGROUND
                    // ==================================================

                    final Color rowColor;

                    if (isVoided ||
                        isRemoved) {
                      rowColor = isDark
                          ? const Color(
                        0xFF3A2428,
                      )
                          : const Color(
                        0xFFFFEEEE,
                      );
                    } else if (isReduced) {
                      rowColor = isDark
                          ? const Color(
                        0xFF393521,
                      )
                          : const Color(
                        0xFFFFFBEA,
                      );
                    } else {
                      rowColor =
                      index.isEven
                          ? (isDark
                          ? const Color(
                        0xFF202433,
                      )
                          : Colors.white)
                          : (isDark
                          ? const Color(
                        0xFF252A36,
                      )
                          : const Color(
                        0xFFF8FAFC,
                      ));
                    }

                    final Color rowBorder =
                    isVoided ||
                        isRemoved
                        ? (isDark
                        ? const Color(
                      0xFF5A3034,
                    )
                        : const Color(
                      0xFFFFD0D0,
                    ))
                        : isReduced
                        ? (isDark
                        ? const Color(
                      0xFF554B29,
                    )
                        : const Color(
                      0xFFF0DE9A,
                    ))
                        : (isDark
                        ? const Color(
                      0xFF303644,
                    )
                        : const Color(
                      0xFFEDF0F4,
                    ));

                    // ==================================================
                    // ROW
                    // ==================================================

                    return Container(
                      constraints:
                      const BoxConstraints(
                        minHeight: 42,
                      ),

                      padding:
                      const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),

                      decoration:
                      BoxDecoration(
                        color: rowColor,

                        border:
                        Border(
                          bottom:
                          BorderSide(
                            color:
                            rowBorder,
                            width: 0.7,
                          ),
                        ),
                      ),

                      child: Row(
                        crossAxisAlignment:
                        CrossAxisAlignment.center,

                        children: [

                          // ==========================================
                          // NUMBER
                          // ==========================================

                          SizedBox(
                            width: 40,

                            child: Text(
                              "${index + 1}",

                              style:
                              TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? Colors
                                    .white38
                                    : const Color(
                                  0xFF8A9AB5,
                                ),
                              ),
                            ),
                          ),

                          // ==========================================
                          // ITEM NAME
                          // ==========================================

                          Expanded(
                            flex: 5,

                            child: Padding(
                              padding:
                              const EdgeInsets
                                  .only(
                                right: 8,
                              ),

                              child: Column(
                                mainAxisAlignment:
                                MainAxisAlignment
                                    .center,

                                crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,

                                children: [

                                  Text(
                                    item.name ??
                                        "-",

                                    maxLines: 1,

                                    overflow:
                                    TextOverflow
                                        .ellipsis,

                                    style:
                                    TextStyle(
                                      fontSize: 12,

                                      fontWeight:
                                      FontWeight
                                          .w500,

                                      color:
                                      isVoided ||
                                          isRemoved
                                          ? (isDark
                                          ? const Color(
                                        0xFFFF7777,
                                      )
                                          : const Color(
                                        0xFFD64545,
                                      ))
                                          : isDark
                                          ? Colors
                                          .white
                                          : const Color(
                                        0xFF172033,
                                      ),

                                      decoration:
                                      isVoided ||
                                          isRemoved
                                          ? TextDecoration
                                          .lineThrough
                                          : null,
                                    ),
                                  ),

                                  // ----------------------------------
                                  // MODIFIERS
                                  // ----------------------------------

                                  if (modifiers
                                      .isNotEmpty)
                                    Padding(
                                      padding:
                                      const EdgeInsets
                                          .only(
                                        top: 1,
                                      ),

                                      child:
                                      Text(
                                        modifiers
                                            .join(
                                          ", ",
                                        ),

                                        maxLines:
                                        1,

                                        overflow:
                                        TextOverflow
                                            .ellipsis,

                                        style:
                                        TextStyle(
                                          fontSize:
                                          9,

                                          color: isDark
                                              ? const Color(
                                            0xFF72A7F0,
                                          )
                                              : const Color(
                                            0xFF5276C7,
                                          ),
                                        ),
                                      ),
                                    ),

                                  // ----------------------------------
                                  // REMOVED / DELETED
                                  // ----------------------------------

                                  if (isVoided ||
                                      isRemoved)
                                    Padding(
                                      padding:
                                      const EdgeInsets
                                          .only(
                                        top: 1,
                                      ),

                                      child:
                                      Text(
                                        isVoided
                                            ? "Item Deleted"
                                            : "Removed",

                                        style:
                                        TextStyle(
                                          fontSize:
                                          8.5,

                                          color: isDark
                                              ? const Color(
                                            0xFFFF7777,
                                          )
                                              : const Color(
                                            0xFFD64545,
                                          ),

                                          fontWeight:
                                          FontWeight
                                              .w600,
                                        ),
                                      ),
                                    ),

                                  // ----------------------------------
                                  // REDUCED
                                  // ----------------------------------

                                  if (isReducedkot)
                                    Padding(
                                      padding:
                                      const EdgeInsets
                                          .only(
                                        top: 1,
                                      ),

                                      child:
                                      Text(
                                        "↓ Reduced",

                                        style:
                                        TextStyle(
                                          fontSize:
                                          8.5,

                                          color: isDark
                                              ? const Color(
                                            0xFFFFC857,
                                          )
                                              : const Color(
                                            0xFFB7791F,
                                          ),

                                          fontWeight:
                                          FontWeight
                                              .w600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),

                          // ==========================================
                          // QUANTITY
                          //
                          // YOUR EXISTING BUTTONS ARE UNCHANGED
                          // ==========================================

                          SizedBox(
                            width: 125,

                            child: Row(
                              mainAxisSize:
                              MainAxisSize.min,

                              children: [

                                // ------------------------------
                                // MINUS
                                // ------------------------------

                                _qtyButton(
                                  Icons.remove,

                                  onTap:
                                  !isVoided &&
                                      (item.quantity ??
                                          0) >
                                          0
                                      ? () {
                                    setInnerState(
                                          () {
                                        item.quantity =
                                            (item.quantity ??
                                                0) -
                                                1;

                                        item.totalWoTax =
                                            item.unitPrice! *
                                                item.quantity!;
                                      },
                                    );

                                    setState(
                                          () {
                                        _dynamicNetPayable -=
                                        item.unitPrice!;
                                      },
                                    );
                                  }
                                      : null,
                                ),

                                const SizedBox(
                                  width: 6,
                                ),

                                SizedBox(
                                  width: 13,

                                  child: Text(
                                    "${isVoided ? 0 : item.quantity ?? 0}",

                                    textAlign:
                                    TextAlign
                                        .center,

                                    style:
                                    TextStyle(
                                      fontSize: 8,
                                      fontWeight:
                                      FontWeight
                                          .w500,
                                      color: isDark
                                          ? Colors
                                          .white
                                          : const Color(
                                        0xFF202633,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(
                                  width: 6,
                                ),

                                // ------------------------------
                                // PLUS
                                // ------------------------------

                                _qtyButton(
                                  Icons.add,

                                  onTap:
                                  !isVoided &&
                                      (item.quantity ??
                                          0) <
                                          (item.maxQty ??
                                              0)
                                      ? () {
                                    setInnerState(
                                          () {
                                        item.quantity =
                                            (item.quantity ??
                                                0) +
                                                1;

                                        item.totalWoTax =
                                            item.unitPrice! *
                                                item.quantity!;
                                      },
                                    );

                                    setState(
                                          () {
                                        _dynamicNetPayable +=
                                        item.unitPrice!;
                                      },
                                    );
                                  }
                                      : null,
                                ),
                              ],
                            ),
                          ),

                          // ==========================================
                          // AMOUNT
                          // ==========================================

                          SizedBox(
                            width: 95,

                            child: Text(
                              isVoided
                                  ? "${_currency}0.00"
                                  : "${_currency}${(item.totalWoTax ?? 0).toStringAsFixed(2)}",

                              maxLines: 1,

                              overflow:
                              TextOverflow
                                  .ellipsis,

                              textAlign:
                              TextAlign.right,

                              style:
                              TextStyle(
                                fontSize: 12,

                                fontWeight:
                                FontWeight
                                    .w700,

                                color: isVoided ||
                                    isRemoved
                                    ? (isDark
                                    ? const Color(
                                  0xFFFF7777,
                                )
                                    : const Color(
                                  0xFFD64545,
                                ))
                                    : isDark
                                    ? Colors
                                    .white
                                    : const Color(
                                  0xFF172033,
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
            ],
          ),
        );
      },
    );
  }
  Widget _orderModifiedPopup(
      BuildContext context,
      OrderlistModel order,
      ) {
    final updatedTotal =
    (order.netPayable ?? order.displayTotal ?? 0).toDouble();

    // ============================================================
    // MODIFIED BY = NAME · ROLE
    // Example: manager 2 · manager
    // ============================================================
    final name = order.placedByName?.trim() ?? '';
    final role = order.placedByRole?.trim() ?? '';

    final modifiedBy = () {
      if (name.isNotEmpty && role.isNotEmpty) {
        return '$name · $role';
      }

      if (name.isNotEmpty) {
        return name;
      }

      if (role.isNotEmpty) {
        return role;
      }

      return '-';
    }();

    final modifiedAt = _modifiedAt ?? DateTime.now();

    final formattedDate =
        "${modifiedAt.day.toString().padLeft(2, '0')} "
        "${_monthName(modifiedAt.month)} "
        "${modifiedAt.year} · "
        "${_formatTime(modifiedAt)}";

    final refundDue = _calculateRefundDue(order);

    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: 430,
      ),
      child: Container(
        width: 430,
        padding: const EdgeInsets.fromLTRB(
          26,
          26,
          26,
          22,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x38000000),
              blurRadius: 0,
              offset: Offset(0, 0),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ============================================================
            // SUCCESS ICON
            // ============================================================
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Color(0xFFDCFCE7),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.check,
                  size: 22,
                  color: Color(0xFF16A34A),
                ),
              ),
            ),

            const SizedBox(height: 13),

            // ============================================================
            // TITLE
            // ============================================================
            const Text(
              'Order Modified Successfully',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF16A34A),
                fontSize: 18,
                fontWeight: FontWeight.w800,
                height: 1.3,
              ),
            ),

            const SizedBox(height: 4),

            // ============================================================
            // ORDER ID
            // ============================================================
            Text(
              'Order #${order.orderId} · Revision 2',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 18),

            // ============================================================
            // DETAILS CARD
            // ============================================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 11,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  // ------------------------------------------------------
                  // ROW 1
                  // ------------------------------------------------------
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _popupInfo(
                          'Updated Total',
                          _formatCurrency(updatedTotal),
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: _popupInfo(
                          'Refund Due',
                          _formatCurrency(refundDue),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 11),

                  // ------------------------------------------------------
                  // ROW 2
                  // ------------------------------------------------------
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _popupInfo(
                          'Modified By',
                          modifiedBy,
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: _popupInfo(
                          'Modified At',
                          formattedDate,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ============================================================
            // VIEW UPDATED ORDER BUTTON
            // ============================================================
            SizedBox(
              width: double.infinity,
              height: 43,
              child: ElevatedButton(
                onPressed: () {
                  // Close the success popup first
                  Navigator.pop(context);

                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrdersDetailsScreen(
                        token: widget.token,
                        pin: widget.pin,
                        restaurantId: widget.restaurantId,
                        restaurantName: widget.restaurantName,
                        orderId: order.orderId!,
                        initialOrder: order,
                        userPermissions: _userPermissions,
                        onPermissionsReceived: (permissions) {
                          setState(() {
                            _userPermissions = permissions;
                          });
                        },
                      ),
                    ),
                        (route) => route.isFirst,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A5F),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
                child: const Text(
                  'View Updated Order →',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _popupInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
  Widget _summaryRow(
      String label,
      String value, {
        bool bold = false,
        Color? labelColor,
        Color? valueColor,
      }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF252B38)
            : const Color(0xFFF8FAFC),

        // Bottom line + bottom curves
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? const Color(0xFF3A4150)
                : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),

        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(14),
          bottomRight: Radius.circular(14),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              color: labelColor ??
                  (isDark
                      ? Colors.white70
                      : const Color(0xFF475569)),
              fontSize: 13,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
              height: 1.0,
            ),
          ),

          Text(
            value,
            style: TextStyle(
              color: valueColor ??
                  (isDark
                      ? Colors.white
                      : const Color(0xFF1E3A5F)),
              fontSize: 14,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w800,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  // Qty button with red when clickable, grey when disabled
  Widget _qtyButton(IconData icon, {VoidCallback? onTap}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEnabled = onTap != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isEnabled
              ? const Color(0xFFFFE5E5)
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          icon,
          size: 14,
          color: isEnabled
              ? const Color(0xFFFE6464)
              : Colors.grey,
        ),
      ),
    );
  }
}
