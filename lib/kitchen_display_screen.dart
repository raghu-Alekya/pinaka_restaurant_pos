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

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final orders = orderProvider.pendingOrders;

    final filteredOrders = orders.where((order) {
      if (selectedOrderType == "All") return true;
      return order["type"] == selectedOrderType;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xffF4F4F4),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TopBarWidget(orderProvider: orderProvider,),

            // const SizedBox(height: 16),
            // const DebugLogPanel(),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue, width: 2),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          height: 45,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            children: [
                              _filterChip("All"),
                              _filterChip("Dine-In"),
                              _filterChip("Takeaway"),
                              _filterChip("Online"),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Container(
                          height: 45,
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xff6C74B8)),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const ActiveOrdersScreen(),
                                    ),
                                  );
                                },
                                child: _statusTab("Active Orders", false),
                              ),
                              _statusTab("Pending Orders", true),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xffFF5B4F),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 25,
                              vertical: 15,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          onPressed: () {
                            print("Navigating to Completed Orders");
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CompletedOrdersScreen(token: '',),
                              ),
                            );
                          },
                          child: const Text(
                            "Completed Orders →",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      ],
                    ),
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
                                crossAxisSpacing: 15,
                                mainAxisSpacing: 15,
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
        ),
      ),
    );
  }

  Widget _connectionBadge(OrderProvider provider) {
    final connected =
        provider.connectionState == KdsConnectionState.connected;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: connected ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: connected ? Colors.green : Colors.red,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.circle,
            size: 10,
            color: connected ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 6),
          Text(
            connected ? 'POS Connected' : 'Disconnected',
            style: TextStyle(
              fontSize: 12,
              color: connected ? Colors.green.shade800 : Colors.red.shade800,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildOrderCard(
      Map<String, dynamic> order,
      OrderProvider orderProvider,
      ) {
    final kotId = order['id']?.toString() ?? '';
    final parentOrderId = order['parentOrderId']?.toString() ?? '';
    final kotNo = order['kotNo']?.toString() ??
        order['kotNumber']?.toString().replaceAll('KOT#', '') ?? '';
    final locationLabel = order['locationLabel']?.toString() ?? '';
    final orderType = order['type']?.toString() ?? '';
    final items = order['items'] as List<dynamic>? ?? [];
    final headerColor = order['headerColor'] as Color? ?? const Color(0xff6C74B8);

    final kotTime = order['kotTime'] is DateTime
        ? order['kotTime'] as DateTime
        : DateTime.now();

    final timeLabel = DateFormat('HH:mm').format(kotTime);
    final dateLabel = DateFormat('EEE, MMM d, yyyy | hh:mm a').format(kotTime);

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header bar ──
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: headerColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      parentOrderId.isNotEmpty
                          ? 'Order ID #$parentOrderId'
                          : 'Order ID #—',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        orderType,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time, color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          timeLabel,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Zone / Table + Date ──
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        locationLabel,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xff333333),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      dateLabel,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),

              // ── Items x Qty | KOT No ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Row(
                  children: [
                    const Text(
                      'Items x Qty',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    const Spacer(),
                    Text(
                      'KOT No: $kotNo',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, thickness: 1),

              // ── Item list ──
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 16,
                    thickness: 0.5,
                    color: Colors.grey.shade200,
                  ),
                  itemBuilder: (_, index) {
                    final item = Map<String, dynamic>.from(items[index] as Map);
                    final name = item['name']?.toString() ?? '';
                    final qty = item['qty'] ?? 1;
                    final note = item['note']?.toString() ?? '';
                    // final status = item['status']?.toString() ?? '';

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$name  x $qty',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (note.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    '($note)',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Text(
                        //   '• $status',
                        //   style: TextStyle(
                        //     fontSize: 12,
                        //     color: Colors.grey.shade700,
                        //   ),
                        // ),
                      ],
                    );
                  },
                ),
              ),

              // ── Ready count ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'Ready: 0 / ${items.length}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),

              const SizedBox(height: 10),

              // ── Buttons ──
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xffFF5B4F),
                          side: const BorderSide(color: Color(0xffFF5B4F)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => orderProvider.cancelOrder(kotId),
                        child: const Text('Cancel', style: TextStyle(fontSize: 15)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xffFF5B4F),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () async {
                          final ok = await orderProvider.startOrder(kotId);
                          if (!context.mounted) return;
                          if (!ok) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Failed to start order. Check API token and connection.',
                                ),
                              ),
                            );
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ActiveOrdersScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Start Order',
                          style: TextStyle(color: Colors.white, fontSize: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Cancelled overlay (keep as-is)
        if (order['isCancelled'] == true)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'KOT order cancelled',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () =>
                          orderProvider.recallOrder(order['id']),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Recall'),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
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
