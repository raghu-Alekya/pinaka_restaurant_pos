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
  String? _updateMessage; // null when no message

// Step 1: Just fetch net payable (no calculation)
  String getNetPayable(OrderlistModel order) {
    double netPayable = (order.netPayable ?? 0).toDouble();
    return "₹${netPayable.toStringAsFixed(2)}";
  }

  List<LineItem> _leftPanelItems = [];
  double _selectedKotOriginalTotal = 0.0;


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
      _selectedKot = kots.firstWhere((k) => k.kotOrderId == kotId);

      _selectedKotOriginalTotal = (_selectedKot?.lineItems ?? [])
          .fold(0.0, (sum, i) => sum + (i.totalWoTax ?? 0));

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
          unitPrice: qty > 0 ? totalWoTax / qty : 0.0, // 🔒 LOCKED
          modifiers: parseModifiers(item.modifiers),
        );
      }).toList();
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
  void _refreshOrders() {
    setState(() {
      _netPayableInitialized = false; // re-init tax & net payable
      _selectedKotId = null;
      _selectedKot = null;
      _leftPanelItems.clear();
      _ordersFuture = _orderRepo.fetchOrders(widget.token);
    });
  }

  Future<void> _updateKot() async {
    if (_selectedKot == null) return;

    if (selectedReason == null || selectedReason!.isEmpty) {
      print("⚠️ No reason selected");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a reason")),
      );
      return;
    }

    final repo = EditOrderlistRepository(
      baseUrl: AppConstants.baseApiPath,
      token: widget.token,
    );

    final kotId = _selectedKot!.kotOrderId;

    print("🔵 Preparing to update KOT");
    print("📌 Order ID: ${widget.orderId}");
    print("📌 Selected KOT ID: $kotId");
    print("📌 Selected Reason: $selectedReason");
    print("📌 Remarks: ${_remarksController.text.trim()}");

    try {
      // 1️⃣ Fetch full parent order
      final order = await repo.fetchOrder(widget.orderId);
      // print("✅ Fetched order successfully: Order ID ${order.id}");

      // 2️⃣ Find selected KOT
      final selectedKotInOrder = order.kotOrders?.firstWhere(
            (k) => k.kotOrderId == kotId,
        orElse: () => throw Exception("Selected KOT not found"),
      );
      print("✅ Selected KOT found: Status ${selectedKotInOrder?.status}");

      // 3️⃣ Build line items payload
      final List<Map<String, dynamic>> lineItemsPayload = [];

      for (final item in _leftPanelItems) {
        final qty = item.quantity ?? 0;

        // 🟢 EXISTING ITEM
        if (item.lineItemId != null) {
          if (qty > 0) {
            lineItemsPayload.add({
              "id": item.lineItemId,   // ✅ preserve ID
              "quantity": qty,
            });
          } else {
            lineItemsPayload.add({
              "id": item.lineItemId,
              "quantity": qty,
              // "_destroy": true,       // ✅ explicit delete (IMPORTANT)
            });
          }
        }

        // 🟢 NEW ITEM
        else if (item.itemId != null && qty > 0) {
          lineItemsPayload.add({
            "product_id": item.itemId,
            "quantity": qty,
          });
        }
      }


      if (lineItemsPayload.isEmpty) {
        print("⚠️ No valid line items to update.");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("⚠️ No valid items to update")),
        );
        return;
      }

      // 4️⃣ Meta data payload
      final metaDataPayload = [
        if (_remarksController.text.trim().isNotEmpty)
          {"key": "kot_remarks", "value": _remarksController.text.trim()},
        {"key": "kot_remarks", "value": selectedReason},
      ];

      print("📤 Meta Data Payload: ${jsonEncode(metaDataPayload)}");

      final payload = {
        "line_items": lineItemsPayload,
        "meta_data": metaDataPayload,
      };

      print("📤 Final Payload Sent to Backend: ${jsonEncode(payload)}");

      // 5️⃣ Handle completed KOTs
      final originalStatus = _selectedKot?.status ?? "processing";
      if (originalStatus == "completed") {
        print("⚡ Changing status from completed → processing");
        await repo.updateOrderRaw(
          orderId: widget.orderId,
          kotOrderId: kotId,
          payload: {"status": "processing"},
        );
      }

      // 6️⃣ Update KOT
      final success = await repo.updateOrderRaw(
        orderId: widget.orderId,
        kotOrderId: kotId,
        payload: payload,
      );

      if (!success) throw Exception("Update failed");
      print("✅ KOT Updated Successfully");
      setState(() {
        _updateMessage = "KOT updated Successfully. Final Net payable updated.";
      });
// 🔄 REFRESH SCREEN DATA
//       _refreshOrders();
      // 7️⃣ Restore original status
      if (originalStatus == "completed") {
        print("⚡ Restoring status from processing → completed");
        await repo.updateOrderRaw(
          orderId: widget.orderId,
          kotOrderId: kotId,
          payload: {"status": "completed"},
        );

// 🔄 THEN refresh UI
        _refreshOrders();
      }

      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(content: Text("✅ KOT Updated Successfully")),
      // );
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
                unitPrice: qty > 0 ? totalWoTax / qty : 0.0, // 🔒 SAME LOGIC
                modifiers: parseModifiers(item.modifiers),
              );
            }).toList();

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
                                          child:_summaryRow(
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
                                            "₹${_leftPanelItems.fold<double>(
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

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox(width: 15),
                          Expanded(
                            child: _infoRow(
                              "Order Net Payable",
                              "₹${(order.netPayable ?? 0).round()}",
                              bold: true,
                            ),
                          ),

                          const SizedBox(width: 30),
                          Expanded(
                            child: _infoRow(
                              "Order Updated Net Payable",
                              "₹${_dynamicNetPayable.round()}",
                              bold: true,
                            ),
                          ),






                        ],
                      ),



                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // ✅ Enter Reason (fixed width, doesn't shrink)
                          if (kot_remarks.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.all(8),
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
                                  SizedBox(
                                    width: 450, // fixed width for dropdown
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

                          // ✅ Spacer only if no success message
                          if (_updateMessage == null) const Spacer(),

                          // ✅ Success message (Flexible)
                          if (_updateMessage != null) ...[
                            const SizedBox(width: 12), // small space before message
                            Flexible(
                              child: Row(
                                children: [
                                  Image.asset(
                                    "assets/success_tick.png",
                                    width: 20,
                                    height: 20,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      _updateMessage!,
                                      style: const TextStyle(
                                        color: Colors.green,
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

                          // ✅ Update KOT button
                          ElevatedButton(
                            onPressed: _updateKot,
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
                  Expanded(flex: 2, child: Text("Amount", style: TextStyle(fontWeight: FontWeight.w400,color: Color(0xFFF5F5F5)))),
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
                      color:Color(0xFFFBFBFC),
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
                        Expanded(
                          flex: 2,
                          child: Text(
                            "₹${(item.totalWoTax ?? 0).toStringAsFixed(2)}",
                          ),
                        ),


                      ],
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
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                child: const Row(
                  children: [
                    Expanded(flex: 1, child: Text("#",style: TextStyle(fontWeight: FontWeight.w400,color: Color(0xFFF5F5F5)))),
                    Expanded(flex: 3, child: Text("Item",style: TextStyle(fontWeight:FontWeight.w400,color: Color(0xFFF5F5F5)))),
                    Expanded(flex: 2, child: Text("Quantity",style: TextStyle(fontWeight:FontWeight.w400,color: Color(0xFFF5F5F5)))),
                    Expanded(flex: 2, child: Text("Amount",style: TextStyle(fontWeight: FontWeight.w400,color: Color(0xFFF5F5F5)))),
                  ],
                ),
              ),

              // Items List
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    // final double unitPrice =
                    //     (item.amount ?? 0).toDouble() / ((item.quantity ?? 1).toDouble());

                    final modifiers = parseModifiers(item.modifiers); // same function as left panel

                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color:Color(0xFFFBFBFC),
                        border: Border(
                          bottom: BorderSide(color: Colors.grey[300]!),
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
                          Expanded(
                            flex: 2,
                            child: Row(
                              children: [

                                // Decrement button
                                _qtyButton(
                                  Icons.remove,
                                  onTap: (item.quantity ?? 0) > 0
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
                                  child: Text("${item.quantity ?? 0}"),
                                ),
                                // Increment
                                _qtyButton(
                                  Icons.add,
                                  onTap: (item.quantity ?? 0) < (item.maxQty ?? 0)
                                      ? () {
                                    setInnerState(() {
                                      item.quantity = (item.quantity ?? 0) + 1;
                                      item.totalWoTax = item.unitPrice! * item.quantity!;
                                    });

                                    setState(() {
                                      _dynamicNetPayable += item.unitPrice!;
                                    });
                                  }
                                      : null, // 🔒 stops increase above original qty
                                ),





                              ],
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text("₹${( item.totalWoTax ?? 0).toStringAsFixed(2)}"),
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
              //       "KOT #${_selectedKot?.kotOrderId ?? '-'} - Amount",
              //       "₹${_leftPanelItems.fold<double>(
              //         0.0,
              //             (sum, i) => sum + (i.totalWoTax ?? 0),
              //       ).toStringAsFixed(2)}",
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
      padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 12),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w500 : FontWeight.normal,
              fontSize: 12, // reduced from 19
              fontFamily: 'Inter',
              color: labelColor,
            ),
          ),
          const SizedBox(width: 280), // fixed width gap
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w500 : FontWeight.normal,
              fontSize: 14, // reduced from 24
              fontFamily: 'Inter',
              color: valueColor,
            ),
          ),
        ],
      ),
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