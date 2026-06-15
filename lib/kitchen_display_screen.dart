import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kds_app/top_bar.dart';
import 'package:kds_app/widgets/completed_orders.dart';
import 'package:provider/provider.dart';

import 'active_orderscreen.dart';
import 'providers/order_provider.dart';
import 'services/kds_mqtt_service.dart';
import 'widgets/debug_log_panel.dart';

class KitchenDashboardScreen extends StatefulWidget {
  final VoidCallback? onOpenSettings;

  const KitchenDashboardScreen({super.key, this.onOpenSettings});

  @override
  State<KitchenDashboardScreen> createState() =>
      _KitchenDashboardScreenState();
}

class _KitchenDashboardScreenState extends State<KitchenDashboardScreen> {
  String selectedOrderType = "All";
  OrderTypeFilter selectedFilter =
      OrderTypeFilter.all;
  String? selectedCancelKotId;

  KotView selectedView =
      KotView.pending;

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final orders = orderProvider.pendingOrders;

    final filteredOrders = orders.where((order) {
      final type =
          order['type']?.toString().toLowerCase() ?? '';

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


    return Scaffold(
      backgroundColor: const Color(0xffF4F4F4),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TopBarWidget(
              selectedFilter: selectedFilter,
              selectedView: selectedView,

              onFilterChanged: (filter) {
                setState(() {
                  selectedFilter = filter;
                });
              },

              onViewChanged: (view) {
                setState(() {
                  selectedView = view;
                });
              },
            ),

            const SizedBox(height: 10),
            // const DebugLogPanel(),
            // const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue, width: 2),
                ),
                child: Column(
                  children: [
                    // Row(
                    //   children: [
                    //     Container(
                    //       height: 45,
                    //       padding: const EdgeInsets.all(4),
                    //       decoration: BoxDecoration(
                    //         color: Colors.white,
                    //         borderRadius: BorderRadius.circular(30),
                    //       ),
                    //       child: Row(
                    //         children: [
                    //           _filterChip("All"),
                    //           _filterChip("Dine-In"),
                    //           _filterChip("Takeaway"),
                    //           _filterChip("Online"),
                    //         ],
                    //       ),
                    //     ),
                    //     const Spacer(),
                    //     Container(
                    //       height: 45,
                    //       decoration: BoxDecoration(
                    //         border: Border.all(color: const Color(0xff6C74B8)),
                    //         borderRadius: BorderRadius.circular(30),
                    //       ),
                    //       child: Row(
                    //         children: [
                    //           GestureDetector(
                    //             onTap: () {
                    //               Navigator.push(
                    //                 context,
                    //                 MaterialPageRoute(
                    //                   builder: (_) =>
                    //                       const ActiveOrdersScreen(),
                    //                 ),
                    //               );
                    //             },
                    //             child: _statusTab("Active Orders", false),
                    //           ),
                    //           _statusTab("Pending Orders", true),
                    //         ],
                    //       ),
                    //     ),
                    //     const SizedBox(width: 20),
                    //     ElevatedButton(
                    //       style: ElevatedButton.styleFrom(
                    //         backgroundColor: const Color(0xffFF5B4F),
                    //         padding: const EdgeInsets.symmetric(
                    //           horizontal: 25,
                    //           vertical: 15,
                    //         ),
                    //         shape: RoundedRectangleBorder(
                    //           borderRadius: BorderRadius.circular(25),
                    //         ),
                    //       ),
                    //       onPressed: () {
                    //         print("Navigating to Completed Orders");
                    //         Navigator.push(
                    //           context,
                    //           MaterialPageRoute(
                    //             builder: (_) => const CompletedOrdersScreen(token: '',),
                    //           ),
                    //         );
                    //       },
                    //       child: const Text(
                    //         "Completed Orders →",
                    //         style: TextStyle(
                    //           color: Colors.white,
                    //           fontSize: 14,
                    //           fontWeight: FontWeight.w600,
                    //         ),
                    //       ),
                    //     )
                    //   ],
                    // ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: filteredOrders.isEmpty
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
                                childAspectRatio: 1.08,
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
        ),
      ),
    );
  }

  // Widget _connectionBadge(OrderProvider provider) {
  //   final connected =
  //       provider.connectionState == KdsConnectionState.connected;
  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  //     decoration: BoxDecoration(
  //       color: connected ? Colors.green.shade50 : Colors.red.shade50,
  //       borderRadius: BorderRadius.circular(12),
  //       border: Border.all(
  //         color: connected ? Colors.green : Colors.red,
  //       ),
  //     ),
  //     child: Row(
  //       mainAxisSize: MainAxisSize.min,
  //       children: [
  //         Icon(
  //           Icons.circle,
  //           size: 10,
  //           color: connected ? Colors.green : Colors.red,
  //         ),
  //         const SizedBox(width: 6),
  //         Text(
  //           connected ? 'POS Connected' : 'Disconnected',
  //           style: TextStyle(
  //             fontSize: 12,
  //             color: connected ? Colors.green.shade800 : Colors.red.shade800,
  //             fontWeight: FontWeight.w600,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildOrderCard(
      Map<String, dynamic> order,
      OrderProvider orderProvider,
      ) {
    final kotId = order['id']?.toString() ?? '';
    final orderId = order['parentOrderId']?.toString() ?? '';
    final kotNo = order['kotNo']?.toString() ?? '';
    final orderType = order['type']?.toString() ?? '';
    final location = order['locationLabel']?.toString() ?? '';
    final tableNo =
        order['tableName']?.toString() ??
            order['tableNo']?.toString() ??
            '';

    String zoneName =
        order['zoneName']?.toString() ?? '';

    if (zoneName.isEmpty) {
      final location =
          order['locationLabel']?.toString() ?? '';

      if (location.contains(' - ')) {
        final parts = location.split(' - ');

        if (parts.length >= 2) {
          zoneName = parts[1];

          if (zoneName.contains('-')) {
            zoneName =
                zoneName.substring(0, zoneName.lastIndexOf('-'));
          }
        }
      }
    }

    final items = order['items'] as List<dynamic>? ?? [];

    final isDineIn =
    orderType.toLowerCase().contains('dine');

    return Stack(
      children: [

     Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(
            color: isDineIn
                ? const Color(0xffF26B3A)
                : const Color(0xff3B73B9),
            width: 3,
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
          crossAxisAlignment:
          CrossAxisAlignment.start,
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
                    color: isDineIn
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
                color: isDineIn
                    ? const Color(0xffFFE4D8)
                    : const Color(0xffD9E9FF),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                orderType.toUpperCase(),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: isDineIn
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
                  "Feb 12, 2026 | 11:30 AM",
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
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 10,
              ),
            ),

            const SizedBox(height: 8),

            Expanded(
              child: Scrollbar(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (_, index) {
                    final item =
                    items[index]
                    as Map<String, dynamic>;

                    return Padding(
                      padding:
                      const EdgeInsets.only(
                        bottom: 10,
                      ),
                      child: Text(
                        "1 × ${item['name']}",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xff444444),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            SizedBox(
              width: double.infinity,
              height: 38,
              child: ElevatedButton.icon(
                icon: const Icon(
                  Icons.play_arrow,
                  size: 16,
                  color: Colors.white,
                ),
                label: const Text(
                  "Start KOT",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  const Color(0xffFF6666),
                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(5),
                  ),
                ),
                onPressed: () async {
                  await orderProvider
                      .startOrder(kotId);

                  if (!context.mounted) return;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                      const ActiveOrdersScreen(),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 28,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xff0C62D8),
                        side: const BorderSide(
                          color: Color(0xff0C62D8),
                          width: 1,
                        ),
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      icon: const Icon(
                        Icons.remove_circle_outline,
                        size: 12,
                        color: Color(0xff0C62D8),
                      ),
                      label: const Text(
                        "Cancel Item",
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xff0C62D8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onPressed: () {},
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: SizedBox(
                    height: 28,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xffFA3633),
                        side: const BorderSide(
                          color: Color(0xffFA3633),
                          width: 1,
                        ),
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      icon: const Icon(
                        Icons.cancel_outlined,
                        size: 12,
                        color: Color(0xffFA3633),
                      ),
                      label: const Text(
                        "Cancel KOT",
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xffFA3633),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          selectedCancelKotId = kotId;
                        });
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
        // ADD THIS BLOCK HERE
        if (selectedCancelKotId == kotId)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.75),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    const Text(
                      "Cancel KOT?",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [

                        ElevatedButton(
                          onPressed: () async {
                            await orderProvider.cancelOrder(kotId);

                            setState(() {
                              selectedCancelKotId = null;
                            });
                          },
                          child: const Text("Yes"),
                        ),

                        const SizedBox(width: 10),

                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              selectedCancelKotId = null;
                            });
                          },
                          child: const Text("No"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ]);
  }
  Widget _filterChip(String title) {
    final isSelected = selectedOrderType == title;
    return GestureDetector(
      onTap: () => setState(() => selectedOrderType = title),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xffFFF2ED) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? Border.all(color: Colors.orange) : null,
        ),
        alignment: Alignment.center,
        child: Text(title),
      ),
    );
  }

  Widget _statusTab(String title, bool selected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? const Color(0xff6C74B8) : Colors.white,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Text(
        title,
        style: TextStyle(
          color: selected ? Colors.white : const Color(0xff6C74B8),
        ),
      ),
    );
  }
}
