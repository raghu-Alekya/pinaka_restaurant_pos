import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/material.dart';
import '../../models/UserPermissions.dart';
import '../../models/order_list/order_list_model.dart';
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


  UserPermissions? _userPermissions;
  int _selectedIndex = 4;
  bool _isUpdateEnabled = false; // initially disabled

  Future<List<OrderlistModel>>? _ordersFuture;

  int? _selectedKotId;
  KotOrder? _selectedKot;
  // calculated net payable from edit kot
  double getUpdatedNetPayable() {
    final items = _selectedKot?.lineItems ?? [];
    return items.fold<double>(
      0.0,
          (sum, item) => sum + (item.amount ?? 0),
    );
  }
  double? _baseNetPayable;
  double? _originalItemsTotal;
  bool _isKotEdited = false;



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
      print("Selected KOT: $_selectedKotId with ${_selectedKot?.lineItems?.length ?? 0} items");
      print("Current Net Payable: ₹${getUpdatedNetPayable().toStringAsFixed(2)}");
    });
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
                            onPressed: () => Navigator.pop(context),
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
                              "₹${(order.netPayable ?? 0).toStringAsFixed(2)}",
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
                            onPressed:
                                () {},

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
  // LEFT PANEL (Order info + KOT selector) static data
  // =========================================================
  Widget _buildLeftPanel(OrderlistModel order, List<KotOrder> kots) {
    final items = _selectedKot?.lineItems ?? [];

    // Calculate Net Payable from selected KOT items
    final double netPayable = items.fold<double>(
      0.0,
          (sum, item) => sum + (item.amount ?? 0).toDouble(),
    );

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
            // const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "KOT ID: ${_selectedKot?.kotOrderId ?? '-'}",
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

            // 🔹 Table Header
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

            //  Items list (no editing)
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
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

                              // if ((item.modifiers ?? []).isNotEmpty)
                              //   Padding(
                              //     padding: const EdgeInsets.only(top: 2),
                              //     child: Text(
                              //       item.modifiers!.join(", "),
                              //       style: const TextStyle(
                              //         fontSize: 12,
                              //         color: Colors.grey,
                              //       ),
                              //     ),
                              //   ),
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

            const SizedBox(height: 10),

            // 🔹 Only Net Payable at the bottom
            // _infoRow(
            //   "Net Payable",
            //   "₹${order.netPayable ?? 0}",
            //   bold: true,
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
    final items = kot.lineItems ?? [];

    int getItemsCount() {
      return items.fold<int>(0, (sum, item) => sum + ((item.quantity ?? 0).toInt()));
    }

    double getNetPayable() {
      return items.fold<double>(0.0, (sum, item) => sum + ((item.amount ?? 0).toDouble()));
    }

    return StatefulBuilder(
      builder: (context, setInnerState) {
        return Container(
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
              Center(
                child: const Text(
                  "To edit an item, please select the item and provide a reason for removing",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Color(0xFF092044)),
                ),
              ),
              const SizedBox(height: 10),

              /// Header
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

              /// Items list
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
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
                                _qtyButton(Icons.remove, onTap: () {
                                  setInnerState(() {
                                    if ((item.quantity ?? 0) > 1) {
                                      final double unitPrice =
                                          (item.amount ?? 0) / (item.quantity ?? 1);

                                      item.quantity = item.quantity! - 1;
                                      item.amount = unitPrice * item.quantity!;
                                    }

                                  });
                                  // Refresh parent so summary row updates
                                  setState(() {});
                                }),



                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text("${item.quantity ?? 0}"),
                                ),
                                _qtyButton(Icons.add, onTap: () {
                                  setInnerState(() {
                                    final double unitPrice =
                                        (item.amount ?? 0) / (item.quantity ?? 1);

                                    item.quantity = (item.quantity ?? 0) + 1;
                                    item.amount = unitPrice * item.quantity!;

                                  });
                                  setState(() {});
                                }),



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

              const SizedBox(height: 10),

              //   Update KOT + Update Details
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // _summaryRow(
                  //   "Updated Net Payable",
                  //   "₹${getNetPayable().toStringAsFixed(2)}",
                  //   bold: true,
                  //   valueColor: const Color(0xFF373535),
                  // ),


                  const Spacer(),

                  // Update KOT button
                  // ElevatedButton(
                  //   onPressed: () {
                  //     setState(() { // ✅ update outer state
                  //       _isUpdateEnabled = true; // now properly enables Update Details
                  //     });
                  //   },
                  //   style: ElevatedButton.styleFrom(
                  //     backgroundColor: const Color(0xFF125BCE),
                  //     padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  //     shape: RoundedRectangleBorder(
                  //       borderRadius: BorderRadius.circular(8),
                  //     ),
                  //   ),
                  //   child: const Text(
                  //     "Update KOT",
                  //     style: TextStyle(
                  //       fontSize: 14,
                  //       fontWeight: FontWeight.w600,
                  //       color: Colors.white,
                  //     ),
                  //   ),
                  // ),

                ],
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