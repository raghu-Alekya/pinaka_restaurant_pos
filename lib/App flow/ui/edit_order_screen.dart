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
  List<String> voidReasons = [
    "Wrong Order",
    "Customer Cancelled",
    "Payment Failed",
    "Item Not Available",
  ];

  String? selectedReason;
  final TextEditingController _remarksController = TextEditingController();


  UserPermissions? _userPermissions;
  int _selectedIndex = 4;
  bool _isUpdateEnabled = false; // initially disabled

  Future<List<OrderlistModel>>? _ordersFuture;

  int? _selectedKotId;
  KotOrder? _selectedKot;

  String getUpdatedNetPayable(OrderlistModel order) {
    // Start with original net payable
    double currentNet = (order.netPayable ?? 0).toDouble();

    // Calculate delta from all left panel items
    double delta = 0.0;

    for (final item in _leftPanelItems) {
      final originalQty = (item.quantity ?? 0);
      final originalAmount = (item.originalAmount ?? 0).toDouble();
      final currentAmount = (item.amount ?? 0).toDouble();

      delta += (currentAmount - originalAmount); // positive or negative
    }

    final updatedNet = currentNet + delta;
    return "₹${updatedNet.toStringAsFixed(2)}";
  }

  List<LineItem> _leftPanelItems = [];


  @override
  void initState() {
    super.initState();
    _userPermissions = widget.userPermissions;
    _ordersFuture = _orderRepo.fetchOrders(widget.token);
  }

  void _onItemTapped(int index) {
    NavigationHelper.handleNavigation(
      context,
      _selectedIndex,
      index,
      widget.pin,
      widget.token,
      widget.restaurantId,
      widget.restaurantName,
      widget.userPermissions,
    );
    setState(() => _selectedIndex = index);
  }

  // Central KOT selection handler
  void _onKotSelected(int kotId, List<KotOrder> kots) {
    setState(() {
      _selectedKotId = kotId;
      _selectedKot = kots.firstWhere((k) => k.kotOrderId == kotId);

      // Deep copy for left panel WITH lineItemId
      _leftPanelItems = (_selectedKot?.lineItems ?? [])
          .map((item) => LineItem(
        lineItemId: item.lineItemId, // ✅ important
        itemId: item.itemId,
        name: item.name,
        quantity: item.quantity,
        amount: item.amount,
        modifiers: List<String>.from(item.modifiers ?? []),
      ))
          .toList();

      print(
          "Selected KOT: $_selectedKotId with ${_selectedKot?.lineItems?.length ?? 0} items");
    });
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

  Future<void> _updateKot() async {
    if (_selectedKot == null) return;

    final repo = EditOrderlistRepository(
      baseUrl: AppConstants.baseApiPath,
      token: widget.token,
    );

    final kotId = _selectedKot!.kotOrderId;
    print("🔵 Preparing to update KOT");
    print("📌 Order ID: ${widget.orderId}");
    print("📌 Selected KOT ID: $kotId");

    try {
      // 1️⃣ Fetch full parent order
      final order = await repo.fetchOrder(widget.orderId);

      // 2️⃣ Find selected KOT inside parent order
      final selectedKotInOrder = order.kotOrders?.firstWhere(
            (k) => k.kotOrderId == kotId,
        orElse: () => throw Exception("Selected KOT not found in parent order"),
      );

      // 3️⃣ Build payload
      final List<Map<String, dynamic>> lineItemsPayload = [];

      for (final item in _leftPanelItems) {
        final qty = item.quantity?.toInt() ?? 0;

        if (item.lineItemId != null) {
          // ✅ Existing item → update or delete
          lineItemsPayload.add({
            "id": item.lineItemId,
            "quantity": qty,
          });
          print(qty == 0
              ? "🗑 Deleting item => line_item_id: ${item.lineItemId}"
              : "✏️ Updating item => line_item_id: ${item.lineItemId}, qty: $qty, name: ${item.name}");
        } else if (item.itemId != null && item.itemId != 0 && qty > 0) {
          // ✅ New item → add
          lineItemsPayload.add({
            "product_id": item.itemId,
            "quantity": qty,
          });
          print(
              "➕ Adding new item => product_id: ${item.itemId}, qty: $qty, name: ${item.name}");
        }
      }

      if (lineItemsPayload.isEmpty) {
        print("⚠️ No valid line items to update.");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("⚠️ No valid items to update")),
        );
        return;
      }

      // 4️⃣ Meta data
      final metaDataPayload = _remarksController.text.trim().isNotEmpty
          ? [
        {"key": "kot_remarks", "value": _remarksController.text.trim()}
      ]
          : [];

      final payload = {
        "line_items": lineItemsPayload,
        "meta_data": metaDataPayload,
      };

      print("📤 Final payload:");
      print(jsonEncode(payload));

      // 5️⃣ Temporarily handle completed KOTs
      final originalStatus = _selectedKot?.status ?? "processing";
      if (originalStatus == "completed") {
        print("⚡ Switching completed → processing");
        await repo.updateOrderRaw(
          orderId: widget.orderId,
          kotOrderId: kotId,
          payload: {"status": "processing"},
        );
      }

      // 6️⃣ Update KOT
      final success = await repo.updateOrderRaw(
        orderId: widget.orderId,
        kotOrderId: kotId, // ✅ Send KOT ID in URL
        payload: payload,
      );

      if (!success) throw Exception("Update failed");

      // 7️⃣ Restore original status if needed
      if (originalStatus == "completed") {
        print("⚡ Restoring processing → completed");
        await repo.updateOrderRaw(
          orderId: widget.orderId,
          kotOrderId: kotId,
          payload: {"status": "completed"},
        );
      }

      print("✅ KOT Updated Successfully for KOT $kotId");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ KOT Updated Successfully")),
      );

      // Navigator.pop(context, true);
    } catch (e) {
      print("❌ KOT Update Failed => $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Update failed: $e")),
      );
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
      backgroundColor: const Color(0xFFE1E1E1),


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

          final kots = order.kotOrders ?? [];

          // Initialize default KOT
          if (_selectedKotId == null && kots.isNotEmpty) {
            _selectedKotId = kots.first.kotOrderId;
            _selectedKot = kots.first;

            // Populate left panel items for default KOT
            _leftPanelItems = (_selectedKot?.lineItems ?? [])
                .map((item) => LineItem(
              lineItemId: item.lineItemId,
              itemId: item.itemId,
              name: item.name,
              quantity: item.quantity,
              amount: item.amount,
              modifiers: parseModifiers(item.modifiers),

            ))
                .toList();
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
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [


                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, size: 20),
                            onPressed: () => Navigator.pop(context, true),

                          ),
                          const SizedBox(width: 6),
                          const Text(
                            "Edit Order",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
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
                              child: _buildLeftPanel(order, kots),
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              flex: 1,
                              child: Container(
                                margin: const EdgeInsets.all(8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE5EFFF),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: _selectedKot == null
                                    ? const Center(child: Text("Select a KOT"))
                                    : buildSelectedKotCard(_selectedKot!),
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
                          Expanded(
                            child: _infoRow(
                              "Net Payable",
                              "₹${(order.netPayable ?? 0).toStringAsFixed(2)}",
                              bold: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _infoRow(
                              "Updated Net Payable",
                              getUpdatedNetPayable(order),  // example adjustment
                              bold: true,
                            ),
                          ),



                        ],
                      ),



                      Row(

                        children: [
                          if (voidReasons.isNotEmpty) ...[
                            Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFE5EFFF),
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

                                      Expanded(
                                        child: Container(
                                          height: 30,
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
                                              items: voidReasons.map((reason) {
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
                                      const SizedBox(width: 12),
                                    ],
                                  ),
                                )

                            ),

                            const Spacer() // ✅ Correct spacing instead of Spacer
                          ],

                          //  Update details Button
                          ElevatedButton(
                            onPressed: _updateKot,   // ✅ call API directly
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4C5F7D),
                              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              "Update KOT",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),


                          const SizedBox(width: 12),
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
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        userPermissions: _userPermissions,
        onItemTapped: _onItemTapped,
      ),
    );
  }

// =========================================================
// LEFT PANEL (Order info + KOT selector) - STATIC VIEW
// =========================================================
  Widget _buildLeftPanel(OrderlistModel order, List<KotOrder> kots) {
    final kot = _selectedKot; // selected KOT
    final items = kot?.lineItems ?? [];

    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
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
                  Expanded(flex: 1, child: Text("#", style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 3, child: Text("Item", style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text("Qty", style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text("Amount", style: TextStyle(fontWeight: FontWeight.bold))),
                ],
              ),
            ),

            // Items List (STATIC)
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final modifiers = parseModifiers(item.modifiers);

                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
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
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              if (modifiers.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    modifiers.join(", "),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Expanded(flex: 2, child: Text("${item.quantity ?? 0}")),
                        Expanded(flex: 2, child: Text("₹${(item.amount ?? 0).toStringAsFixed(2)}")),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _infoRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
              color: Colors.black87,
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }


  // =========================================================
  // RIGHT PANEL (Editable KOT)

  Widget buildSelectedKotCard(KotOrder kot) {
    // Use the editable copy
    final items = _leftPanelItems;

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
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                child: const Row(
                  children: [
                    Expanded(flex: 1, child: Text("#")),
                    Expanded(flex: 3, child: Text("Item")),
                    Expanded(flex: 2, child: Text("Qty")),
                    Expanded(flex: 2, child: Text("Amount")),
                  ],
                ),
              ),

              // Items List
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final unitPrice = (item.amount ?? 0) / ((item.quantity ?? 1));

                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(flex: 1, child: Text("${index + 1}")),
                          Expanded(flex: 3, child: Text(item.name ?? "-")),
                          Expanded(
                            flex: 2,
                            child: Row(
                              children: [
                                // Decrement
                                _qtyButton(
                                  Icons.remove,
                                  onTap: (item.quantity ?? 0) > 0
                                      ? () {
                                    setInnerState(() {
                                      item.quantity = (item.quantity ?? 0) - 1;
                                      item.amount = unitPrice * item.quantity!;
                                    });
                                    setState(() {});
                                  }
                                      : null, // disable if 0
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text("${item.quantity ?? 0}"),
                                ),
                                // Increment
                                _qtyButton(
                                  Icons.add,
                                  onTap: (item.quantity ?? 0) < (item.quantity ?? 0) // restrict to backend value
                                      ? () {
                                    setInnerState(() {
                                      item.quantity = (item.quantity ?? 0) + 1;
                                      item.amount = unitPrice * item.quantity!;
                                    });
                                    setState(() {});
                                  }
                                      : null, // disable if reached backend value
                                ),
                              ],
                            ),
                          ),

                          Expanded(
                            flex: 2,
                            child: Text("₹${(item.amount ?? 0).toStringAsFixed(2)}"),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // Summary Row: Updated Net Payable
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //   children: [
              //     _summaryRow(
              //       "Updated Net Payable",
              //       "₹${_leftPanelItems.fold<double>(0.0, (sum, i) => sum + (i.amount ?? 0)).toStringAsFixed(2)}",
              //       bold: true,
              //     ),
              //
              //     // Update KOT Button
              //     ElevatedButton(
              //       onPressed: _updateKot, // uses updated _leftPanelItems
              //       style: ElevatedButton.styleFrom(
              //         backgroundColor: const Color(0xFF125BCE),
              //         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              //         shape: RoundedRectangleBorder(
              //           borderRadius: BorderRadius.circular(8),
              //         ),
              //       ),
              //       child: const Text(
              //         "Update KOT",
              //         style: TextStyle(
              //           fontSize: 14,
              //           fontWeight: FontWeight.w600,
              //           color: Colors.white,
              //         ),
              //       ),
              //     ),
              //   ],
              // ),
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
        Color labelColor = Colors.black,
        Color valueColor = Colors.black,
      }) {
    return Row(
      mainAxisSize: MainAxisSize.min, // 🔹 shrink to content
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            color: labelColor,
          ),
        ),
        const SizedBox(width: 4), // 🔹 small gap between label & value
        Text(
          value,
          style: TextStyle(
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            color: valueColor,
          ),
        ),
      ],
    );
  }




  Widget _qtyButton(IconData icon, {VoidCallback? onTap, bool enabled = true}) {
    return InkWell(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFFFFE5E5) : Colors.grey[300],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          icon,
          size: 14,
          color: enabled ? Colors.red : Colors.grey,
        ),
      ),
    );
  }


}