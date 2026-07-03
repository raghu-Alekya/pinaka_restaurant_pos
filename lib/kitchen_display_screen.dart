import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kds_app/top_bar.dart';
import 'package:kds_app/widgets/completed_orders.dart';
import 'package:kds_app/widgets/repeated_item.dart';
import 'package:provider/provider.dart';

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
  State<KitchenDashboardScreen> createState() =>
      _KitchenDashboardScreenState();
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().loadExistingOrders();
    });
    _fetchRepeatedItemsCount();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) {
        context.read<OrderProvider>().loadExistingOrders();
        _fetchRepeatedItemsCount();
      },
    );

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
      body: Padding(
        padding: const EdgeInsets.all(12),
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
              activeCount: orderProvider.preparingOrders.length + orderProvider.readyOrders.length,
              repeatedCount: _repeatedItemsCount,
            ),
            const SizedBox(height: 10),
            Expanded(child: bodyWidget),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingBody(
    List<Map<String, dynamic>> filteredOrders,
    OrderProvider orderProvider,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              const Text(
                "Pending KOTs",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff1E293B),
                ),
              ),
              const Spacer(),
              _filterButtonGroup(),
            ],
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xffE2E8F0)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
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
                          : GridView.builder(
                            itemCount: filteredOrders.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 1.0,
                                ),
                            itemBuilder: (context, index) {
                              final order = filteredOrders[index];
                              return _buildOrderCard(order, orderProvider);
                            },
                          ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _filterButtonGroup() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _filterButton(
            title: "All",
            selected: selectedFilter == OrderTypeFilter.all,
            onTap: () {
              setState(() {
                selectedFilter = OrderTypeFilter.all;
              });
            },
          ),
          _filterButton(
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
          _filterButton(
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
          _filterButton(
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
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xff2F4376)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              Icon(
                icon,
                size: 16,
                color: selected ? Colors.white : iconColor,
              ),
            if (icon != null)
              const SizedBox(width: 4),
            Text(
              title,
              style: TextStyle(
                color: selected
                    ? Colors.white
                    : Colors.black87,
                fontWeight: FontWeight.w500,
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

    return Stack(
      children: [
        Container(
          height: 800,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border(
              left: BorderSide(
                color:
                    isDineIn
                        ? const Color(0xffF26B3A)
                        : const Color(0xff3B73B9),
                width: 4,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// TOP ROW
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isDineIn
                                ? const Color(0xffF26B3A)
                                : const Color(0xff3B73B9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tableNo,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              zoneName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const Spacer(),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isDineIn
                                      ? const Color(0xffFFE4D8)
                                      : const Color(0xffD9E9FF),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              orderType.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color:
                                    isDineIn
                                        ? const Color(0xffF26B3A)
                                        : const Color(0xff3B73B9),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 58),

                    const Icon(
                      Icons.access_time_outlined,
                      color: Colors.orange,
                      size: 15,
                    ),

                    const SizedBox(width: 2),

                    Text(
                      order['elapsedTime']?.toString() ?? '0:00',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                /// KOT NO + TIME
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "KOT #$kotNo",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Color(0xff333333),
                        ),
                      ),
                    ),

                    Text(
                      //"Feb 12, 2026 | 11:30 AM",
                      DateFormat(
                        "MMM dd, yyyy | hh:mm a",
                      ).format(DateTime.now()),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                /// ORDER ID + ITEMS COUNT
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Order ID: #$orderId",
                        style: const TextStyle(
                          color: Color(0xffF26B3A),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    Text(
                      "${items.length} Items",
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xff333333),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                const Divider(height: 1),

                const SizedBox(height: 8),

                Text(
                  "Qty × Items",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                ),

                const SizedBox(height: 8),

                Expanded(
                  child: Scrollbar(
                    child: ListView.builder(
                      itemCount: items.length + (selectedCancelItemKotId == kotId ? 1 : 0),
                      itemBuilder: (_, index) {
                        if (selectedCancelItemKotId == kotId && index == 0) {
                          final allChecked = selected.every((val) => val);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: allChecked,
                                  onChanged: (value) {
                                    setState(() {
                                      for (int i = 0; i < selected.length; i++) {
                                        selected[i] = value ?? false;
                                      }
                                    });
                                  },
                                ),
                                const Expanded(
                                  child: Text(
                                    "All",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xff444444),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        final itemIndex = selectedCancelItemKotId == kotId ? index - 1 : index;
                        final item = items[itemIndex] as Map<String, dynamic>;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              if (selectedCancelItemKotId == kotId)
                                Checkbox(
                                  value: selected[itemIndex],
                                  onChanged: (value) {
                                    setState(() {
                                      selected[itemIndex] = value ?? false;
                                    });
                                  },
                                ),
                              Expanded(
                                child: Text(
                                  "1 × ${item['name']}",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: selected[itemIndex]
                                        ? Colors.red
                                        : const Color(0xff444444),
                                    decoration: selected[itemIndex]
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    // Left button: Cancel or Revoke
                    Expanded(
                      child: SizedBox(
                        height: 38,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDineIn ? const Color(0xffF26B3A) : const Color(0xff3B73B9),
                            side: BorderSide(
                              color: isDineIn ? const Color(0xffF26B3A) : const Color(0xff3B73B9),
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
                            size: 16,
                          ),
                          label: Text(
                            selectedCancelItemKotId == kotId ? "Revoke" : "Cancel",
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          onPressed: () {
                            setState(() {
                              if (selectedCancelItemKotId == kotId) {
                                // Revoke: uncheck all and exit cancel mode
                                for (int i = 0; i < selected.length; i++) {
                                  selected[i] = false;
                                }
                                selectedCancelItemKotId = null;
                              } else {
                                // Cancel: enter cancel mode
                                selectedCancelItemKotId = kotId;
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
                        height: 38,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: selected.every((val) => val)
                                ? const Color(0xffFA3633) // Cancel KOT background
                                : (isDineIn ? const Color(0xffF26B3A) : const Color(0xff3B73B9)), // Start KOT background
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          icon: Icon(
                            selected.every((val) => val)
                                ? Icons.cancel_outlined
                                : Icons.play_arrow,
                            size: 16,
                            color: Colors.white,
                          ),
                          label: Text(
                            selected.every((val) => val) ? "Cancel KOT" : "Start KOT",
                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          onPressed: () async {
                            if (selected.every((val) => val)) {
                              // Cancel entire order
                              final success = await orderProvider.cancelOrder(kotId);
                              if (success) {
                                setState(() {
                                  selectedCancelItemKotId = null;
                                });
                              }
                            } else {
                              // Start KOT with remaining items
                              final remainingItems = <Map<String, dynamic>>[];
                              for (int i = 0; i < items.length; i++) {
                                if (!selected[i]) {
                                  remainingItems.add(items[i] as Map<String, dynamic>);
                                }
                              }
                              await orderProvider.startOrder(kotId, remainingItems);
                              
                              // Clear checkboxes and exit cancel mode after starting KOT
                              setState(() {
                                for (int i = 0; i < selected.length; i++) {
                                  selected[i] = false;
                                }
                                if (selectedCancelItemKotId == kotId) {
                                  selectedCancelItemKotId = null;
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
    );
  }

  }
