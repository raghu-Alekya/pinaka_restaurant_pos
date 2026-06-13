import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kds_app/top_bar.dart';
import 'package:kds_app/top_bar.dart';
import 'package:kds_app/widgets/completed_orders.dart';
import 'package:provider/provider.dart';

import 'providers/order_provider.dart';

class ActiveOrdersScreen extends StatefulWidget {
  const ActiveOrdersScreen({super.key});

  @override
  State<ActiveOrdersScreen> createState() => _ActiveOrdersScreenState();
}

class _ActiveOrdersScreenState extends State<ActiveOrdersScreen> {
  String selectedFilter = "All";

  List<Map<String, dynamic>> filterOrders(
      List<Map<String, dynamic>> orders) {
    if (selectedFilter == "All") {
      return orders;
    }

    return orders.where((order) {
      return order['type']
          ?.toString()
          .toLowerCase() ==
          selectedFilter.toLowerCase();
    }).toList();
  }
  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final preparingOrders =
    filterOrders(orderProvider.preparingOrders);

    final readyOrders =
    filterOrders(orderProvider.readyOrders);

    final servedOrders =
    filterOrders(orderProvider.servedOrders);
    return Scaffold(
      backgroundColor: const Color(0xffF5F5F5),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TopBarWidget(orderProvider: orderProvider,),

              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    height: 45,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: const [
                        BoxShadow(blurRadius: 5, color: Colors.black12),
                      ],
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => setState(() => selectedFilter = "All"),
                          child: _filterChip("All", selectedFilter == "All"),
                        ),

                        GestureDetector(
                          onTap: () => setState(() => selectedFilter = "Dine-In"),
                          child: _filterChip("Dine-In", selectedFilter == "Dine-In"),
                        ),

                        GestureDetector(
                          onTap: () => setState(() => selectedFilter = "Takeaway"),
                          child: _filterChip("Takeaways", selectedFilter == "Takeaway"),
                        ),

                        GestureDetector(
                          onTap: () => setState(() => selectedFilter = "Online"),
                          child: _filterChip("Online Orders", selectedFilter == "Online"),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    height: 45,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xff5D78C8)),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Row(
                      children: [
                        _statusChip("Active Orders", true),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: _statusChip("Pending Orders", false),
                        ),
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
                child: Row(
                  children: [
                    Expanded(
                      child: _buildSection(
                        title: "Preparing",
                        color: Colors.orange,
                        child: DragTarget<Map<String, dynamic>>(
                          onAcceptWithDetails: (details) {
                            final orderId =
                                details.data['id']?.toString() ?? '';

                            orderProvider.updateOrderStatus(
                              orderId,
                              'Preparing',
                            );
                          },
                          builder: (context, candidateData, rejectedData) {
                            return preparingOrders.isEmpty
                                ? const Center(
                              child: Text(
                                'No orders in preparing',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                                : ListView.builder(
                              itemCount: preparingOrders.length,
                              itemBuilder: (context, index) {
                                final order = preparingOrders[index];

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Draggable<Map<String, dynamic>>(
                                    data: order,
                                    feedback: Material(
                                      child: SizedBox(
                                        width: 250,
                                        child: _buildOrderCard(order),
                                      ),
                                    ),
                                    childWhenDragging: Opacity(
                                      opacity: 0.3,
                                      child: _buildOrderCard(order),
                                    ),
                                    child: _buildOrderCard(order),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSection(
                        title: "Ready",
                        color: Colors.green,
                        child: DragTarget<Map<String, dynamic>>(
                          onAcceptWithDetails: (details) {
                            final orderId =
                                details.data['id']?.toString() ?? '';
                            orderProvider.updateOrderStatus(orderId, 'Ready');
                          },
                          builder: (context, candidateData, rejectedData) {
                            return ListView.builder(
                              itemCount: readyOrders.length,
                              itemBuilder: (_, index) {
                                final order = readyOrders[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Draggable<Map<String, dynamic>>(
                                    data: order,
                                    feedback: Material(
                                      child: SizedBox(
                                        width: 250,
                                        child: _buildOrderCard(order),
                                      ),
                                    ),
                                    childWhenDragging: Opacity(
                                      opacity: 0.3,
                                      child: _buildOrderCard(order),
                                    ),
                                    child: _buildOrderCard(order),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSection(
                        title: "Served",
                        color: Colors.red,
                        child: DragTarget<Map<String, dynamic>>(
                          onAcceptWithDetails: (details) {
                            final orderId =
                                details.data['id']?.toString() ?? '';
                            orderProvider.updateOrderStatus(orderId, 'Served');
                          },
                          builder: (context, candidateData, rejectedData) {
                            return ListView.builder(
                              itemCount: servedOrders.length,
                              itemBuilder: (_, index) {
                                return _buildOrderCard(servedOrders[index]);
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required Color color,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            height: 50,
            width: double.infinity,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Center(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    return _ExpandableActiveOrderCard(order: order);

  }

  Widget _filterChip(String title, bool selected) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.symmetric(horizontal: 15),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? const Color(0xffFFF2ED) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: selected ? Border.all(color: Colors.orange) : null,
      ),
      child: Text(title),
    );
  }

  Widget _statusChip(String title, bool selected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? const Color(0xff5D78C8) : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        title,
        style: TextStyle(
          color: selected ? Colors.white : const Color(0xff5D78C8),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
class _ExpandableActiveOrderCard extends StatefulWidget {
  final Map<String, dynamic> order;

  const _ExpandableActiveOrderCard({required this.order});

  @override
  State<_ExpandableActiveOrderCard> createState() =>
      _ExpandableActiveOrderCardState();
}

class _ExpandableActiveOrderCardState extends State<_ExpandableActiveOrderCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final headerColor =
        order['headerColor'] as Color? ?? const Color(0xff6C74B8);
    final parentOrderId = order['parentOrderId']?.toString() ?? '';
    final orderType = order['type']?.toString() ?? '';
    final kotNo = order['kotNo']?.toString() ?? '';
    final items = order['items'] as List<dynamic>? ?? [];

    final kotTime = order['kotTime'] is DateTime
        ? order['kotTime'] as DateTime
        : DateTime.now();

    final timeLabel = DateFormat('HH:mm').format(kotTime);
    final dateLabel =
    DateFormat('EEE, MMM d, yyyy | hh:mm a').format(kotTime);

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 4),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header bar (always visible) ──
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: headerColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(10),
                    topRight: const Radius.circular(10),
                    bottomLeft: Radius.circular(_expanded ? 0 : 10),
                    bottomRight: Radius.circular(_expanded ? 0 : 10),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      parentOrderId.isNotEmpty
                          ? 'Order ID #$parentOrderId'
                          : 'Order ID ${order['id']?.toString() ?? ''}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        orderType,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const Icon(Icons.access_time,
                        color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      timeLabel,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 13),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),

            // ── Expanded body only ──
            if (_expanded) ...[
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      'KOT No: $kotNo',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      dateLabel,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ...items.asMap().entries.map((entry) {
                final item =
                Map<String, dynamic>.from(entry.value as Map);
                final name = item['name']?.toString() ?? '';
                final qty = item['qty'] ?? 1;
                final note = item['note']?.toString() ?? '';
                final isLast = entry.key == items.length - 1;

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
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
                          Text(
                            'X $qty',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isLast)
                      Divider(
                        height: 1,
                        thickness: 0.5,
                        color: Colors.grey.shade200,
                      ),
                  ],
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
