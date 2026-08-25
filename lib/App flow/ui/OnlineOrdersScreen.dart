import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../models/UserPermissions.dart';
import '../../models/order_list/order_list_model.dart';
import '../../repositories/order_list_repository.dart';
import '../widgets/top_bar.dart';

class OnlineOrdersScreen extends StatefulWidget {
  final String token;
  final String pin;
  final String restaurantId;
  final String restaurantName;
  final UserPermissions? userPermissions;

  const OnlineOrdersScreen({
    Key? key,
    required this.token,
    required this.pin,
    required this.restaurantId,
    required this.restaurantName,
    this.userPermissions,
  }) : super(key: key);

  @override
  State<OnlineOrdersScreen> createState() => _OnlineOrdersScreenState();
}

class _OnlineOrdersScreenState extends State<OnlineOrdersScreen> {
  String _selectedPlatform = "All"; // All, Swiggy, Zomato, OrderOut, DoorDash, Direct
  String _selectedStatus = "New"; // New, Preparing, Ready, Cancelled
  String _searchQuery = "";
  bool _isGridView = true;
  bool _isLoading = false;

  List<Map<String, dynamic>> _orders = [];

  static const String _orderOutApiUrl =
      "https://pdh.alektasolutions.com/connector/api/v1/orders";

  @override
  void initState() {
    super.initState();
    _fetchOnlineOrders();
  }

  /// Fetch online orders from both POS OrderList API & OrderOut API
  Future<void> _fetchOnlineOrders() async {
    setState(() {
      _isLoading = true;
    });

    List<Map<String, dynamic>> combinedOrders = [];

    // 1. Fetch POS Online Orders via OrderstatusRepository
    try {
      final posRepo = OrderstatusRepository();
      final posOrders = await posRepo.fetchOrders(
        widget.token,
        restaurantId: widget.restaurantId,
        forceRefresh: true,
      );

      for (final order in posOrders) {
        final ot = (order.orderType ?? '').toLowerCase();
        final createdVia = (order.createdVia ?? '').toLowerCase();
        final isOnline = ot.contains('online') ||
            ot.contains('shop') ||
            ot.contains('woo') ||
            ot.contains('doordash') ||
            ot.contains('ubereats') ||
            ot.contains('delivery') ||
            createdVia == 'online' ||
            createdVia == 'rest-api' ||
            (order.externalOrderId != null && order.externalOrderId!.isNotEmpty);

        if (isOnline) {
          combinedOrders.add(_parsePosOrder(order));
        }
      }
    } catch (e) {
      debugPrint("⚠️ POS Online Orders fetch error: $e");
    }

    // 2. Fetch OrderOut API Online Orders
    try {
      final response = await http
          .get(Uri.parse(_orderOutApiUrl))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data["success"] == true && data["orders"] != null) {
          final List rawOrders = data["orders"];
          for (final o in rawOrders) {
            final parsed = _parseApiOrder(o);
            if (!combinedOrders.any((existing) => existing["id"] == parsed["id"])) {
              combinedOrders.add(parsed);
            }
          }
        }
      }
    } catch (e) {
      debugPrint("⚠️ OrderOut API fetch error: $e");
    }

    // Fallback if no online orders exist
    if (combinedOrders.isEmpty) {
      _loadFallbackMockOrders();
      return;
    }

    setState(() {
      _orders = combinedOrders;
      _isLoading = false;
    });
  }

  /// Parse POS OrderlistModel object
  Map<String, dynamic> _parsePosOrder(OrderlistModel o) {
    final orderId = (o.externalOrderId != null && o.externalOrderId!.isNotEmpty)
        ? o.externalOrderId!
        : (o.orderId?.toString() ?? "N/A");

    // Extract items & quantities from KOT orders (lineItems or initialKotItems)
    List<Map<String, dynamic>> itemsList = [];
    if (o.kotOrders != null && o.kotOrders!.isNotEmpty) {
      for (final kot in o.kotOrders!) {
        final lines = kot.lineItems ?? kot.initialKotItems;
        if (lines != null) {
          for (final item in lines) {
            itemsList.add({
              "name": item.name ?? "Item",
              "qty": item.quantity ?? 1,
            });
          }
        }
      }
    }

    final visibleItems = itemsList.take(3).toList();
    final moreCount = itemsList.length > 3 ? itemsList.length - 3 : 0;

    // Time formatting
    String timeStr = o.date ?? "12:00 PM";
    if (o.date != null) {
      try {
        final dt = DateTime.parse(o.date!).toLocal();
        timeStr = DateFormat.jm().format(dt);
      } catch (_) {}
    }

    // Status mapping
    String mappedStatus = "New";
    final st = (o.status ?? "").toLowerCase();
    if (st.contains("preparing") || st.contains("kitchen") || st.contains("accepted")) {
      mappedStatus = "Preparing";
    } else if (st.contains("ready") || st.contains("dispatched") || st.contains("completed") || st.contains("paid")) {
      mappedStatus = "Ready";
    } else if (st.contains("cancel") || st.contains("void")) {
      mappedStatus = "Cancelled";
    }

    // Platform mapping
    String platform = "Direct";
    final ot = (o.orderType ?? "").toLowerCase();
    if (ot.contains("swiggy")) {
      platform = "Swiggy";
    } else if (ot.contains("zomato")) {
      platform = "Zomato";
    } else if (ot.contains("doordash")) {
      platform = "DoorDash";
    } else if (ot.contains("woo") || ot.contains("shop")) {
      platform = "OrderOut";
    }

    final totalAmt = o.netPayable ?? o.total ?? o.amount ?? o.grossTotal ?? 0;

    return {
      "id": orderId,
      "rawId": o.orderId?.toString() ?? "",
      "platform": platform,
      "time": timeStr,
      "customerName": o.customerName ?? "Online Customer",
      "customerPhone": o.customerPhone ?? "N/A",
      "status": mappedStatus,
      "paymentStatus": o.paymentType ?? "Paid Online",
      "totalAmount": totalAmt,
      "note": o.tableName != null ? "Table: ${o.tableName}" : "Add Cutlery",
      "items": visibleItems,
      "allItemsCount": itemsList.length,
      "moreItemsCount": moreCount,
    };
  }

  /// Parse OrderOut API JSON object
  Map<String, dynamic> _parseApiOrder(Map<String, dynamic> jsonOrder) {
    final rawPlatform = (jsonOrder["platform"] ?? "ORDEROUT").toString();
    final rawStatus = (jsonOrder["status"] ?? "CREATED").toString();

    // Customer parsing (fullName or name)
    final customerObj = jsonOrder["customer"] as Map<String, dynamic>?;
    final customerName = customerObj?["fullName"] ??
        customerObj?["name"] ??
        "Test Customer Name";
    final customerPhone = customerObj?["phone"] ?? "+1 (111) 111-1111";

    // Order ID (externalOrderId or id)
    final orderId = (jsonOrder["externalOrderId"] ?? jsonOrder["id"] ?? "")
        .toString();

    // Time parsing (createdAt)
    String timeStr = "12:00 PM";
    if (jsonOrder["createdAt"] != null) {
      try {
        final dt = DateTime.parse(jsonOrder["createdAt"]).toLocal();
        timeStr = DateFormat.jm().format(dt);
      } catch (_) {}
    }

    // Items list parsing
    final List rawItems = jsonOrder["items"] ?? [];
    final itemsList = rawItems.map((it) {
      return {
        "name": (it["name"] ?? "Item").toString(),
        "qty": it["quantity"] ?? 1,
        "price": it["unitPrice"] ?? 0,
      };
    }).toList();

    // Display first 3 items in card, calc remaining count
    final visibleItems = itemsList.take(3).toList();
    final moreCount = itemsList.length > 3 ? itemsList.length - 3 : 0;

    // Status mapping
    String mappedStatus = "New";
    final upperStatus = rawStatus.toUpperCase();
    if (upperStatus == "ACCEPTED" || upperStatus == "PREPARING" || upperStatus == "CONFIRMED") {
      mappedStatus = "Preparing";
    } else if (upperStatus == "READY" || upperStatus == "DISPATCHED" || upperStatus == "COMPLETED") {
      mappedStatus = "Ready";
    } else if (upperStatus == "CANCELLED" || upperStatus == "REJECTED") {
      mappedStatus = "Cancelled";
    }

    // Platform mapping
    String mappedPlatform = "OrderOut";
    final upperPlatform = rawPlatform.toUpperCase();
    if (upperPlatform.contains("SWIGGY")) {
      mappedPlatform = "Swiggy";
    } else if (upperPlatform.contains("ZOMATO")) {
      mappedPlatform = "Zomato";
    } else if (upperPlatform.contains("DOORDASH")) {
      mappedPlatform = "DoorDash";
    } else if (upperPlatform.contains("DIRECT")) {
      mappedPlatform = "Direct";
    } else {
      mappedPlatform = "OrderOut";
    }

    return {
      "id": orderId,
      "rawId": jsonOrder["id"] ?? "",
      "platform": mappedPlatform,
      "time": timeStr,
      "customerName": customerName,
      "customerPhone": customerPhone,
      "status": mappedStatus,
      "paymentStatus": "Paid Online",
      "totalAmount": jsonOrder["totalAmount"] ?? 0.0,
      "note": jsonOrder["deliveryAddress"]?["street"] != null
          ? "${jsonOrder['deliveryAddress']['street']}"
          : "Add Cutlery",
      "items": visibleItems,
      "allItemsCount": itemsList.length,
      "moreItemsCount": moreCount,
    };
  }

  void _loadFallbackMockOrders() {
    setState(() {
      _isLoading = false;
      _orders = [
        {
          "id": "oo_test_order_b70f4",
          "rawId": "ord_f3f4036e",
          "platform": "OrderOut",
          "time": "03:56 PM",
          "customerName": "Test Customer Name",
          "customerPhone": "+1 (111) 111-1111",
          "status": "New",
          "paymentStatus": "Paid Online",
          "totalAmount": 0.97,
          "note": "1 delivery addr street",
          "items": [
            {"name": "Chicken Popcorn", "qty": 2},
            {"name": "Veg Spring Rolls", "qty": 1},
            {"name": "Bruschetta", "qty": 2},
          ],
          "moreItemsCount": 0,
        },
        {
          "id": "7047828189",
          "rawId": "7047828189",
          "platform": "Swiggy",
          "time": "12:42 PM",
          "customerName": "Bhargav Ram",
          "customerPhone": "+91 9876543210",
          "status": "New",
          "paymentStatus": "Paid Online",
          "totalAmount": 530,
          "note": "Add Cutlery",
          "items": [
            {"name": "Chicken Biryani", "qty": 1},
            {"name": "Chicken 65", "qty": 1},
            {"name": "Coke", "qty": 1},
          ],
          "moreItemsCount": 10,
        },
        {
          "id": "207782924989",
          "rawId": "207782924989",
          "platform": "Zomato",
          "time": "12:40 PM",
          "customerName": "Sudharshan",
          "customerPhone": "+91 9876543211",
          "status": "New",
          "paymentStatus": "Paid Online",
          "totalAmount": 810,
          "note": "Add Cutlery",
          "items": [
            {"name": "Paneer Butter Masala", "qty": 2},
            {"name": "Garlic Naan", "qty": 4},
            {"name": "Gulab Jamun", "qty": 1},
          ],
          "moreItemsCount": 0,
        },
        {
          "id": "DD-8811",
          "rawId": "ord_a64e4a5c",
          "platform": "DoorDash",
          "time": "12:35 PM",
          "customerName": "Test Customer",
          "customerPhone": "+15555550100",
          "status": "New",
          "paymentStatus": "Paid Online",
          "totalAmount": 25.0,
          "note": "1 Main Street",
          "items": [
            {"name": "Test Item", "qty": 1},
          ],
          "moreItemsCount": 0,
        },
        {
          "id": "oo_test_order_bbd5b",
          "rawId": "ord_8604451d",
          "platform": "OrderOut",
          "time": "01:42 PM",
          "customerName": "Test Customer Name",
          "customerPhone": "+1 (111) 111-1111",
          "status": "Preparing",
          "paymentStatus": "Paid Online",
          "totalAmount": 0.98,
          "note": "1 delivery addr street",
          "items": [
            {"name": "Jim Beam Original", "qty": 1},
            {"name": "Jack Daniel's Old No. 7", "qty": 2},
            {"name": "Antiquite Rare", "qty": 1},
          ],
          "moreItemsCount": 0,
        },
      ];
    });
  }

  List<Map<String, dynamic>> get _filteredOrders {
    return _orders.where((order) {
      // Platform filter
      if (_selectedPlatform != "All") {
        if (order["platform"].toString().toLowerCase() !=
            _selectedPlatform.toLowerCase()) {
          return false;
        }
      }
      // Status filter
      if (order["status"].toString().toLowerCase() !=
          _selectedStatus.toLowerCase()) {
        return false;
      }
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final id = order["id"].toString().toLowerCase();
        final name = order["customerName"].toString().toLowerCase();
        if (!id.contains(query) && !name.contains(query)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  int _getOrdersCountByStatus(String status) {
    return _orders.where((o) =>
    _selectedPlatform == "All" ||
        o["platform"].toString().toLowerCase() ==
            _selectedPlatform.toLowerCase()).where((o) =>
    o["status"].toString().toLowerCase() == status.toLowerCase()).length;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1E2430) : const Color(0xFFF8FAFC),
      appBar: TopBar(
        token: widget.token,
        pin: widget.pin,
        restaurantId: widget.restaurantId,
        restaurantName: widget.restaurantName,
        userPermissions: widget.userPermissions,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// HEADER BAR: TITLE, SEARCH, VIEW TOGGLES
            _buildHeaderSection(isDark),

            const SizedBox(height: 16),

            /// PLATFORM FILTER CARD (All, Swiggy, Zomato, OrderOut, DoorDash, Direct)
            _buildPlatformFilterCard(isDark),

            const SizedBox(height: 20),

            /// STATUS TABS (New, Preparing, Ready, Cancelled)
            _buildStatusTabs(isDark),

            const SizedBox(height: 20),

            /// ORDERS GRID / LIST VIEW OR LOADING
            _isLoading
                ? Container(
              height: 300,
              alignment: Alignment.center,
              child: const CircularProgressIndicator(),
            )
                : _buildOrdersView(isDark),
          ],
        ),
      ),
    );
  }

  /// Header with screen title, search input, and grid/list view switcher
  Widget _buildHeaderSection(bool isDark) {
    return Row(
      children: [
        Text(
          "ONLINE ORDERS",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        const Spacer(),

        /// SEARCH BAR
        Container(
          width: 280,
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A324B) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? Colors.grey.shade700 : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.search,
                size: 20,
                color: isDark ? Colors.white60 : const Color(0xFF64748B),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                  decoration: InputDecoration(
                    hintText: "Search by Order ID",
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey.shade400 : const Color(0xFF94A3B8),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        /// VIEW TOGGLE BUTTONS (GRID / LIST)
        Container(
          height: 42,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A324B) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? Colors.grey.shade700 : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: [
              _viewToggleButton(
                icon: Icons.grid_view_rounded,
                isSelected: _isGridView,
                onTap: () => setState(() => _isGridView = true),
                isDark: isDark,
              ),
              _viewToggleButton(
                icon: Icons.format_list_bulleted,
                isSelected: !_isGridView,
                onTap: () => setState(() => _isGridView = false),
                isDark: isDark,
              ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        /// REFRESH BUTTON
        InkWell(
          onTap: () => _fetchOnlineOrders(),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A324B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? Colors.grey.shade700 : const Color(0xFFE2E8F0),
              ),
            ),
            child: Icon(
              Icons.sync,
              size: 20,
              color: isDark ? Colors.white : const Color(0xFF334155),
            ),
          ),
        ),
      ],
    );
  }

  Widget _viewToggleButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFFEA580C) : const Color(0xFFFF6B00))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isSelected
              ? Colors.white
              : (isDark ? Colors.grey.shade400 : const Color(0xFF64748B)),
        ),
      ),
    );
  }

  /// Platform Filter Pill Bar (All, Swiggy, Zomato, OrderOut, DoorDash, Direct)
  Widget _buildPlatformFilterCard(bool isDark) {
    final platforms = ["All", "Swiggy", "Zomato", "OrderOut", "DoorDash", "Direct"];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF202636) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: platforms
              .map((p) => Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _platformFilterPill(p, isDark),
          ))
              .toList(),
        ),
      ),
    );
  }

  Widget _platformFilterPill(String platformName, bool isDark) {
    final isSelected = _selectedPlatform.toLowerCase() == platformName.toLowerCase();

    Color brandColor = const Color(0xFFFF6B00);
    IconData icon = Icons.grid_view_rounded;

    if (platformName == "Swiggy") {
      brandColor = const Color(0xFFFC8019);
      icon = Icons.delivery_dining;
    } else if (platformName == "Zomato") {
      brandColor = const Color(0xFFCB202D);
      icon = Icons.restaurant;
    } else if (platformName == "OrderOut") {
      brandColor = const Color(0xFF8B5CF6);
      icon = Icons.bolt;
    } else if (platformName == "DoorDash") {
      brandColor = const Color(0xFFFF3008);
      icon = Icons.takeout_dining;
    } else if (platformName == "Direct") {
      brandColor = const Color(0xFF1890FF);
      icon = Icons.flatware;
    }

    return InkWell(
      onTap: () => setState(() => _selectedPlatform = platformName),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (platformName == "All"
              ? (isDark ? const Color(0xFFEA580C).withOpacity(0.15) : const Color(0xFFFFF7ED))
              : brandColor.withOpacity(0.12))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? (platformName == "All" ? const Color(0xFFFF6B00) : brandColor)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isSelected ? brandColor : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              platformName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? (isDark ? Colors.white : const Color(0xFF1E293B))
                    : (isDark ? Colors.grey.shade400 : const Color(0xFF64748B)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Status Filter Tabs (New, Preparing, Ready, Cancelled)
  Widget _buildStatusTabs(bool isDark) {
    final statuses = ["New", "Preparing", "Ready", "Cancelled"];

    return Row(
      children: statuses.map((status) {
        final count = _getOrdersCountByStatus(status);
        final isSelected = _selectedStatus.toLowerCase() == status.toLowerCase();

        return Padding(
          padding: const EdgeInsets.only(right: 24),
          child: InkWell(
            onTap: () => setState(() => _selectedStatus = status),
            borderRadius: BorderRadius.circular(4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$status ($count)",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected
                        ? (status == "New"
                        ? Colors.red
                        : (isDark ? Colors.white : const Color(0xFF0F172A)))
                        : (isDark ? Colors.grey.shade400 : const Color(0xFF64748B)),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 3,
                  width: isSelected ? 48 : 0,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.red : Colors.transparent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Render Order Cards Grid or List
  Widget _buildOrdersView(bool isDark) {
    final orders = _filteredOrders;

    if (orders.isEmpty) {
      return Container(
        height: 300,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 48,
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              "No $_selectedStatus Online Orders Found",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    if (!_isGridView) {
      return Column(
        children: orders.map((order) => _buildOrderCard(order, isDark)).toList(),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 4;
        if (constraints.maxWidth < 1100) crossAxisCount = 3;
        if (constraints.maxWidth < 800) crossAxisCount = 2;
        if (constraints.maxWidth < 550) crossAxisCount = 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            mainAxisExtent: 380,
          ),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            return _buildOrderCard(orders[index], isDark);
          },
        );
      },
    );
  }

  /// Single Order Card Matching Screenshot Design
  Widget _buildOrderCard(Map<String, dynamic> order, bool isDark) {
    final platform = order["platform"].toString();
    final orderId = order["id"].toString();
    final time = order["time"].toString();
    final customerName = order["customerName"].toString();
    final customerPhone = order["customerPhone"].toString();
    final note = order["note"].toString();
    final items = (order["items"] as List<dynamic>?) ?? [];
    final moreItemsCount = (order["moreItemsCount"] as int?) ?? 0;
    final totalAmount = order["totalAmount"];
    final paymentStatus = order["paymentStatus"].toString();
    final status = order["status"].toString();

    // Brand specific header colors & icons
    Color brandColor = const Color(0xFFFC8019); // Swiggy Orange
    IconData brandIcon = Icons.delivery_dining;

    if (platform.toLowerCase() == "zomato") {
      brandColor = const Color(0xFFCB202D); // Zomato Red
      brandIcon = Icons.restaurant;
    } else if (platform.toLowerCase() == "orderout") {
      brandColor = const Color(0xFF8B5CF6); // OrderOut Purple
      brandIcon = Icons.bolt;
    } else if (platform.toLowerCase() == "doordash") {
      brandColor = const Color(0xFFFF3008); // DoorDash Red
      brandIcon = Icons.takeout_dining;
    } else if (platform.toLowerCase() == "direct") {
      brandColor = const Color(0xFF1890FF); // Direct Blue
      brandIcon = Icons.flatware;
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF202636) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// HEADER: PLATFORM ICON, BRAND NAME, ORDER ID & TIME
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: brandColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(brandIcon, size: 20, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      platform.toUpperCase(),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: brandColor,
                      ),
                    ),
                    Text(
                      "#$orderId",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white70 : const Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          /// CUSTOMER NAME & CALL LINK
          Row(
            children: [
              Icon(
                Icons.person_outline,
                size: 16,
                color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  customerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF334155),
                  ),
                ),
              ),
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Calling $customerName ($customerPhone)..."),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Icon(
                      Icons.phone_outlined,
                      size: 14,
                      color: brandColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "Call Customer",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: brandColor,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          /// ITEMS LIST CONTAINER
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF191F2D) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.grey.shade800 : const Color(0xFFF1F5F9),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item["name"].toString(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white : const Color(0xFF1E293B),
                              ),
                            ),
                          ),
                          Text(
                            "x${item['qty']}",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : const Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),

                  if (moreItemsCount > 0) ...[
                    const Spacer(),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2A324B) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          "▼ $moreItemsCount More Items",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.grey.shade300 : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          /// NOTE / INSTRUCTIONS
          if (note.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A324B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.note_alt_outlined,
                    size: 14,
                    color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      "Note: $note",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.grey.shade300 : const Color(0xFF475569),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 10),

          /// PAYMENT BADGE & PRICE ROW
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  paymentStatus,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF15803D),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "₹$totalAmount",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1D4ED8),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          /// ACTION BUTTONS (CANCEL ORDER / ACCEPT ORDER)
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: OutlinedButton(
                    onPressed: () {
                      _updateOrderStatus(order, "Cancelled");
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFF87171)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "Cancel Order",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: ElevatedButton(
                    onPressed: () {
                      if (status == "New") {
                        _updateOrderStatus(order, "Preparing");
                      } else if (status == "Preparing") {
                        _updateOrderStatus(order, "Ready");
                      } else {
                        _updateOrderStatus(order, "Dispatched");
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      status == "New"
                          ? "Accept Order"
                          : (status == "Preparing" ? "Mark Ready" : "Dispatch"),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _updateOrderStatus(Map<String, dynamic> order, String newStatus) {
    setState(() {
      order["status"] = newStatus;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Order #${order['id']} moved to $newStatus"),
        backgroundColor: newStatus == "Cancelled" ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
