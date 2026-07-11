import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kds_app/top_bar.dart';
import 'package:kds_app/widgets/completed_orders.dart';
import 'package:kds_app/widgets/repeated_item.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'active_orderscreen.dart';
import 'providers/order_provider.dart';
import 'services/kds_mqtt_service.dart';
import 'services/repeateditem_apiservices.dart';

class KitchenDashboardScreen extends StatefulWidget {
  final String token;
  final int restaurantId;
  final VoidCallback? onOpenSettings;

  const KitchenDashboardScreen({
    super.key,
    required this.token,
    required this.restaurantId,
    this.onOpenSettings,
  });

  @override
  State<KitchenDashboardScreen> createState() => _KitchenDashboardScreenState();
}

class _KitchenDashboardScreenState extends State<KitchenDashboardScreen> {
  String selectedOrderType = "All";
  OrderTypeFilter selectedFilter = OrderTypeFilter.all;
  String? selectedCancelKotId;
  Timer? _refreshTimer;
  String? selectedCancelItemKotId;
  final Set<String> selectedItems = {};

  final Map<String, List<bool>> selectedItemsMap = {};

  KotView selectedView = KotView.pending;
  int _repeatedItemsCount = 0;
  bool isZoomedOut = true;
  final Set<String> zoomedKotIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().loadExistingOrders();
    });
    _fetchRepeatedItemsCount();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      context.read<OrderProvider>().loadExistingOrders();
      _fetchRepeatedItemsCount();
    });

    _fetchRepeatedItemsCount();
  }

  Future<void> _fetchRepeatedItemsCount() async {
    try {
      final response = await getKitchenItemsCount(
        token: widget.token,
        restaurantId: widget.restaurantId,
      );
      if (mounted) {
        setState(() {
          _repeatedItemsCount = response.length;
        });
      }
    } catch (e) {
      debugPrint("Failed to fetch repeated items count: $e");
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();

    final orders = orderProvider.pendingOrders;

    final filteredOrders =
        orders.where((order) {
          final type = order['type']?.toString().toLowerCase() ?? '';

          switch (selectedFilter) {
            case OrderTypeFilter.all:
              return true;

            case OrderTypeFilter.dineIn:
              return type.contains('dine');

            case OrderTypeFilter.takeaway:
              return type.contains('take');

            case OrderTypeFilter.online:
              return type.contains('online');
          }
        }).toList();

    Widget bodyWidget;
    switch (selectedView) {
      case KotView.pending:
        bodyWidget = _buildPendingBody(filteredOrders, orderProvider);
        break;
      case KotView.active:
        bodyWidget = ActiveOrdersScreen(
          token: widget.token,
          restaurantId: widget.restaurantId,
          isEmbedded: true,
        );
        break;
      case KotView.repeated:
        bodyWidget = RepeatedItemsScreen(
          token: widget.token,
          restaurantId: widget.restaurantId,
          isEmbedded: true,
        );
        break;
      case KotView.history:
        bodyWidget = CompletedOrdersScreen(
          token: widget.token,
          restaurantId: widget.restaurantId,
          isEmbedded: true,
          onRecallSuccess: () {
            setState(() {
              selectedView = KotView.active;
            });
          },
        );
        break;
    }

    return Scaffold(
      backgroundColor: const Color(0xffF4F4F4),
      body: SafeArea(
        child: Column(
          children: [
            TopBarWidget(
              token: widget.token,
              restaurantId: widget.restaurantId,
              selectedView: selectedView,
              onViewChanged: (view) {
                setState(() {
                  selectedView = view;
                });
              },
              onLogout: widget.onOpenSettings,
              pendingCount: orderProvider.pendingOrders.length,
              activeCount:
                  orderProvider.preparingOrders.length +
                  orderProvider.readyOrders.length,
              repeatedCount: _repeatedItemsCount,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: bodyWidget,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingBody(
    List<Map<String, dynamic>> filteredOrders,
    OrderProvider orderProvider,
  ) {
    final size = MediaQuery.of(context).size;
    final crossAxisCount = isZoomedOut ? 4 : 2;
    // Account for scaffold padding (12 * 2), outer container padding (16 * 2), outer container border (1 * 2), and gaps (16 * (crossAxisCount - 1))
    final cardWidth =
        (size.width - 58 - (16 * (crossAxisCount - 1))) / crossAxisCount;
    // Calculate the perfect height for cards considering TopBar, padding, and spacing
    final cardHeight =
        isZoomedOut ? (size.height - 202 - 16) / 2 : (size.height - 202);

    // Distribute all filtered orders into vertical columns (row-major filling)
    final List<List<Map<String, dynamic>>> columns = List.generate(
      crossAxisCount,
      (_) => [],
    );
    for (int i = 0; i < filteredOrders.length; i++) {
      columns[i % crossAxisCount].add(filteredOrders[i]);
    }

    // Build the columns widgets list
    List<Widget> columnWidgets = [];
    for (int i = 0; i < columns.length; i++) {
      final colOrders = columns[i];
      final colWidget = SizedBox(
        width: cardWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int j = 0; j < colOrders.length; j++) ...[
              if (j > 0) const SizedBox(height: 16),
              (() {
                final order = colOrders[j];
                final isThisKotZoomed =
                    isZoomedOut &&
                    zoomedKotIds.contains(order['id']?.toString());
                final currentCardHeight =
                    isThisKotZoomed ? (cardHeight * 2 + 16) : cardHeight;
                return SizedBox(
                  width: cardWidth,
                  height: currentCardHeight,
                  child: _buildOrderCard(order, orderProvider),
                );
              })(),
            ],
          ],
        ),
      );
      columnWidgets.add(colWidget);
      if (i < columns.length - 1) {
        columnWidgets.add(const SizedBox(width: 16));
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xffe2e8f0)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SizedBox(
              height: 52,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "New KOT's(${filteredOrders.length.toString().padLeft(2, '0')})",
                    style: GoogleFonts.montserrat(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xff1E293B),
                    ),
                  ),
                  const Spacer(),
                  _filterButtonGroup(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 2),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Column(
                children: [
                  Expanded(
                    child:
                        filteredOrders.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.receipt_long,
                                    size: 64,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    orderProvider.connectionState ==
                                            KdsConnectionState.connected
                                        ? 'Waiting for orders from POS...'
                                        : 'Connecting to POS...',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: columnWidgets,
                              ),
                            ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterButtonGroup() {
    return Container(
      width: 510,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xffe2e8f0), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x35595858),
            offset: Offset(0, 4),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _filterButton(
              title: "All",
              selected: selectedFilter == OrderTypeFilter.all,
              icon: Icons.grid_view,
              iconColor: const Color(0xff2F4376),
              onTap: () {
                setState(() {
                  selectedFilter = OrderTypeFilter.all;
                });
              },
            ),
          ),
          Expanded(
            child: _filterButton(
              title: "Dine-In",
              selected: selectedFilter == OrderTypeFilter.dineIn,
              icon: Icons.restaurant,
              iconColor: Colors.orange,
              onTap: () {
                setState(() {
                  selectedFilter = OrderTypeFilter.dineIn;
                });
              },
            ),
          ),
          Expanded(
            child: _filterButton(
              title: "Takeaways",
              selected: selectedFilter == OrderTypeFilter.takeaway,
              icon: Icons.shopping_bag_outlined,
              iconColor: Colors.blueGrey,
              onTap: () {
                setState(() {
                  selectedFilter = OrderTypeFilter.takeaway;
                });
              },
            ),
          ),
          Expanded(
            child: _filterButton(
              title: "Online Orders",
              selected: selectedFilter == OrderTypeFilter.online,
              icon: Icons.delivery_dining,
              iconColor: Colors.green,
              onTap: () {
                setState(() {
                  selectedFilter = OrderTypeFilter.online;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterButton({
    required String title,
    required bool selected,
    required VoidCallback onTap,
    IconData? icon,
    Color? iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xff2F4376) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null)
              Icon(icon, size: 16, color: selected ? Colors.white : iconColor),
            if (icon != null) const SizedBox(width: 4),
            Text(
              title,
              style: TextStyle(
                color: selected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(
    Map<String, dynamic> order,
    OrderProvider orderProvider,
  ) {
    final kotId = order['id']?.toString() ?? '';
    final orderId = order['parentOrderId']?.toString() ?? '';
    final kotNo = order['kotNo']?.toString() ?? '';
    final orderType = order['type']?.toString() ?? '';
    final items = order['items'] as List<dynamic>? ?? [];
    selectedItemsMap.putIfAbsent(
      kotId,
      () => List.generate(items.length, (_) => false),
    );

    final selected = selectedItemsMap[kotId]!;

    // String? selectedCancelItemKotId;
    // final Map<String, List<bool>> selectedItemsMap = {};
    final tableNo =
        order['tableName']?.toString() ?? order['tableNo']?.toString() ?? '';

    String zoneName = order['zoneName']?.toString() ?? '';

    if (zoneName.isEmpty) {
      final location = order['locationLabel']?.toString() ?? '';

      if (location.contains(' - ')) {
        final parts = location.split(' - ');

        if (parts.length >= 2) {
          zoneName = parts[1];

          if (zoneName.contains('-')) {
            zoneName = zoneName.substring(0, zoneName.lastIndexOf('-'));
          }
        }
      }
    }

    // final items = order['items'] as List<dynamic>? ?? [];

    final isDineIn = orderType.toLowerCase().contains('dine');
    final isCardZoomedOut = isZoomedOut && !zoomedKotIds.contains(kotId);

    return Stack(
      children: [
        Container(
          height: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Solid header bar spanning full width
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: isCardZoomedOut ? 5 : 8,
                ),
                decoration: BoxDecoration(
                  color:
                      isDineIn
                          ? const Color(0xffF26B3A)
                          : const Color(0xff3B73B9),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(9),
                    topRight: Radius.circular(9),
                  ),
                ),
                child: Row(
                  children: [
                    // Left segment (Table No and Zone Name) - taking all remaining space
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          if (tableNo.isNotEmpty) ...[
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: isCardZoomedOut ? 2 : 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                tableNo,
                                style: TextStyle(
                                  color:
                                      isDineIn
                                          ? const Color(0xffF26B3A)
                                          : const Color(0xff3B73B9),
                                  fontSize: isCardZoomedOut ? 9 : 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: Text(
                              zoneName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isCardZoomedOut ? 11 : 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Right segment (Order Type Badge & Elapsed Time grouped next to each other)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isCardZoomedOut ? 6 : 8,
                        vertical: isCardZoomedOut ? 2 : 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        orderType.toUpperCase(),
                        style: TextStyle(
                          fontSize: isCardZoomedOut ? 8 : 9,
                          fontWeight: FontWeight.w700,
                          color:
                              isDineIn
                                  ? const Color(0xffF26B3A)
                                  : const Color(0xff3B73B9),
                        ),
                      ),
                    ),
                    if (isZoomedOut) ...[
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            if (zoomedKotIds.contains(kotId)) {
                              zoomedKotIds.remove(kotId);
                            } else {
                              zoomedKotIds.add(kotId);
                            }
                          });
                        },
                        child: Icon(
                          zoomedKotIds.contains(kotId)
                              ? Icons.close_fullscreen
                              : Icons.open_in_full,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(isCardZoomedOut ? 8 : 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// KOT NO + TIME
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              "KOT #$kotNo",
                              style: TextStyle(
                                fontSize: isCardZoomedOut ? 15 : 18,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xff333333),
                              ),
                            ),
                          ),

                          Text(
                            (() {
                              DateTime? kt;
                              final rawTime = order['kotTime'];
                              if (rawTime is DateTime) {
                                kt = rawTime;
                              } else if (rawTime is String) {
                                kt = DateTime.tryParse(rawTime);
                                if (kt == null) {
                                  try {
                                    kt = DateFormat('yyyy-MM-dd hh:mm a').parse(rawTime);
                                  } catch (_) {}
                                }
                              }
                              kt ??= DateTime.now();
                              return DateFormat("MMM dd, yyyy | hh:mm a").format(kt);
                            })(),
                            style: TextStyle(
                              fontSize: isCardZoomedOut ? 10 : 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: isCardZoomedOut ? 2 : 4),

                      /// ORDER ID + ITEMS COUNT
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Order ID: #$orderId",
                              style: TextStyle(
                                color: const Color(0xffF26B3A),
                                fontSize: isCardZoomedOut ? 10 : 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          Text(
                            "${items.length} Items",
                            style: TextStyle(
                              fontSize: isCardZoomedOut ? 10 : 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xff333333),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: isCardZoomedOut ? 4 : 8),

                      const Divider(height: 1),

                      SizedBox(height: isCardZoomedOut ? 4 : 8),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Qty × Items",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.bold,
                              fontSize: isCardZoomedOut ? 11 : 13,
                            ),
                          ),
                          if (selectedCancelItemKotId == kotId)
                            Padding(
                              padding: EdgeInsets.only(
                                right: isCardZoomedOut ? 8 : 16,
                              ),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    final allSelected = selected.every(
                                      (val) => val,
                                    );
                                    for (int i = 0; i < selected.length; i++) {
                                      selected[i] = !allSelected;
                                    }
                                  });
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "Select All",
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: isCardZoomedOut ? 9 : 11,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      selected.every((val) => val)
                                          ? Icons.check_box
                                          : Icons.check_box_outline_blank,
                                      size: isCardZoomedOut ? 14 : 18,
                                      color:
                                          selected.every((val) => val)
                                              ? Colors.red
                                              : Colors.grey,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),

                      SizedBox(height: isCardZoomedOut ? 4 : 8),

                      Expanded(
                        child: Scrollbar(
                          child: ListView.builder(
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final item = items[index];
                              final String name =
                                  item['name']?.toString() ?? '';
                              final int qty = item['qty'] ?? 1;

                              return InkWell(
                                onTap: () {
                                  if (selectedCancelItemKotId == kotId) {
                                    setState(() {
                                      selected[index] = !selected[index];
                                    });
                                  }
                                },
                                child: Container(
                                  color:
                                      selected[index]
                                          ? Colors.red.withOpacity(.12)
                                          : null,
                                  padding: EdgeInsets.only(
                                    top: isCardZoomedOut ? 2 : 4,
                                    bottom: isCardZoomedOut ? 2 : 4,
                                    right: isCardZoomedOut ? 8 : 16,
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        "$qty × ",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: isCardZoomedOut ? 12 : 14,
                                          color:
                                              selected[index]
                                                  ? Colors.red
                                                  : const Color(0xff333333),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          name,
                                          style: TextStyle(
                                            fontSize: isCardZoomedOut ? 12 : 14,
                                            color:
                                                selected[index]
                                                    ? Colors.red
                                                    : const Color(0xff333333),
                                          ),
                                        ),
                                      ),
                                      if (selectedCancelItemKotId == kotId)
                                        Icon(
                                          selected[index]
                                              ? Icons.check_box
                                              : Icons.check_box_outline_blank,
                                          size: isCardZoomedOut ? 14 : 18,
                                          color:
                                              selected[index]
                                                  ? Colors.red
                                                  : Colors.grey,
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      if (selectedCancelItemKotId == kotId &&
                          selected.any((val) => val) &&
                          !selected.every((val) => val))
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xffFA3633),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                padding: EdgeInsets.symmetric(
                                  vertical: isCardZoomedOut ? 5 : 9,
                                ),
                              ),
                              onPressed: () async {
                                final selectedItems = <Map<String, dynamic>>[];
                                for (int i = 0; i < items.length; i++) {
                                  if (selected[i]) {
                                    selectedItems.add(
                                      items[i] as Map<String, dynamic>,
                                    );
                                  }
                                }

                                if (selectedItems.isNotEmpty) {
                                  final success = await orderProvider
                                      .cancelItems(kotId, selectedItems);
                                  if (success) {
                                    setState(() {
                                      selectedCancelItemKotId = null;
                                      zoomedKotIds.remove(kotId);
                                    });
                                  }
                                }
                              },
                              child: Text(
                                "Confirm Item Cancel",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isCardZoomedOut ? 10 : 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),

                      SizedBox(height: isCardZoomedOut ? 6 : 10),

                      Row(
                        children: [
                          // Left button: Cancel or Revoke
                          Expanded(
                            child: SizedBox(
                              height: isCardZoomedOut ? 30 : 38,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isCardZoomedOut ? 4 : 8,
                                  ),
                                  foregroundColor:
                                      isDineIn
                                          ? const Color(0xffF26B3A)
                                          : const Color(0xff3B73B9),
                                  side: BorderSide(
                                    color:
                                        isDineIn
                                            ? const Color(0xffF26B3A)
                                            : const Color(0xff3B73B9),
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                                icon: Icon(
                                  selectedCancelItemKotId == kotId
                                      ? Icons.undo
                                      : Icons.cancel_outlined,
                                  size: isCardZoomedOut ? 12 : 16,
                                ),
                                label: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    selectedCancelItemKotId == kotId
                                        ? "Undo" //"Revoke"
                                        : "Cancel",
                                    style: TextStyle(
                                      fontSize: isCardZoomedOut ? 11 : 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                onPressed: () {
                                  setState(() {
                                    if (selectedCancelItemKotId == kotId) {
                                      // Revoke: uncheck all and exit cancel mode
                                      for (
                                        int i = 0;
                                        i < selected.length;
                                        i++
                                      ) {
                                        selected[i] = false;
                                      }
                                      selectedCancelItemKotId = null;
                                      zoomedKotIds.remove(kotId);
                                    } else {
                                      // Cancel: enter cancel mode
                                      if (selectedCancelItemKotId != null &&
                                          selectedCancelItemKotId != kotId) {
                                        zoomedKotIds.remove(
                                          selectedCancelItemKotId,
                                        );
                                      }
                                      selectedCancelItemKotId = kotId;
                                      zoomedKotIds.add(kotId);
                                    }
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Right button: Start KOT or Cancel KOT
                          Expanded(
                            child: SizedBox(
                              height: isCardZoomedOut ? 30 : 38,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isCardZoomedOut ? 4 : 8,
                                  ),
                                  backgroundColor:
                                      selected.every((val) => val)
                                          ? const Color(
                                            0xffFA3633,
                                          ) // Cancel KOT background
                                          : (isDineIn
                                              ? const Color(0xffF26B3A)
                                              : const Color(
                                                0xff3B73B9,
                                              )), // Start KOT background
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                                icon: Icon(
                                  selected.every((val) => val)
                                      ? Icons.cancel_outlined
                                      : Icons.play_arrow,
                                  size: isCardZoomedOut ? 12 : 16,
                                  color: Colors.white,
                                ),
                                label: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    selected.every((val) => val)
                                        ? "Cancel KOT"
                                        : "Start KOT",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isCardZoomedOut ? 11 : 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                onPressed: () async {
                                  if (selected.every((val) => val)) {
                                    // Cancel entire order
                                    final success = await orderProvider
                                        .cancelOrder(kotId);
                                    if (success) {
                                      setState(() {
                                        selectedCancelItemKotId = null;
                                        zoomedKotIds.remove(kotId);
                                      });
                                    }
                                  } else {
                                    // Start KOT with remaining items
                                    final remainingItems =
                                        <Map<String, dynamic>>[];
                                    for (int i = 0; i < items.length; i++) {
                                      if (!selected[i]) {
                                        remainingItems.add(
                                          items[i] as Map<String, dynamic>,
                                        );
                                      }
                                    }
                                    await orderProvider.startOrder(
                                      kotId,
                                      remainingItems,
                                    );

                                    // Clear checkboxes and exit cancel mode after starting KOT
                                    setState(() {
                                      for (
                                        int i = 0;
                                        i < selected.length;
                                        i++
                                      ) {
                                        selected[i] = false;
                                      }
                                      if (selectedCancelItemKotId == kotId) {
                                        selectedCancelItemKotId = null;
                                        zoomedKotIds.remove(kotId);
                                      }
                                    });
                                  }
                                },
                              ),
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
        ),
      ],
    );
  }
}
