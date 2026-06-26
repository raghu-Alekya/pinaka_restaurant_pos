import 'dart:convert';

import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/material.dart';
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
  List<String> kot_remarks= [
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

  String? selectedReason;
  final TextEditingController _remarksController = TextEditingController();


  UserPermissions? _userPermissions;
  int _selectedIndex = 4;
  bool _isUpdateEnabled = false; // initially disabled

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
                    '₹${item.itemTotal.toStringAsFixed(2)}',
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

      _selectedKotOriginalTotal = (_selectedKot?.lineItems ?? [])
          .fold(0.0, (sum, i) => sum + (i.totalWoTax ?? 0));

      // LEFT PANEL (always original snapshot)
      _leftPanelItems = (_selectedKot?.lineItems ?? []).map((item) {
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
            () => _selectedKot!.lineItems!.map((item) {
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
      return _voidedItems.firstWhere(
            (v) => v.itemId == itemId,
      );
    } catch (_) {
      return null;
    }
  }




  List<String> parseModifiers(dynamic raw) {
    if (raw == null) return [];

    if (raw is List) {
      // List of strings or objects
      return raw.map<String>((m) {
        if (m is String) return m;
        if (m is Map) return m['name']?.toString() ?? '';
        return '';
      }).where((e) => e.isNotEmpty).toList();
    }

    if (raw is String) {
      // Possibly JSON string
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded.map<String>((m) {
            if (m is String) return m;
            if (m is Map) return m['name']?.toString() ?? '';
            return '';
          }).where((e) => e.isNotEmpty).toList();
        }
      } catch (e) {
        // Not JSON, just raw string
        return [raw];
      }
    }

    return [];
  }
  Future<void> _refreshOrders() async {
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
        const SnackBar(content: Text("Please select a reason")),
      );
      return;
    }
    setState(() {
      _isUpdatingKot = true;   // 🔹 START LOADER
      _updateMessage = null;  // clear old success
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
          const SnackBar(content: Text("⚠️ No items to update")),
        );
        return;
      }

      // 3️⃣ Build payload
      final List<Map<String, dynamic>> lineItemsPayload = [];

      for (final item in items) {
        final qty = item.quantity ?? 0;

        if (item.lineItemId != null) {
          lineItemsPayload.add({
            "id": item.lineItemId,
            "quantity": qty, // qty = 0 → remove
          });
        } else if (item.itemId != null && qty > 0) {
          lineItemsPayload.add({
            "product_id": item.itemId,
            "quantity": qty,
          });
        }
      }

      if (lineItemsPayload.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("⚠️ No valid items to update")),
        );
        return;
      }

      final payload = {
        "line_items": lineItemsPayload,
        "meta_data": [
          if (_remarksController.text.trim().isNotEmpty)
            {
              "key": "kot_remarks",
              "value": _remarksController.text.trim(),
            },
          {
            "key": "kot_remarks",
            "value": selectedReason,
          },
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

      setState(() {
        _isUpdatingKot = false;
        _updateMessage = "KOT updated Successfully. Final Net payable updated.";
      });

      Future.delayed(const Duration(seconds: 1), () {
        if (!mounted) return;
        setState(() => _updateMessage = null);
      });

    } catch (e) {
      print("❌ KOT Update Failed => $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Update failed: $e")),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF1F1F3),


      appBar: TopBar(
        token: widget.token,
        pin: widget.pin,
        userPermissions: _userPermissions,
        onPermissionsReceived: (p) => setState(() => _userPermissions = p),
      ),


      body: FutureBuilder<List<OrderlistModel>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final order = snapshot.data!
              .firstWhere((o) => o.orderId == widget.orderId);
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
            _leftPanelItems = (_selectedKot?.lineItems ?? []).map((item) {
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
                    () => _selectedKot!.lineItems!.map((item) {
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

          return Padding(
            padding: const EdgeInsets.all(0),
            child: Container(
              // decoration: BoxDecoration(
              //   color: const Color(0xFFE5EFFF),
              //   borderRadius: BorderRadius.circular(14),
              // ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(width:  42),
                      Row(
                        children: [
                          const SizedBox(width:  10),
                          SizedBox(
                            width: 110, // button width
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3B4259), // dark button color
                                minimumSize: const Size(110, 40),
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () {
                                Navigator.pop(context, true); // navigate back
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.arrow_back, size: 20, color: Colors.white),
                                  SizedBox(width: 6),
                                  Text(
                                    "Edit Order",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white, // white text
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(width: 16),

                          // 🧾 Order ID label
                          const Text(
                            "Order ID :",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF7A7A7A),
                            ),
                          ),

                          const SizedBox(width: 6),

                          //  Order ID value
                          Text(
                            "#${widget.orderId}",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4C5F7D),
                            ),
                          ),

                          const Spacer(),
                          if (kots.isNotEmpty)
                            Container(
                              height: 40,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF125BCE),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  value: _selectedKotId,
                                  icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                                  dropdownColor: const Color(0xFF125BCE),
                                  style: const TextStyle(color: Colors.white),
                                  items: kots.map((kot) {
                                    return DropdownMenuItem<int>(
                                      value: kot.kotOrderId,
                                      child: Text("KOT ${kot.kotOrderId}"),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    if (value != null) _onKotSelected(value, kots);
                                  },
                                ),
                              ),
                            ),
                          const SizedBox(width: 12),
                        ],
                      ),

                      const SizedBox(height: 0),

                      // Panels
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              flex: 1,
                              child: Container(
                                margin: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE5EFFF),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Stack(
                                  children: [
                                    // Left panel content
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        top: 0,
                                        left: 0,
                                        right: 0,
                                        bottom: 20, // leave space for overlay summary
                                      ),
                                      child: _selectedKot == null
                                          ? const Center(child: Text("Select a KOT"))
                                          : _buildLeftPanel(order, kots), // your existing left panel content
                                    ),

                                    // Overlay summary inside the container
                                    if (_selectedKot != null)
                                      Positioned(
                                        left: 0,
                                        right: 0,
                                        bottom: 0,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
                                          decoration: BoxDecoration(
                                            color: Colors.transparent,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child:  _summaryRow(
                                            "KOT #${_selectedKot?.kotOrderId ?? '-'} - Amount",
                                            "₹${(_selectedKot?.lineItems ?? [])
                                                .fold<double>(
                                              0.0,
                                                  (sum, item) => sum + (item.totalWoTax ?? 0),
                                            )
                                                .toStringAsFixed(2)}",
                                            bold: true,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(width: 12),
                            Flexible(
                              flex: 1,
                              child: Container(
                                margin: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE5EFFF),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Stack(
                                  children: [
                                    // KOT Card content
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        top: 12,
                                        left: 12,
                                        right: 12,
                                        bottom: 30, // leave space for overlay summary inside the container
                                      ),
                                      child: _selectedKot == null
                                          ? const Center(child: Text("Select a KOT"))
                                          : buildSelectedKotCard(_selectedKot!),
                                    ),

                                    // Overlay summary row inside the container
                                    if (_selectedKot != null)
                                      Positioned(
                                        left: 0,
                                        right: 0,
                                        bottom: 0, // stays inside the container
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
                                          decoration: BoxDecoration(
                                            color: Colors.transparent,
                                            borderRadius: BorderRadius.circular(12),
                                            // boxShadow: const [
                                            //   BoxShadow(
                                            //     color: Colors.black26,
                                            //     blurRadius: 6,
                                            //     offset: Offset(0, 2),
                                            //   ),
                                            // ],
                                          ),
                                          child: _summaryRow(
                                            "KOT #${_selectedKot?.kotOrderId ?? '-'} - Amount",
                                            "₹${(_editedKotItems[_selectedKotId] ?? [])
                                                .fold<double>(0.0, (sum, i) => sum + (i.totalWoTax ?? 0))
                                                .toStringAsFixed(2)}",
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

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox(width: 15),

                          Expanded(
                            child: _infoRow(
                              "Order Net Payable",
                              "₹${(order.orderPrevTotal ?? 0).toStringAsFixed(2)}",
                              bold: true,
                              labelColor: Colors.black87,
                              valueColor: Colors.black87,
                              labelFontWeight: FontWeight.w600,
                              valueFontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 34),

                          Expanded(
                            child: _infoRow(
                              "Order Updated Net Payable",
                              "₹${_dynamicNetPayable.toStringAsFixed(2)}",
                              bold: true,
                              labelColor: Colors.black87,
                              valueColor: Colors.black87, //  second value color valueColor: Color(0xFF086888),
                              labelFontWeight: FontWeight.w700,  // Label weight: light
                              valueFontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),



                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          //  Enter Reason

                          if (kot_remarks.isNotEmpty) ...[
                            const SizedBox(width: 10,),
                            Container(
                              padding: const EdgeInsets.fromLTRB(24, 8, 8, 8),

                              decoration: BoxDecoration(
                                color: const Color(0xFFE5EFFF),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFE5EFFF)),
                              ),
                              child: Row(
                                children: [
                                  const Text(
                                    "Enter Reason:",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF393A3B),
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  // dropdown
                                  SizedBox(
                                    width: 450,
                                    height: 30,
                                    child: Container(
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
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF9E9E9E),
                                            ),
                                          ),
                                          isExpanded: true,
                                          dropdownColor: Colors.white,
                                          icon: const Icon(
                                            Icons.keyboard_arrow_down,
                                            color: Color(0xFF757575),
                                          ),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF212121),
                                          ),
                                          items: kot_remarks.map((reason) {
                                            return DropdownMenuItem<String>(
                                              value: reason,
                                              child: Text(
                                                reason,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFF212121),
                                                ),
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
                            ),
                          ],

                          //  Spacer only if no success message
                          if (_updateMessage == null) const Spacer(),

                          // Success message (Flexible)

                          if (_isUpdatingKot || _updateMessage != null) ...[
                            const SizedBox(width: 12),

                            Flexible(
                              child: Row(
                                children: [
                                  // 🔄 Loader while updating
                                  if (_isUpdatingKot)
                                    const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  // ✅ Success tick
                                  else
                                    Image.asset(
                                      "assets/success_tick.png",
                                      width: 20,
                                      height: 20,
                                    ),

                                  const SizedBox(width: 6),

                                  Flexible(
                                    child: Text(
                                      _isUpdatingKot
                                          ? "Updating KOT, please wait..."
                                          : _updateMessage!,
                                      style: TextStyle(
                                        color: _isUpdatingKot ? Colors.orange : Colors.green,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 12),
                          ],


                          //  Update KOT button

                          ElevatedButton(
                            onPressed: _isUpdatingKot ? null : _updateKot,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4C5F7D), // ✅ SAME color
                              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
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
                                : const Text(
                              "Update KOT",
                              style: TextStyle(
                                fontSize: 14,               //  SAME font size
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),

                          const SizedBox(width:  10),
                        ],
                      )


                    ],
                  ),
                ),
              ),
            ),
          );

        },
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
    );
  }

// =========================================================
// LEFT PANEL (Order info + KOT selector) - STATIC VIEW
// =========================================================
  Widget _buildLeftPanel(OrderlistModel order, List<KotOrder> kots) {
    final kot = _selectedKot;

    if (kot != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadVoidedItemsForKot(kot);
      });
    }

//  DEFINE LISTS HERE (IMPORTANT)
    final allItems = kot?.lineItems ?? [];

// normal (not deleted)
    final normalItems = allItems.where((item) {
      return _getVoidedItemByItemId(item.itemId) == null;
    }).toList();

// deleted (from API)
    final voidedItems = _currentVoidedItems;


    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE5EFFF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "KOT ID: ${kot?.kotOrderId ?? '-'}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                Expanded(
                  child: Text(
                    "All ordered items are listed here KOT wise",
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF092044),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Table Header
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF999393),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
              child: const Row(
                children: [
                  Expanded(flex: 1, child: Text("#", style: TextStyle(fontWeight:FontWeight.w400,color: Color(0xFFF5F5F5)))),
                  Expanded(flex: 3, child: Text("Item", style: TextStyle(fontWeight: FontWeight.w400,color: Color(0xFFF5F5F5)))),
                  Expanded(flex: 2, child: Text("Quantity", style: TextStyle(fontWeight: FontWeight.w400,color: Color(0xFFF5F5F5)))),
                  Expanded(flex: 1, child: Text("Amount", style: TextStyle(fontWeight: FontWeight.w400,color: Color(0xFFF5F5F5)))),
                ],
              ),
            ),

            // Items List (STATIC)
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: normalItems.length + voidedItems.length,
                itemBuilder: (context, index) {
                  final bool isNormal = index < normalItems.length;
                  final bool isLast =
                      index == (normalItems.length + voidedItems.length - 1);

                  // Loading state for voided items
                  if (_isVoidedLoading && !isNormal) {
                    return const Padding(
                      padding: EdgeInsets.all(12),
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }

                  return Container(
                    padding: isNormal
                        ? const EdgeInsets.symmetric(vertical: 8, horizontal: 16)
                        : const EdgeInsets.symmetric(vertical: 2, horizontal: 16),
                    decoration: BoxDecoration(
                      color: isNormal ? const Color(0xFFFBFBFC) : const Color(0xFFF2F2F2),
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade300),
                      ),
                      borderRadius: isLast
                          ? const BorderRadius.only(
                        bottomLeft: Radius.circular(0),
                        bottomRight: Radius.circular(0),
                      )
                          : BorderRadius.zero,
                    ),
                    child: isNormal
                        ? _buildNormalRowUI(
                      normalItems[index],
                      index,
                    )
                        : _buildVoidedRowUI(
                      voidedItems[index - normalItems.length],
                      index,
                    ),
                  );
                },
              ),
            ),


            // const SizedBox(height: 12),
            //
            // // Summary Row: Updated Net Payable
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //   children: [
            //     _summaryRow(
            //       "KOT #${_selectedKot?.kotOrderId ?? '-'} - Amount",
            //       "₹${_leftPanelItems.fold<double>(0.0, (sum, i) => sum + (i.amount ?? 0)).toStringAsFixed(2)}",
            //       bold: true,
            //     ),
            //
            //
            //     // Update KOT Button
            //     // ElevatedButton(
            //     //   onPressed: _updateKot, // uses updated _leftPanelItems
            //     //   style: ElevatedButton.styleFrom(
            //     //     backgroundColor: const Color(0xFF125BCE),
            //     //     padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            //     //     shape: RoundedRectangleBorder(
            //     //       borderRadius: BorderRadius.circular(8),
            //     //     ),
            //     //   ),
            //     //   child: const Text(
            //     //     "Update KOT",
            //     //     style: TextStyle(
            //     //       fontSize: 14,
            //     //       fontWeight: FontWeight.w600,
            //     //       color: Colors.white,
            //     //     ),
            //     //   ),
            //     // ),
            //   ],
            // ),
          ],
        ),
      ),
    );
  }
  Widget _buildNormalRowUI(LineItem item, int index) {
    final modifiers = parseModifiers(item.modifiers);

    return Row(
      children: [
        Expanded(flex: 1, child: Text("${index + 1}")),
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name ?? "-",
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              if (modifiers.isNotEmpty)
                Text(
                  modifiers.join(", "),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
            ],
          ),
        ),
        Expanded(flex: 2, child: Text("${item.quantity ?? 0}")),
        Expanded(
          flex: 1,
          child: Text(
            "₹${(item.totalWoTax ?? 0).toStringAsFixed(2)}",
          ),
        ),
      ],
    );
  }
  Widget _buildVoidedRowUI(VoidedItem item, int index) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Text(
            "${index + 1}",
            style: const TextStyle(color: Color(0xFFB9B9B9)),
          ),
        ),
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.product,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFB9B9B9),
                ),
              ),
              const Text(
                "Item Deleted",
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            "${item.origQty} → 0",
            style: const TextStyle(color: Color(0xFFB9B9B9)),
          ),
        ),
        Expanded(
          flex: 1,
          child: Text(
            "₹${item.itemTotal.toStringAsFixed(2)}",
            style: const TextStyle(
              color: Color(0xFFB9B9B9),
              // decoration: TextDecoration.lineThrough,
            ),
          ),
        ),
      ],
    );
  }


  Widget _infoRow(
      String label,
      String value, {
        bool bold = false,
        Color labelColor = Colors.black87,
        Color valueColor = Colors.black87,
        FontWeight labelFontWeight = FontWeight.normal, // Default to normal
        FontWeight valueFontWeight = FontWeight.normal, // Default to normal
      }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
      child: Row(
        children: [
          const SizedBox(width: 20),

          Text(
            label,
            style: TextStyle(
              fontWeight: labelFontWeight, // Apply labelFontWeight
              fontSize: 14,
              color: labelColor,
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: valueFontWeight, // Apply valueFontWeight
                fontSize: 16,
                color: valueColor,
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
    // Use the editable copy
    final items = _editedKotItems[_selectedKotId] ?? [];

    return StatefulBuilder(
      builder: (context, setInnerState) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: const Text(
                  "To edit an item, adjust quantity or add/remove items as needed.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Color(0xFF092044)),
                ),
              ),
              const SizedBox(height: 10),

              // Header
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF999393),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                child: const Row(
                  children: [
                    Expanded(flex: 1, child: Text("#", style: TextStyle(fontWeight: FontWeight.w400,color: Color(0xFFF5F5F5)))),
                    Expanded(flex: 3, child: Text("Item", style: TextStyle(fontWeight:FontWeight.w400,color: Color(0xFFF5F5F5)))),
                    Expanded(flex: 2, child: Text("Quantity", style: TextStyle(fontWeight:FontWeight.w400,color: Color(0xFFF5F5F5)))),
                    Expanded(flex: 1, child: Text("Amount", style: TextStyle(fontWeight: FontWeight.w400,color: Color(0xFFF5F5F5)))),
                  ],
                ),
              ),

              // Items List
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final modifiers = parseModifiers(item.modifiers);

                    // Check if this item is voided
                    final voidedItem = _getVoidedItemByItemId(item.itemId);
                    final isVoided = voidedItem != null;

                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: isVoided ? const Color(0xFFFFEEEE) : const Color(0xFFFBFBFC),
                        border: Border(
                          bottom: BorderSide(color: isVoided ? Colors.red.shade200 : Colors.grey[300]!),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(flex: 1, child: Text("${index + 1}")),

                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name ?? "-",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: isVoided ? Colors.red : Colors.black,
                                    decoration: isVoided ? TextDecoration.lineThrough : null,
                                  ),
                                ),

                                if (modifiers.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      modifiers.join(", "),
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  ),

                                if (isVoided)
                                  const Padding(
                                    padding: EdgeInsets.only(top: 2),
                                    child: Text(
                                      "Item Deleted",
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.red,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          Expanded(
                            flex: 2,
                            child: Row(
                              children: [
                                // Decrement button (disabled for voided items)
                                _qtyButton(
                                  Icons.remove,
                                  onTap: !isVoided && (item.quantity ?? 0) > 0
                                      ? () {
                                    setInnerState(() {
                                      item.quantity = (item.quantity ?? 0) - 1;
                                      item.totalWoTax = item.unitPrice! * item.quantity!;
                                    });
                                    setState(() {
                                      _dynamicNetPayable -= item.unitPrice!;
                                    });
                                  }
                                      : null,
                                ),

                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text("${isVoided ? 0 : item.quantity ?? 0}"),
                                ),

                                // Increment button (disabled for voided items)
                                _qtyButton(
                                  Icons.add,
                                  onTap: !isVoided && (item.quantity ?? 0) < (item.maxQty ?? 0)
                                      ? () {
                                    setInnerState(() {
                                      item.quantity = (item.quantity ?? 0) + 1;
                                      item.totalWoTax = item.unitPrice! * item.quantity!;
                                    });
                                    setState(() {
                                      _dynamicNetPayable += item.unitPrice!;
                                    });
                                  }
                                      : null,
                                ),
                              ],
                            ),
                          ),

                          Expanded(
                            flex: 1,
                            child: Text(
                              isVoided ? "₹0.00" : "₹${(item.totalWoTax ?? 0).toStringAsFixed(2)}",
                              style: TextStyle(color: isVoided ? Colors.red : Colors.black),
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





  // Summary Row Helper
  Widget _summaryRow(
      String label,
      String value, {
        bool bold = false,
        Color labelColor = const Color(0xFF252525),
        Color valueColor = const Color(0xFF373535),
      }) {
    return Container(

      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        color: const Color(0xFFECECEC),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(14),
            bottomRight: Radius.circular(14),
          ),
        ),
        shadows: [
          BoxShadow(
            color: Color(0x3F000000),
            blurRadius: 6,
            offset: Offset(0, -4),
            spreadRadius: 0,
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(30, 12, 50, 8),

      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w500 : FontWeight.normal,
              fontSize: 12,
              fontFamily: 'Inter',
              color: labelColor,
            ),
          ),
          // const SizedBox(width: 280), // fixed width gap
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w500 : FontWeight.normal,
              fontSize: 14,
              fontFamily: 'Inter',
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }


// Qty button with red when clickable, grey when disabled
  Widget _qtyButton(IconData icon, {VoidCallback? onTap}) {
    final isEnabled = onTap != null; // if onTap is null, button is disabled

    return InkWell(
      onTap: onTap, // null disables tap automatically
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFFFE5E5), // light red background always
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          icon,
          size: 14,
          color: isEnabled ? Colors.red : Colors.grey, // red if enabled, grey if disabled
        ),
      ),
    );
  }


}