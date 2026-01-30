import 'dart:convert';

import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/material.dart';
import '../../models/UserPermissions.dart';
import '../../models/order_list/order_list_model.dart';
// import '../../repositories/cancel_order_list_repository.dart';
import '../../repositories/order_list_repository.dart';
import '../widgets/navigationhelper.dart';
import '../widgets/top_bar.dart';
import '../widgets/bottom_nav_bar.dart';
import 'edit_order_screen.dart';
// import 'edit_kots_screen.dart';
// import 'edit_order_list.dart';

class OrdersDetailsScreen extends StatefulWidget {
  final String token;
  final String pin;
  final String restaurantId;
  final String restaurantName;
  final int orderId; // 👈 Pass selected order ID
  final UserPermissions? userPermissions;

  const OrdersDetailsScreen({
    super.key,
    required this.token,
    required this.pin,
    required this.restaurantId,
    required this.restaurantName,
    required this.orderId,
    this.userPermissions,
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

    setState(() {
      _selectedIndex = index;
    });
  }
  Color _statusColor(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case "completed":
        return Colors.green;
      case "pending":
        return Colors.orange;
      case "declined":
        return Colors.red;
      default:
        return Colors.grey;
    }
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

    final names = modifiersList.map<String>((m) {
      if (m is String) return m;
      if (m is Map) {
        return m['name']?.toString() ??
            m['modifier_name']?.toString() ??
            m['title']?.toString() ??
            '';
      }
      return '';
    }).where((e) => e.isNotEmpty).toList();

    debugPrint("✅ FINAL MODIFIER NAMES → $names");

    return names;
  }


  @override
  Widget build(BuildContext context) {
    final blockHeight = MediaQuery.of(context).size.height * 0.9;

    return Scaffold(
      backgroundColor: const Color(0xFFE5EFFF),

      /// 🔹 TOP BAR
      appBar: TopBar(
        token: widget.token,
        pin: widget.pin,
        userPermissions: _userPermissions,
        onPermissionsReceived: (permissions) {
          setState(() {
            _userPermissions = permissions;
          });
        },
      ),

      /// 🔹 BODY
      body: FutureBuilder<List<OrderlistModel>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No Orders Found"));
          }

          // ✅ Pick the correct order by ID
          final orderModel = snapshot.data!.firstWhere(
                (o) => o.orderId == widget.orderId,
            orElse: () => snapshot.data!.first,
          );

          final order = orderModel.toMapForView();
          final kots = (order["kots"] as List<dynamic>?) ?? [];

          // Initialize selected KOT if null
          if (selectedKotId == null && kots.isNotEmpty) {
            selectedKotId = kots.first["kotNo"];
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


          return Center(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.all(10),
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
              child: Row(
                children: [
                  Flexible(
                    flex: 1,
                    child: Container(
                      height: blockHeight,
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5EFFF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Left: Back button
                                GestureDetector(
                                  onTap: () => Navigator.pop(context, true),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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


                                // Right buttons: Edit Order + Cancel Order
                                Row(
                                  children: [
                                    // Edit Order Button
                                    if ((orderModel.status ?? '').toLowerCase() == 'completed')
                                      ElevatedButton(
                                        onPressed: () async {
                                          final bool? updated = await Navigator.push<bool>(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => EditOrdersListScreen(
                                                token: widget.token,
                                                pin: widget.pin,
                                                restaurantId: widget.restaurantId,
                                                restaurantName: widget.restaurantName,
                                                userPermissions: widget.userPermissions,
                                                orderId: orderModel.orderId!,
                                              ),
                                            ),
                                          );

                                          if (updated == true) {
                                            debugPrint("🔁 Refreshing View Order Screen");

                                            setState(() {
                                              _ordersFuture = _orderRepo.fetchOrders(widget.token);
                                              _justUpdated = true;
                                            });
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF4C5F7D),
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
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
                                    if ((orderModel.status ?? '').toLowerCase() == 'completed')
                                      GestureDetector(
                                        onTap: () {
                                          showDialog(
                                              context: context,
                                              barrierDismissible: false,
                                              builder: (context) => Dialog(
                                                backgroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(16),
                                                ),
                                                child: SizedBox(
                                                  width: 400,
                                                  child: Padding(
                                                    padding: const EdgeInsets.all(20),
                                                    child: Column(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [

                                                        /// 🔼 Top Image (You can replace asset path)
                                                        Image.asset(
                                                          'assets/cancelorder.png',
                                                          height: 90,
                                                        ),

                                                        const SizedBox(height: 16),

                                                        /// Title
                                                        const Text(
                                                          'Cancel Order?',
                                                          textAlign: TextAlign.center,
                                                          style: TextStyle(
                                                            fontSize: 22,
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                        ),

                                                        const SizedBox(height: 10),

                                                        /// Message
                                                        const Text(
                                                          'Are you sure do you want cancel the order?',
                                                          textAlign: TextAlign.center,
                                                          style: TextStyle(
                                                            fontSize: 16,
                                                            color: Colors.black54,
                                                          ),
                                                        ),

                                                        const SizedBox(height: 24),

                                                        /// Buttons Row
                                                        Row(
                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                          children: [

                                                            /// Back Button
                                                            SizedBox(
                                                              width: 110,
                                                              child: OutlinedButton(
                                                                style: OutlinedButton.styleFrom(
                                                                  minimumSize: const Size(110, 40),
                                                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                                                  side: const BorderSide(color: Colors.grey),
                                                                  shape: RoundedRectangleBorder(
                                                                    borderRadius: BorderRadius.circular(8),
                                                                  ),
                                                                ),
                                                                onPressed: () {
                                                                  Navigator.pop(context);
                                                                },
                                                                child: const Text(
                                                                  'Back',
                                                                  style: TextStyle(fontSize: 15),
                                                                ),
                                                              ),
                                                            ),

                                                            const SizedBox(width: 14),

                                                            /// Yes Done Button
                                                            SizedBox(
                                                              width: 130,
                                                              child: ElevatedButton(
                                                                style: ElevatedButton.styleFrom(
                                                                  backgroundColor: const Color(0xFFFE6464),
                                                                  minimumSize: const Size(130, 40),
                                                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                                                  shape: RoundedRectangleBorder(
                                                                    borderRadius: BorderRadius.circular(8),
                                                                  ),
                                                                ),
                                                                onPressed: () {
                                                                  Navigator.pop(context);

                                                                  if (orderModel.orderId != null) {
                                                                    // cancelOrder(orderModel);

                                                                  }
                                                                },
                                                                child: const Text(
                                                                  'Yes, Done',
                                                                  style: TextStyle(fontSize: 15,color: Colors.white,),

                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        )

                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              )
                                          );

                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          decoration: ShapeDecoration(
                                            color: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              side: const BorderSide(
                                                width: 0.8,
                                                color: Color(0xFFFE6464),
                                              ),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: const [
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
                                                  fontFamily: 'Kumbh Sans',
                                                  fontWeight: FontWeight.w400,
                                                  height: 0.75,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )


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
                                  Row(
                                    children: [

                                      Expanded(
                                        child: Container(
                                          height: 120,
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [

                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    "#${orderModel.orderId ?? '-'}",
                                                    style: const TextStyle(
                                                        fontWeight: FontWeight.bold, fontSize: 16),
                                                  ),
                                                  Text(
                                                    orderModel.date ?? "-",
                                                    style: const TextStyle(
                                                        fontWeight: FontWeight.bold, fontSize: 14),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              const Text(
                                                "Order Details",
                                                style: TextStyle(fontWeight: FontWeight.bold),
                                              ),

                                              // Order Details (Order Type + Table)
                                              Text(
                                                "Order Type  ${orderModel.orderType ?? '-'}${orderModel.tableName != null ? ', ${orderModel.tableName}' : ''}",
                                                style: const TextStyle(color: Colors.grey),
                                              ),
                                              const SizedBox(height: 4),

                                              // Additional Info: first KOT items names (like your screenshot)
                                              // if (orderModel.kotOrders != null && orderModel.kotOrders!.isNotEmpty)
                                              //   Text(
                                              //     "Additional Info: ${orderModel.kotOrders!.first.lineItems!.map((e) => e.name).join(', ')}",
                                              //     style: const TextStyle(color: Colors.grey),
                                              //     overflow: TextOverflow.ellipsis,
                                              //   ),
                                              // const SizedBox(height: 8),

                                              // Payment Type
                                              Text(
                                                "Payment Type  ${orderModel.paymentType ?? '-'}",
                                                style: const TextStyle(color: Colors.grey),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      const SizedBox(width: 12),

                                      // customer details
                                      Expanded(
                                        child: Container(
                                          height: 120,
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [

                                              Align(
                                                alignment: Alignment.topRight,
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: _statusColor(orderModel.status),
                                                    borderRadius: BorderRadius.circular(5),
                                                  ),
                                                  child: Text(
                                                    orderModel.status ?? '-',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),

                                              const SizedBox(height: 8),

                                              const Text(
                                                "Customer Details",
                                                style: TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                (orderModel.customerName != null &&
                                                    orderModel.customerName!.trim().isNotEmpty)
                                                    ? orderModel.customerName!
                                                    : "Customer Name",
                                                style: const TextStyle(color: Colors.grey),
                                              ),
                                              Text(
                                                (orderModel.customerPhone != null &&
                                                    orderModel.customerPhone!.trim().isNotEmpty)
                                                    ? orderModel.customerPhone!
                                                    : "Customer Number",
                                                style: const TextStyle(color: Colors.grey),
                                              ),

                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),


                                  const SizedBox(height: 10),

                                  // payment summary
                                  Expanded(
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text(
                                                "Payment Details",
                                                style: TextStyle(fontWeight: FontWeight.bold),
                                              ),

                                              // Show "Updated" if either the backend says yes OR _justUpdated is true
                                              if (_justUpdated || (order['is_updated']?.toString().toLowerCase() ?? '') == 'yes')
                                                Row(
                                                  children: [
                                                    Image.asset(
                                                      'assets/refreshicon.png',
                                                      width: 12,
                                                      height: 12,
                                                      color: Colors.orange,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    const Text(
                                                      "Updated",
                                                      style: TextStyle(
                                                        color: Colors.orange,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                            ],
                                          ),


                                          paymentRow(
                                            "Gross Total",
                                            "₹${orderModel.grossTotal ?? 0}",
                                            color: Colors.black,
                                            fontWeight: FontWeight.w500,
                                          ),

                                          paymentRow(
                                            "Coupon / Discounts",
                                            "-₹${orderModel.discount ?? 0}",
                                            color: Colors.green,
                                          ),
                                          ShaderMask(
                                            shaderCallback: (Rect bounds) {
                                              return LinearGradient(
                                                begin: Alignment.centerLeft,
                                                end: Alignment.centerRight,
                                                colors: [
                                                  Colors.black.withOpacity(0.1),
                                                  Colors.black.withOpacity(0.7),
                                                  Colors.black.withOpacity(0.1),
                                                ],
                                                stops: const [0.0, 0.5, 1.0],
                                              ).createShader(bounds);
                                            },
                                            blendMode: BlendMode.srcIn,
                                            child: const DottedLine(
                                              dashLength: 6,
                                              dashGapLength: 4,
                                              lineThickness: 1,
                                              direction: Axis.horizontal,
                                              dashColor: Colors.black,
                                            ),
                                          ),


                                          paymentRow(
                                            "Sub Total",
                                            "₹${orderModel.subTotal ?? 0}",
                                            color: Colors.black,
                                          ),

                                          paymentRow(
                                            "Tax @5% Food",
                                            "",
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),

                                          paymentRow(
                                            "CGST 2.5%",
                                            "₹${((orderModel.totalTax ?? 0) / 2).toStringAsFixed(2)}",
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),

                                          paymentRow(
                                            "SGST 2.5%",
                                            "₹${((orderModel.totalTax ?? 0) / 2).toStringAsFixed(2)}",
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),

                                          paymentRow(
                                            "Tax Alcohol @ Nil",
                                            "₹0",
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),

                                          ShaderMask(
                                            shaderCallback: (Rect bounds) {
                                              return LinearGradient(
                                                begin: Alignment.centerLeft,
                                                end: Alignment.centerRight,
                                                colors: [
                                                  Colors.black.withOpacity(0.1),
                                                  Colors.black.withOpacity(0.7),
                                                  Colors.black.withOpacity(0.1),
                                                ],
                                                stops: const [0.0, 0.5, 1.0],
                                              ).createShader(bounds);
                                            },
                                            blendMode: BlendMode.srcIn,
                                            child: const DottedLine(
                                              dashLength: 6,
                                              dashGapLength: 4,
                                              lineThickness: 1,
                                              direction: Axis.horizontal,
                                              dashColor: Colors.black,
                                            ),
                                          ),


                                          paymentRow(
                                            "Total Tax",
                                            "₹${orderModel.totalTax ?? 0}",
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                          ),

                                          paymentRow(
                                            "Net Total",
                                            "₹${orderModel.netTotal ?? 0}",
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                          ),

                                          paymentRow(
                                            "Merchant Discount",
                                            "-₹${orderModel.merchantDiscount ?? 0}",
                                            color: Colors.blue,
                                          ),
                                          paymentRow(
                                            "Round Off",
                                            "${(orderModel.roundOff ?? 0) >= 0 ? '+' : '-'}₹${(orderModel.roundOff ?? 0).abs().toStringAsFixed(2)}",
                                            color: Colors.grey,
                                          ),



                                          ShaderMask(
                                            shaderCallback: (Rect bounds) {
                                              return LinearGradient(
                                                begin: Alignment.centerLeft,
                                                end: Alignment.centerRight,
                                                colors: [
                                                  Colors.black.withOpacity(0.1),
                                                  Colors.black.withOpacity(0.7),
                                                  Colors.black.withOpacity(0.1),
                                                ],
                                                stops: const [0.0, 0.5, 1.0],
                                              ).createShader(bounds);
                                            },
                                            blendMode: BlendMode.srcIn,
                                            child: const DottedLine(
                                              dashLength: 6,
                                              dashGapLength: 4,
                                              lineThickness: 1,
                                              direction: Axis.horizontal,
                                              dashColor: Colors.black,
                                            ),
                                          ),


                                          paymentRow(
                                            "Net Payable",
                                            "₹${orderModel.netPayable ?? 0}",
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ],
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
                  ),

                  /// 🔹 RIGHT BLOCK (KOTs)
                  Flexible(
                    flex: 1,
                    child: Container(
                      height: blockHeight,
                      margin: const EdgeInsets.all(6),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5EFFF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ✅ Only show summary if updated
                          if ((_justUpdated) || ((order['is_updated']?.toString().toLowerCase() ?? '') == 'yes'))
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Top label
                                  const Text(
                                    "Old payment Details",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  // Bottom row with values and vertical divider
                                  IntrinsicHeight(
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        // Net Payable
                                        Expanded(
                                          child: Row(
                                            children: [
                                              const Text(
                                                "Net Payable Amount- ",
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              ),
                                              Text(
                                                "₹${order['order_prev_total']?.toStringAsFixed(2) ?? '0.00'}",
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Vertical Divider
                                        Container(
                                          width: 1,
                                          color: Colors.grey[300],
                                          margin: const EdgeInsets.symmetric(horizontal: 12),
                                        ),

                                        // Reason for edit
                                        Expanded(
                                          child: Row(
                                            children: [
                                              const Text(
                                                "Reason for edit- ",
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              ),
                                              Expanded(
                                                child: Text(
                                                  (order['is_updated'] == 'yes' &&
                                                      order['updatedRemarks'] != null &&
                                                      order['updatedRemarks'].toString().trim().isNotEmpty)
                                                      ? order['updatedRemarks'].toString()
                                                      : '-',

                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  maxLines: 3, // or null for unlimited
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),

                                            ],
                                          ),
                                        ),


                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),




                          // 🔹 KOT TABLE
                          Expanded(child: buildSelectedKotCard(order)),
                        ],
                      ),
                    ),
                  )

                ],
              ),
            ),
          );
        },
      ),

      /// 🔹 BOTTOM NAV BAR
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        userPermissions: _userPermissions,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  Widget buildSelectedKotCard(Map<String, dynamic> order) {
    final kots = (order["kots"] as List<dynamic>?) ?? [];

    Map<String, dynamic>? selectedKot = kots
        .cast<Map<String, dynamic>?>()
        .firstWhere(
          (kot) => kot?["kotNo"] == selectedKotId,
      orElse: () => null,
    );

    if (selectedKot == null) {
      return const Center(
        child: Text("No KOT Selected", style: TextStyle(color: Colors.grey)),
      );
    }
    String kotReason = "-";
    if (selectedKot["meta_data"] != null) {
      final metaData = (selectedKot["meta_data"] as List<dynamic>);
      final reasonMeta = metaData.firstWhere(
            (m) => m["key"] == "kot_reason",
        orElse: () => {"value": "-"},
      );
      kotReason = reasonMeta["value"] ?? "-";
    }

    return buildKOTCard(selectedKot, kots, );
  }

  Widget buildKOTCard(Map<String, dynamic> selectedKot, List<dynamic> kots) {
    final items = (selectedKot["items"] as List<dynamic>?) ?? [];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "KOT’s",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF125BCE), // blue background
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: selectedKotId,
                    hint: const Text(
                      "Select KOT",
                      style: TextStyle(color: Colors.white),
                    ),
                    icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white), // white icon
                    dropdownColor: const Color(0xFF125BCE), // dropdown menu blue
                    style: const TextStyle(color: Colors.white), // selected text white
                    items: kots.map((kot) {
                      return DropdownMenuItem<int>(
                        value: kot["kotNo"],
                        child: Text(
                          "KOT ${kot["kotNo"]}",
                          style: const TextStyle(color: Colors.white), // dropdown items text
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedKotId = value;
                      });
                    },
                  ),
                ),
              )


            ],
          ),
          const SizedBox(height: 10),

          /// 🔹 Table Header
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF999393),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            child: Row(
              children: const [
                Expanded(
                  flex: 1,
                  child: Text(
                    "#",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    "Item Name",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "Quantity",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "Amount",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          /// 🔹 Items List
          /// 🔹 Items List (SCROLLABLE)
          SizedBox(
            height: 300, // 🔥 adjust based on your UI layout
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                bool isLast = index == items.length - 1;

                final List<String> modifierNames =
                extractModifierNames(item as Map<String, dynamic>);

                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: const BorderSide(color: Color(0xFFB9B9B9)),
                      left: const BorderSide(color: Color(0xFFB9B9B9)),
                      right: const BorderSide(color: Color(0xFFB9B9B9)),
                    ),
                    borderRadius: isLast
                        ? const BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    )
                        : BorderRadius.zero,
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
                              item['name']?.toString() ?? "-",
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),

                            if (modifierNames.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  modifierNames.join(", "),
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
                        child: Text(
                          "${item['qty'] ?? 0} x ${item['item_price'] ?? 0}",
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          item['amount']?.toString() ?? "-",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          )


        ],
      ),
    );
  }

  // payment summary
  Widget paymentRow(
      String title,
      String amount, {
        Color color = Colors.black,
        double fontSize = 14,
        FontWeight fontWeight = FontWeight.normal,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(color: color, fontSize: fontSize, fontWeight: fontWeight),
          ),
          Text(
            amount,
            style: TextStyle(color: color, fontSize: fontSize, fontWeight: fontWeight),
          ),
        ],
      ),
    );
  }
}