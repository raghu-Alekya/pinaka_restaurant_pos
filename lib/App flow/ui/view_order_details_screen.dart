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
import 'package:pinaka_restaurant_pos/models/payment/payment_summary_model.dart' as psm;
import '../widgets/navigationhelper.dart';
import '../widgets/top_bar.dart';
import '../widgets/bottom_nav_bar.dart';
import 'CheckinPopup.dart';
import 'edit_order_screen.dart';
// import 'edit_kots_screen.dart';
// import 'edit_order_list.dart';

class OrdersDetailsScreen extends StatefulWidget {
  final String token;
  final String pin;
  final String restaurantId;
  final String restaurantName;
  final int orderId; //  Pass selected order ID
  final UserPermissions? userPermissions;
  final Function(UserPermissions)? onPermissionsReceived;

  const OrdersDetailsScreen({
    super.key,
    required this.token,
    required this.pin,
    required this.restaurantId,
    required this.restaurantName,
    required this.orderId,
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


  void _onKotSelected(int kotId) {
    setState(() {
      selectedKotId = kotId;
      isVoidedLoading = true;
      voidedItemsResponse = null;
    });

    loadVoidedItems(kotId);
  }

  @override
  void initState() {
    super.initState();
    _userPermissions = widget.userPermissions;
    _ordersFuture = _orderRepo.fetchOrders(widget.token);
    _loadPermissions();
    _loadCurrency();   // <-- Add this
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
    setState(() => isVoidedLoading = true);

    try {
      final result = await OrderstatusRepository().fetchVoidedItems(
        kotOrderId: kotOrderId,
        token:  widget.token,
      );

      setState(() {
        voidedItemsResponse = result;
      });
    } catch (e) {
      debugPrint("Voided fetch error: $e");
    } finally {
      setState(() => isVoidedLoading = false);
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
  void _reloadAfterEdit() {
    setState(() {
      _ordersFuture = _orderRepo.fetchOrders(widget.token);
      isVoidedLoading = true;
      voidedItemsResponse = null;
    });

    if (selectedKotId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        loadVoidedItems(selectedKotId!);
      });
    }
  }

  Future<void> _cancelCompletedOrder(OrderlistModel orderModel) async {
    if (orderModel.orderId == null) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
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
      backgroundColor: const Color(0xFFF6F6F6),
      // TOP BAR
      appBar: TopBar(
        token: widget.token,
        pin: widget.pin,restaurantId: widget.restaurantId,
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
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF202433)
                            : const Color(0xFFF6F6F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
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

                                // Right buttons: Edit Order + Cancel Order
                                Row(
                                  children: [

                                    // Edit Order Button
                                    if ((orderModel.status ?? '').toLowerCase() == 'completed')
                                      ElevatedButton(
                                        onPressed: !canEditOrder
                                            ? null
                                            : () async {
                                          // order with merchant discount
                                          if ((orderModel.merchantDiscount ?? 0) > 0) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: const Text(
                                                  'Order with Merchant Discount is not editable',
                                                  style: TextStyle(color: Colors.white),

                                                ),
                                                duration: Duration(seconds: 1),
                                                backgroundColor: Colors.redAccent,
                                              ),
                                            );
                                            return;
                                          }
                                          final String role = (_userPermissions?.role ?? '').toLowerCase();
                                          // 1 TOP-BAR ROLE CHECK (blocks captains)
                                          if (!((_userPermissions?.canEditOrder ?? false) &&
                                              (role == 'administrator' ||
                                                  role == 'manager' ||
                                                  role == 'merchant'))) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Only administrators, managers, and merchants can edit orders',
                                                ),
                                                duration: Duration(seconds: 1),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                            return;
                                          }
                                          // 3️ PIN-ENTERED USER MUST BE MANAGER
                                          // Permission check from login response
                                          // if (!(_userPermissions?.canEditOrder ?? false)) {
                                          //   ScaffoldMessenger.of(context).showSnackBar(
                                          //     const SnackBar(
                                          //       content: Text("Only managers can edit orders"),
                                          //       duration: Duration(seconds: 1),
                                          //       backgroundColor: Colors.red,
                                          //     ),
                                          //   );
                                          //   return;
                                          // }

                                          // 4️ SAME MANAGER DOUBLE CHECK
                                          // final String pinEnteredManagerId = _permissions!.userId;
                                          // final String? orderCompletedById =
                                          //     orderModel.completedByUserId;
                                          //
                                          // if (orderCompletedById != null &&
                                          //     pinEnteredManagerId != orderCompletedById) {
                                          //   ScaffoldMessenger.of(context).showSnackBar(
                                          //     const SnackBar(
                                          //       content: Text(
                                          //         'Only the same manager who completed this order can edit it.',
                                          //       ),
                                          //       duration: Duration(seconds: 1),
                                          //       backgroundColor: Colors.red,
                                          //     ),
                                          //   );
                                          //   return;
                                          // }

                                          //  OPTIONAL: ensure same top-bar manager & PIN manager
                                          // if (pinEnteredManagerId != originalLoggedInUserId) {
                                          //   ScaffoldMessenger.of(context).showSnackBar(
                                          //     const SnackBar(
                                          //       content: Text(
                                          //         'PIN must belong to the logged-in manager.',
                                          //       ),
                                          //       duration: Duration(seconds: 1),
                                          //       backgroundColor: Colors.red,
                                          //     ),
                                          //   );
                                          //   return;
                                          // }

                                          // 5️ Navigation
                                          final bool? updated = await Navigator.push<bool>(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => EditOrdersListScreen(
                                                token: widget.token,
                                                pin: widget.pin,
                                                restaurantId: widget.restaurantId,
                                                restaurantName: widget.restaurantName,
                                                userPermissions: _permissions,
                                                orderId: orderModel.orderId!,

                                              ),
                                            ),
                                          );

                                          if (updated == true) {
                                            _reloadAfterEdit();
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
                                    // Cancel Order Button
                                    if ((orderModel.status ?? '').toLowerCase() == 'completed')
                                      ElevatedButton(
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            barrierDismissible: false,
                                            builder: (context) => Dialog(
                                              backgroundColor: theme.cardColor,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                              child:  SizedBox(
                                                width: 400,
                                                child: Padding(
                                                  padding: const EdgeInsets.all(20),
                                                  child: Column(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Image.asset(
                                                        'assets/cancelorder.png',
                                                        height: 90,
                                                      ),
                                                      const SizedBox(height: 16),

                                                      Text(
                                                        'Cancel Order?',
                                                        textAlign: TextAlign.center,
                                                        style: theme.textTheme.titleLarge?.copyWith(
                                                          fontSize: 22,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),

                                                      const SizedBox(height: 10),

                                                      Text(
                                                        'Are you sure you want to cancel the order?',
                                                        textAlign: TextAlign.center,
                                                        style: theme.textTheme.bodyMedium?.copyWith(
                                                          fontSize: 16,
                                                          color: isDark ? Colors.white70 : Colors.black54,
                                                        ),
                                                      ),

                                                      const SizedBox(height: 24),

                                                      Row(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          SizedBox(
                                                            width: 110,
                                                            child: OutlinedButton(
                                                              onPressed: () => Navigator.pop(context),
                                                              style: OutlinedButton.styleFrom(
                                                                minimumSize: const Size(110, 40),
                                                                backgroundColor: isDark
                                                                    ? const Color(0xFF2A2F3D)
                                                                    : Colors.white,
                                                                side: BorderSide(
                                                                  color: theme.dividerColor,
                                                                ),
                                                                shape: RoundedRectangleBorder(
                                                                  borderRadius: BorderRadius.circular(8),
                                                                ),
                                                              ),
                                                              child: Text(
                                                                'Back',
                                                                style: TextStyle(
                                                                  color: theme.textTheme.bodyLarge?.color,
                                                                ),
                                                              ),
                                                            ),
                                                          ),

                                                          const SizedBox(width: 14),

                                                          SizedBox(
                                                            width: 130,
                                                            child: ElevatedButton(
                                                              onPressed: () {
                                                                Navigator.pop(context);
                                                                _cancelCompletedOrder(orderModel);
                                                              },
                                                              style: ElevatedButton.styleFrom(
                                                                backgroundColor: const Color(0xFFFE6464),
                                                                minimumSize: const Size(130, 40),
                                                                shape: RoundedRectangleBorder(
                                                                  borderRadius: BorderRadius.circular(8),
                                                                ),
                                                              ),
                                                              child: const Text(
                                                                'Yes, Done',
                                                                style: TextStyle(color: Colors.white),
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
                                          backgroundColor: Theme.of(context).cardColor,
                                          elevation: 2,
                                          shadowColor: const Color(0x554C5F7D),
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
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
                                            color: theme.cardColor,
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                MainAxisAlignment
                                                    .spaceBetween,
                                                children: [
                                                  Text(
                                                    "Order Details",
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),

                                                  // Text(
                                                  //   "#${orderModel.orderId ?? '-'}",
                                                  //   style: const TextStyle(
                                                  //     fontWeight:
                                                  //     FontWeight.bold,
                                                  //     fontSize: 16,
                                                  //   ),
                                                  // ),
                                                  Text(
                                                    orderModel.date ?? "-",
                                                    style: theme.textTheme.bodySmall?.copyWith(
                                                      fontWeight: FontWeight.w700,
                                                      fontSize: 13,
                                                      color: isDark
                                                          ? Colors.white70
                                                          : const Color(0xFF555555),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              // const Text(
                                              //   "Order Details",
                                              //   style: TextStyle(
                                              //     fontWeight: FontWeight.bold,
                                              //   ),
                                              // ),
                                              RichText(
                                                text: TextSpan(
                                                  children: [
                                                    TextSpan(
                                                      text: "Order ID : ",
                                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                        fontWeight: FontWeight.w400,
                                                        fontSize: 14,
                                                        color: Theme.of(context).brightness == Brightness.dark
                                                            ? Colors.white70
                                                            : Colors.grey,
                                                      ),
                                                    ),
                                                    TextSpan(
                                                      text: "${orderModel.orderId ?? '-'}",
                                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 14,
                                                        color: Theme.of(context).brightness == Brightness.dark
                                                            ? Colors.white
                                                            : const Color(0xFF4C5F7D),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 6),

                                              // Order Details (Order Type + Table)
                                              RichText(
                                                text: TextSpan(
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey, // default for label
                                                  ),
                                                  children: [
                                                    const TextSpan(
                                                      text: "Order Type : ",
                                                    ),
                                                    TextSpan(
                                                      text:
                                                      "${orderModel.orderType ?? '-'}"
                                                          "${orderModel.tableName != null ? ', ${orderModel.tableName}' : ''}",
                                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                        fontWeight: FontWeight.w400,
                                                        color: Theme.of(context).brightness == Brightness.dark
                                                            ? Colors.white
                                                            : Colors.black,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),

                                              const SizedBox(height: 6),

                                              // Additional Info: first KOT items names (like your screenshot)
                                              // if (orderModel.kotOrders != null && orderModel.kotOrders!.isNotEmpty)
                                              //   Text(
                                              //     "Additional Info: ${orderModel.kotOrders!.first.lineItems!.map((e) => e.name).join(', ')}",
                                              //     style: const TextStyle(color: Colors.grey),
                                              //     overflow: TextOverflow.ellipsis,
                                              //   ),
                                              // const SizedBox(height: 8),

                                              // Payment Type
                                              RichText(
                                                text: TextSpan(
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey, // label color
                                                  ),
                                                  children: [
                                                    const TextSpan(
                                                      text: "Payment Type : ",
                                                    ),
                                                    TextSpan(
                                                      text: orderModel.paymentType ?? '-',
                                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                        fontWeight: FontWeight.w400,
                                                        color: Theme.of(context).brightness == Brightness.dark
                                                            ? Colors.white
                                                            : Colors.black,
                                                      ),
                                                    ),
                                                  ],
                                                ),
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
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: theme.cardColor,
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  // LEFT → Customer Details
                                                  const Text(
                                                    "Customer Details",
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),

                                                  const Spacer(),

                                                  // RIGHT → Status badge
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: _statusColor(orderModel.status),
                                                      borderRadius: BorderRadius.circular(5),
                                                    ),
                                                    child: Text(
                                                      orderModel.status ?? '-',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              // const SizedBox(height: 8),

                                              const SizedBox(height: 4),

                                              // Customer Name
                                              Row(
                                                // mainAxisAlignment:
                                                // MainAxisAlignment
                                                //     .spaceBetween,
                                                children: [
                                                  const Text(
                                                    "Customer Name :",
                                                    style: TextStyle(
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    orderModel.customerName !=
                                                        null &&
                                                        orderModel
                                                            .customerName!
                                                            .trim()
                                                            .isNotEmpty
                                                        ? orderModel
                                                        .customerName!
                                                        : "Guest", // fallback if empty
                                                    style: const TextStyle(
                                                      fontWeight:
                                                      FontWeight.w700,
                                                    ),
                                                  ),
                                                ],
                                              ),

                                              const SizedBox(height: 4),

                                              // Customer Phone
                                              Row(
                                                // mainAxisAlignment:
                                                // MainAxisAlignment
                                                //     .spaceBetween,
                                                children: [
                                                  const Text(
                                                    "Contact Number :",
                                                    style: TextStyle(
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    orderModel.customerPhone !=
                                                        null &&
                                                        orderModel
                                                            .customerPhone!
                                                            .trim()
                                                            .isNotEmpty
                                                        ? orderModel
                                                        .customerPhone!
                                                        : "-", // fallback if empty
                                                    style: const TextStyle(
                                                      fontWeight:
                                                      FontWeight.w700,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 8),

                                  // payment summary
                                  Expanded(
                                    child: Container(
                                      width: double.infinity,
                                      margin: const EdgeInsets.fromLTRB(4, 2, 4, 0),
                                      padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
                                      decoration: BoxDecoration(
                                        color: theme.cardColor,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      // child: ShaderMask(
                                      //   shaderCallback: (Rect bounds) {
                                      //     return const LinearGradient(
                                      //       begin: Alignment.topCenter,
                                      //       end: Alignment.bottomCenter,
                                      //       colors: [
                                      //         Colors.transparent,
                                      //         Colors.black,
                                      //         Colors.black,
                                      //         Colors.transparent,
                                      //       ],
                                      //       stops: [0.0, 0.06, 0.94, 1.0],
                                      //     ).createShader(bounds);
                                      //   },
                                      //   blendMode: BlendMode.dstIn,
                                      child: SingleChildScrollView(
                                        physics: const ClampingScrollPhysics(),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // ================= HEADER =================
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                const Text(
                                                  "Payment Details",
                                                  style: TextStyle(fontWeight: FontWeight.bold),
                                                ),
                                                if (orderModel.isUpdated?.toLowerCase() == 'yes')
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
                                              "$_currency${(orderModel.grossTotal ?? 0).toDouble().toStringAsFixed(2)}",
                                              fontWeight: FontWeight.w500,
                                            ),
                                            paymentRow(
                                              "Coupon / Discounts",
                                              "-$_currency${orderModel.totalCouponDiscount.toDouble().toStringAsFixed(2)}",
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
                                              "$_currency${(orderModel.subTotal ?? 0).toDouble().toStringAsFixed(2)}",
                                            ),

                                            paymentRow(
                                              "Tax @5% Food",
                                              "",
                                              color: Colors.grey,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                            ),

                                            Padding(
                                              padding: const EdgeInsets.only(left: 36),
                                              child: paymentRow(
                                                "CGST 2.5%",
                                                "$_currency${((orderModel.totalTax ?? 0) / 2).toStringAsFixed(2)}",
                                                fontSize: 10,
                                                color: Colors.grey,
                                              ),
                                            ),

                                            Padding(
                                              padding: const EdgeInsets.only(left: 36),
                                              child: paymentRow(
                                                "SGST 2.5%",
                                                "$_currency${((orderModel.totalTax ?? 0) / 2).toStringAsFixed(2)}",
                                                fontSize: 10,
                                                color: Colors.grey,
                                              ),
                                            ),


                                            paymentRow(
                                              "Tax @Alcohol Nil (Price inclusive of Excise Duty)",
                                              "${_currency}0.00",
                                              fontSize: 12,
                                              color: Colors.grey,
                                              fontWeight: FontWeight.w700,
                                            ),

                                            Align(
                                              alignment: Alignment.centerRight,
                                              child: FractionallySizedBox(
                                                widthFactor: 0.5,
                                                child: ShaderMask(
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
                                              ),
                                            ),

                                            paymentRow(
                                              "Total Tax",
                                              "$_currency${(orderModel.totalTax ?? 0).toDouble().toStringAsFixed(2)}",
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
                                              "Net Total",
                                              "$_currency${(orderModel.netTotal ?? 0).toStringAsFixed(2)}",
                                              fontWeight: FontWeight.bold,
                                            ),

                                            paymentRow(
                                              "Merchant Discount",
                                              "-$_currency${(orderModel.merchantDiscount ?? 0).toDouble().toStringAsFixed(2)}",
                                              color: Colors.blue,
                                            ),
                                            if ((orderModel.tipAmount ?? 0) > 0)
                                              paymentRow(
                                                "Tip Amount",
                                                "$_currency${(orderModel.tipAmount ?? 0).toDouble().toStringAsFixed(2)}",
                                                color: Colors.green,
                                              ),

                                            if ((orderModel.serviceChargeValue ?? 0) > 0)
                                              paymentRow(
                                                "Service Charges",
                                                "$_currency${(orderModel.serviceChargeValue ?? 0).toDouble().toStringAsFixed(2)}",
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
                                              "$_currency${(orderModel.netPayable ?? 0).toDouble().toStringAsFixed(2)}",
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),

                                            // const SizedBox(height: 10),
                                          ],
                                        ),
                                      ),
                                      // ),
                                    ),
                                  ),
                                  const SizedBox(height: 10,),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 40,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF3F65A1),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      onPressed: () async {
                                        try {
                                          Map<String, Map<String, dynamic>> consolidated = {};
                                          if (orderModel.kotOrders != null) {
                                            for (var kot in orderModel.kotOrders!) {
                                              if (kot.lineItems != null) {
                                                for (var lineItem in kot.lineItems!) {
                                                  final name = lineItem.name ?? '';
                                                  final modifiers = lineItem.modifiers ?? [];
                                                  final key = "$name-${modifiers.join(',')}";
                                                  if (consolidated.containsKey(key)) {
                                                    final existing = consolidated[key]!;
                                                    final currentQty = int.tryParse(existing['qty'].toString()) ?? 0;
                                                    final addedQty = lineItem.quantity ?? 0;
                                                    final newQty = currentQty + addedQty;
                                                    existing['qty'] = newQty;
                                                    existing['amount'] = (double.tryParse(existing['price'].toString()) ?? 0.0) * newQty;
                                                  } else {
                                                    consolidated[key] = {
                                                      "name": name,
                                                      "qty": lineItem.quantity ?? 0,
                                                      "price": lineItem.itemPrice ?? 0.0,
                                                      "amount": lineItem.amount ?? 0.0,
                                                      "modifiers": modifiers,
                                                    };
                                                  }
                                                }
                                              }
                                            }
                                          }

                                          final paymentSummaryObj = psm.PaymentSummary(
                                            restaurantId: orderModel.restaurantId ?? 0,
                                            orderId: orderModel.orderId ?? 0,
                                            grossTotal: (orderModel.grossTotal ?? 0).toDouble(),
                                            tax: (orderModel.totalTax ?? 0).toDouble(),
                                            fees: 0.0,
                                            discount: (orderModel.merchantDiscount ?? 0).toDouble(),
                                            coupons: orderModel.totalCouponDiscount.toDouble(),
                                            tipAmount: (orderModel.tipAmount ?? 0).toDouble(),
                                            netTotal: (orderModel.netPayable ?? orderModel.netTotal ?? 0).toDouble(),
                                            lineItems: consolidated.values.map((item) {
                                              return psm.LineItem(
                                                productId: 0,
                                                variationId: 0,
                                                name: item['name'].toString(),
                                                qty: int.tryParse(item['qty'].toString()) ?? 0,
                                                price: double.tryParse(item['price'].toString()) ?? 0.0,
                                                total: double.tryParse(item['amount'].toString()) ?? 0.0,
                                                tax: 0.0,
                                                taxClass: 'food',
                                                modifiers: List<String>.from(item['modifiers'] ?? []),
                                                modifierAmount: 0.0,
                                              );
                                            }).toList(),
                                            tableId: orderModel.tableId ?? 0,
                                            tableName: orderModel.tableName ?? "",
                                            zoneId: orderModel.zoneId ?? 0,
                                            modifiersTaxable: false,
                                            isNoCharge: false,
                                            couponDetails: orderModel.couponDetails?.map((e) {
                                              return psm.CouponDetail(
                                                code: e.code ?? "",
                                                value: (e.value ?? 0).toDouble(),
                                              );
                                            }).toList() ?? [],
                                            serviceChargePercentage: (orderModel.serviceChargePercentage ?? 0).toDouble(),
                                            serviceChargeValue: (orderModel.serviceChargeValue ?? 0).toDouble(),
                                            roundOff: (orderModel.roundOff ?? 0).toDouble(),
                                          );

                                          showDialog(
                                            context: context,
                                            barrierDismissible: false,
                                            builder: (context) => Dialog(
                                              backgroundColor: Colors.transparent,
                                              insetPadding: EdgeInsets.zero,
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: Padding(
                                                  padding: const EdgeInsets.only(
                                                    left: 330,
                                                    top: 60,
                                                    bottom: 60,
                                                  ),
                                                  child: PrintRecipt(
                                                    loadedTables: const [],
                                                    pin: widget.pin,
                                                    token: widget.token,
                                                    restaurantId: widget.restaurantId,
                                                    restaurantName: widget.restaurantName,
                                                    zoneId: orderModel.zoneId,
                                                    paymentSummary: paymentSummaryObj,
                                                    cashierName: widget.userPermissions?.displayName ?? 'Admin',
                                                    isTakeAway: orderModel.orderType?.toLowerCase().contains("take") ?? false,
                                                    isFromOrderDetails: true,
                                                    isCopy: true,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        } catch (e) {
                                          debugPrint("Print Bill Error: $e");
                                        }
                                      },
                                      child: const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.print,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            "Print Bill",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
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
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF202433)
                            : const Color(0xFFF6F6F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ✅ Only show summary if updated
                          if (orderModel.isUpdated?.toLowerCase() == 'yes')
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: theme.cardColor,
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
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            const Text(
                                              " Original Net Payable-    ",
                                              style: TextStyle(fontSize: 14),
                                            ),
                                            Text(
                                              "$_currency${orderModel.orderPrevTotal?.toStringAsFixed(2) ?? '0.00'}",
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Container(
                                      //   width: 1,
                                      //   color: Colors.grey[300],
                                      //   margin: const EdgeInsets.symmetric(horizontal: 8),
                                      // ),

                                      // Reason
                                      Expanded(
                                        child: Row(
                                          children: [
                                            const Text(
                                              "Reason for edit-   ",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF7A7A7A),
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                orderModel.updated_remarks?.isNotEmpty == true
                                                    ? orderModel.updated_remarks!
                                                    : '-',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // const Text(
                                      //   "Old payment Details",
                                      //   style: TextStyle(fontSize: 12),
                                      // ),

                                      // UPDATED PILL
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: ShapeDecoration(
                                          color: const Color(0xFFFFF1C2),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(15),
                                          ),
                                        ),
                                        child: Row(
                                          children: const [
                                            // Icon(
                                            //   Icons.refresh,
                                            //   size: 12,
                                            //   color: Colors.orange,
                                            // ),
                                            SizedBox(width: 4),
                                            Text(
                                              "Updated",
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFFA78307),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  // const SizedBox(height: 8),
                                  // IntrinsicHeight(
                                  //   child: Row(
                                  //     children: [
                                  //       // Net Payable
                                  //       Expanded(
                                  //         child: Row(
                                  //           children: [
                                  //             const Text(
                                  //               "Net Payable Amount-    ",
                                  //               style: TextStyle(fontSize: 14),
                                  //             ),
                                  //             Text(
                                  //               "₹${orderModel.orderPrevTotal?.toStringAsFixed(2) ?? '0.00'}",
                                  //               style: const TextStyle(
                                  //                 fontSize: 14,
                                  //                 fontWeight: FontWeight.w500,
                                  //               ),
                                  //             ),
                                  //           ],
                                  //         ),
                                  //       ),
                                  //
                                  //       Container(
                                  //         width: 1,
                                  //         color: Colors.grey[300],
                                  //         margin: const EdgeInsets.symmetric(horizontal: 8),
                                  //       ),
                                  //
                                  //       // Reason
                                  //       Expanded(
                                  //         child: Row(
                                  //           children: [
                                  //             const Text(
                                  //               "Reason for edit-   ",
                                  //               style: TextStyle(
                                  //                 fontSize: 12,
                                  //                 color: Color(0xFF7A7A7A),
                                  //               ),
                                  //             ),
                                  //             Expanded(
                                  //               child: Text(
                                  //                 orderModel.updated_remarks?.isNotEmpty == true
                                  //                     ? orderModel.updated_remarks!
                                  //                     : '-',
                                  //                 maxLines: 1,
                                  //                 overflow: TextOverflow.ellipsis,
                                  //                 style: const TextStyle(
                                  //                   fontSize: 14,
                                  //                   fontWeight: FontWeight.w500,
                                  //                 ),
                                  //               ),
                                  //             ),
                                  //           ],
                                  //         ),
                                  //       ),
                                  //     ],
                                  //   ),
                                  // ),
                                ],
                              ),
                            ),


                          //  KOT TABLE
                          Expanded(child: buildSelectedKotCard(order,orderModel)),
                          // const SizedBox(height: 10,),
                          // Align(
                          //   alignment: Alignment.centerRight,
                          //   child: SizedBox(
                          //     width: 180,
                          //     height: 36,
                          //     child: ElevatedButton(
                          //       style: ElevatedButton.styleFrom(
                          //         backgroundColor: const Color(0xFFF7C127),
                          //         shape: RoundedRectangleBorder(
                          //           borderRadius: BorderRadius.circular(10),
                          //         ),
                          //         padding: const EdgeInsets.symmetric(horizontal: 12),
                          //       ),
                          //       onPressed: () async {
                          //         try {
                          //           Map<String, Map<String, dynamic>> consolidated = {};
                          //           if (orderModel.kotOrders != null) {
                          //             for (var kot in orderModel.kotOrders!) {
                          //               if (kot.lineItems != null) {
                          //                 for (var lineItem in kot.lineItems!) {
                          //                   final name = lineItem.name ?? '';
                          //                   final modifiers = lineItem.modifiers ?? [];
                          //                   final key = "$name-${modifiers.join(',')}";
                          //                   if (consolidated.containsKey(key)) {
                          //                     final existing = consolidated[key]!;
                          //                     final currentQty = int.tryParse(existing['qty'].toString()) ?? 0;
                          //                     final addedQty = lineItem.quantity ?? 0;
                          //                     final newQty = currentQty + addedQty;
                          //                     existing['qty'] = newQty;
                          //                     existing['amount'] = (double.tryParse(existing['price'].toString()) ?? 0.0) * newQty;
                          //                   } else {
                          //                     consolidated[key] = {
                          //                       "name": name,
                          //                       "qty": lineItem.quantity ?? 0,
                          //                       "price": lineItem.itemPrice ?? 0.0,
                          //                       "amount": lineItem.amount ?? 0.0,
                          //                       "modifiers": modifiers,
                          //                     };
                          //                   }
                          //                 }
                          //               }
                          //             }
                          //           }
                          //
                          //           await Printer.printBill(
                          //             context: context,
                          //             orderId: orderModel.orderId.toString(),
                          //             tableName: orderModel.tableName ?? "",
                          //             cashierName: widget.userPermissions?.displayName ?? 'Admin',
                          //             items: consolidated.values.toList(),
                          //             grossTotal: (orderModel.grossTotal ?? 0).toDouble(),
                          //             couponDiscount: (orderModel.discount ?? 0).toDouble(),
                          //             merchantDiscount: (orderModel.merchantDiscount ?? 0).toDouble(),
                          //             tipAmount: (orderModel.tipAmount ?? 0).toDouble(),
                          //             taxAmount: (orderModel.totalTax ?? 0).toDouble(),
                          //             serviceCharge: (orderModel.serviceChargeValue ?? 0).toDouble(),
                          //             netPayable: (orderModel.netPayable ?? orderModel.netTotal ?? 0).toDouble(),
                          //             isCopy: true,
                          //           );
                          //         } catch (e) {
                          //           debugPrint("Print Bill Error: $e");
                          //         }
                          //       },
                          //       child: const Row(
                          //         mainAxisAlignment: MainAxisAlignment.center,
                          //         children: [
                          //           Icon(
                          //             Icons.print,
                          //             color: Colors.white,
                          //             size: 18,
                          //           ),
                          //           SizedBox(width: 8),
                          //           Text(
                          //             "Print Bill",
                          //             style: TextStyle(
                          //               fontSize: 16,
                          //               fontWeight: FontWeight.bold,
                          //               color: Colors.white,
                          //             ),
                          //           ),
                          //         ],
                          //       ),
                          //     ),
                          //   ),
                          // ),



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


  Widget buildKOTCard(Map<String, dynamic> selectedKot, List<dynamic> kots, OrderlistModel orderModel,) {
    final items = (selectedKot["items"] as List<dynamic>?) ?? [];
    final bool showVoided =
        orderModel.isUpdated?.toLowerCase() == 'yes';

    final List<Map<String, dynamic>> normalItems =
    items.cast<Map<String, dynamic>>();

    final List<VoidedItem> voidedItems =
    (showVoided && !isVoidedLoading && voidedItemsResponse != null)
        ? voidedItemsResponse!.items
        : [];
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;


    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
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
                height: 36,
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
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.white,
                      ), // white icon
                      dropdownColor: const Color(
                        0xFF125BCE,
                      ), // dropdown menu blue
                      style: const TextStyle(
                        color: Colors.white,
                      ), // selected text white
                      items:
                      kots.map((kot) {
                        return DropdownMenuItem<int>(
                          value: kot["kotNo"],
                          child: Text(
                            "KOT ${kot["kotNo"]}",
                            style: const TextStyle(
                              color: Colors.white,
                            ), // dropdown items text
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedKotId = value;
                        });
                        loadVoidedItems(value!);
                      }

                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Table Header
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF999393),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              children: const [
                Expanded(
                  flex: 1,
                  child: Text(
                    "#",
                    style: TextStyle(fontWeight: FontWeight.w400,color: Color(0xFFF5F5F5)),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    "Item Name",
                    style: TextStyle(fontWeight: FontWeight.w400,color: Color(0xFFF5F5F5)),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "Quantity",
                    style: TextStyle(fontWeight: FontWeight.w400,color: Color(0xFFF5F5F5)),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    "Amount",
                    style: TextStyle(fontWeight: FontWeight.w400,color: Color(0xFFF5F5F5)),
                  ),
                ),
              ],
            ),
          ),

          ///  Items List (SCROLLABLE)
// ---------------- NORMAL ITEMS LIST ----------------
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: normalItems.length + voidedItems.length,
              itemBuilder: (context, index) {
                final bool isNormal = index < normalItems.length;
                final bool isLast =
                    index == (normalItems.length + voidedItems.length - 1);
                if (isVoidedLoading && showVoided) {
                  return const Padding(
                    padding: EdgeInsets.all(12),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  );
                }

                return Container(
                  padding: isNormal
                      ? const EdgeInsets.symmetric(vertical: 8, horizontal: 16)
                      : const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  decoration: BoxDecoration(
                    color: isNormal
                        ? (isDark ? const Color(0xFF202433) : Colors.white)
                        : (isDark ? const Color(0xFF2A2F3D) : Colors.grey.shade200),
                    border: Border(
                      bottom: BorderSide(color: theme.dividerColor),
                      left: BorderSide(color: theme.dividerColor),
                      right: BorderSide(color: theme.dividerColor),
                    ),
                    borderRadius: isLast
                        ? const BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    )
                        : BorderRadius.zero,
                  ),
                  child: isNormal
                      ? _buildNormalRow(normalItems[index], index)
                      : _buildVoidedRow(
                    voidedItems[index - normalItems.length],
                    index,
                  ),
                );
              },
            ),
          )

// ---------------- DELETED ITEMS ----------------
//           if (orderModel.isUpdated?.toLowerCase() == 'yes') ...[
//             const SizedBox(height: 12),
//             const Divider(),
//
//             const Text(
//               "Deleted Items",
//               style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 8),
//
//             if (isVoidedLoading)
//               const Center(child: CircularProgressIndicator())
//             else if (voidedItemsResponse == null ||
//                 voidedItemsResponse!.items.isEmpty)
//               const Text("No deleted items found")
//             else
//               ListView.separated(
//                 shrinkWrap: true,
//                 physics: const NeverScrollableScrollPhysics(),
//                 itemCount: voidedItemsResponse!.items.length,
//                 separatorBuilder: (_, __) => const Divider(),
//                 itemBuilder: (context, index) {
//                   final item = voidedItemsResponse!.items[index];
//
//                   return Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Expanded(child: Text(item.product)),
//                       Text(
//                         "${item.origQty} → ${item.newQty}",
//                         style: const TextStyle(color: Colors.red),
//                       ),
//                       Text("₹${item.itemTotal.toStringAsFixed(2)}"),
//                     ],
//                   );
//                 },
//               ),
//           ]

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
}
