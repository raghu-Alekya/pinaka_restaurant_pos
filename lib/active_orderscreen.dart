import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kds_app/top_bar.dart';
import 'package:kds_app/widgets/completed_orders.dart';
import 'package:provider/provider.dart';

import 'providers/order_provider.dart';

class ActiveOrdersScreen extends StatefulWidget {
  final String token;
  final int restaurantId;
  final int? recalledOrderId;
  final bool isEmbedded;

  const ActiveOrdersScreen({
    super.key,
    required this.token,
    required this.restaurantId,
    this.recalledOrderId,
    this.isEmbedded = false,
  });

  @override
  State<ActiveOrdersScreen> createState() => _ActiveOrdersScreenState();
}

class _ActiveOrdersScreenState extends State<ActiveOrdersScreen> {
  OrderTypeFilter selectedFilter = OrderTypeFilter.all;
  KotView selectedView = KotView.active;

  final ScrollController _preparingScrollController = ScrollController();
  final ScrollController _readyScrollController = ScrollController();
  final ScrollController _servedScrollController = ScrollController();

  @override
  void dispose() {
    _preparingScrollController.dispose();
    _readyScrollController.dispose();
    _servedScrollController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> filterOrders(List<Map<String, dynamic>> orders) {
    switch (selectedFilter) {
      case OrderTypeFilter.all:
        return orders;

      case OrderTypeFilter.dineIn:
        return orders.where((order) {
          return order['type']?.toString().toLowerCase().contains('dine') ??
              false;
        }).toList();

      case OrderTypeFilter.takeaway:
        return orders.where((order) {
          return order['type']?.toString().toLowerCase().contains('takeaway') ??
              false;
        }).toList();

      case OrderTypeFilter.online:
        return orders.where((order) {
          return order['type']?.toString().toLowerCase().contains('online') ??
              false;
        }).toList();
    }
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

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final preparingOrders = filterOrders(orderProvider.preparingOrders);

    final readyOrders = filterOrders(orderProvider.readyOrders);

    final servedOrders = filterOrders(orderProvider.servedOrders);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xffe2e8f0)),
      ),
      child: Column(
        children: [
          if (widget.isEmbedded)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: SizedBox(
                height: 52,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Active KOTs",
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
            )
          else
            TopBarWidget(
              token: widget.token,
              restaurantId: widget.restaurantId,
              selectedView: selectedView,
              onViewChanged: (view) {
                setState(() {
                  selectedView = view;

                  if (view == KotView.pending) {
                    Navigator.pop(context);
                  }
                });
              },
              onLogout: () {},
            ),

          if (!widget.isEmbedded) const SizedBox(height: 22),

          if (!widget.isEmbedded) const SizedBox(height: 20),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildSection(
                    title: "Preparing",
                    //color: const Color(0xffF59E0B), //
                    color: const Color(0xFFFF0000),
                    child: DragTarget<Map<String, dynamic>>(
                      onWillAcceptWithDetails: (details) {
                        final status =
                            details.data['status']?.toString().toLowerCase() ??
                            '';
                        return status == 'ready';
                      },
                      onAcceptWithDetails: (details) {
                        final orderId = details.data['id']?.toString() ?? '';

                        orderProvider.updateOrderStatus(orderId, 'Preparing');
                      },
                      builder: (context, candidateData, rejectedData) {
                        return preparingOrders.isEmpty
                            ? _buildEmptyState(
                              color: Colors.orange,
                              title: "Preparing...",
                            )
                            : Scrollbar(
                                controller: _preparingScrollController,
                                thumbVisibility: true,
                                child: ListView.builder(
                                  controller: _preparingScrollController,
                                  padding: EdgeInsets.zero,
                                  itemCount: preparingOrders.length,
                                  itemBuilder: (context, index) {
                                    final order = preparingOrders[index];

                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
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
                                ),
                              );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildSection(
                    title: "Ready",
                    color: const Color(0xff2563EB),
                    child: DragTarget<Map<String, dynamic>>(
                      onWillAcceptWithDetails: (details) {
                        final status =
                            details.data['status']?.toString().toLowerCase() ??
                            '';
                        return status == 'preparing';
                      },
                      onAcceptWithDetails: (details) {
                        final orderId = details.data['id']?.toString() ?? '';
                        orderProvider.updateOrderStatus(orderId, 'Ready');
                      },
                      builder: (context, candidateData, rejectedData) {
                        if (readyOrders.isEmpty) {
                          return _buildEmptyState(
                            color: const Color(0xff2563EB),
                            title: "Ready",
                          );
                        }

                        return Scrollbar(
                          controller: _readyScrollController,
                          thumbVisibility: true,
                          child: ListView.builder(
                            controller: _readyScrollController,
                            padding: EdgeInsets.zero,
                            itemCount: readyOrders.length,
                            itemBuilder: (_, index) {
                              final order = readyOrders[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
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
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSection(
                    title: "Served",
                    color: const Color(0xff16A34A),
                    child: DragTarget<Map<String, dynamic>>(
                      onWillAcceptWithDetails: (details) {
                        final status =
                            details.data['status']?.toString().toLowerCase() ??
                            '';
                        return status == 'ready';
                      },
                      onAcceptWithDetails: (details) {
                        final orderId = details.data['id']?.toString() ?? '';
                        orderProvider.updateOrderStatus(orderId, 'Served');
                      },
                      builder: (context, candidateData, rejectedData) {
                        if (servedOrders.isEmpty) {
                          return _buildEmptyState(
                            color: const Color(0xff16A34A),
                            title: "Served",
                          );
                        }

                        return Scrollbar(
                          controller: _servedScrollController,
                          thumbVisibility: true,
                          child: ListView.builder(
                            controller: _servedScrollController,
                            padding: EdgeInsets.zero,
                            itemCount: servedOrders.length,
                            itemBuilder: (_, index) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _buildOrderCard(servedOrders[index]),
                              );
                            },
                          ),
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
    );

    // if (widget.isEmbedded) {
    //   return Padding(
    //     padding: const EdgeInsets.symmetric(horizontal: 4),
    //     child: content,
    //   );
    // }

    // return Scaffold(
    //   backgroundColor: const Color(0xffF5F5F5),
    //   body: SafeArea(
    //     child: Padding(padding: const EdgeInsets.all(16), child: content),
    //   ),
    // );
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
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 50,
            width: double.infinity,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(11),
                topRight: Radius.circular(11),
              ),
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/chef.png',
                    width: 22,
                    height: 22,
                    color: Colors.white,
                  ),

                  const SizedBox(width: 6),

                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final kotId = order['id']?.toString() ?? UniqueKey().toString();
    return _ExpandableActiveOrderCard(key: ValueKey(kotId), order: order);
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

  const _ExpandableActiveOrderCard({super.key, required this.order});

  @override
  State<_ExpandableActiveOrderCard> createState() =>
      _ExpandableActiveOrderCardState();
}

class _ExpandableActiveOrderCardState
    extends State<_ExpandableActiveOrderCard> {
  bool _expanded = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final orderType = order['type']?.toString() ?? '';
    final status = order['status']?.toString() ?? '';

    final Color headerColor;

    if (status == 'Ready') {
      headerColor = const Color(0xFF60A5FA); // Blue
    } else if (status == 'Served') {
      headerColor = const Color(0xFF22C55E); // Green
    } else {
      if (orderType.toLowerCase().contains('dine')) {
        headerColor = const Color(0xffF59E0B); // Dine-In (Amber)
      } else if (orderType.toLowerCase().contains('take')) {
        //headerColor = const Color(0xff0D3B66); // Takeaway
        headerColor = const Color(0xffF59E0B);
      } else if (orderType.toLowerCase().contains('online')) {
        headerColor = const Color(0xff16A34A); // Online
      } else {
        headerColor = const Color(0xff6C74B8); // Default
      }
    }
    final parentOrderId = order['parentOrderId']?.toString() ?? '';
    // final orderType = order['type']?.toString() ?? '';
    final kotNo = order['kotNo']?.toString() ?? '';
    final items = order['items'] as List<dynamic>? ?? [];

    final kotTime =
        order['kotTime'] is DateTime
            ? order['kotTime'] as DateTime
            : DateTime.now();

    final timeLabel = DateFormat('HH:mm').format(kotTime);
    final dateLabel = DateFormat('EEE, MMM d, yyyy | hh:mm a').format(kotTime);

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header bar (always visible) ──
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: headerColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(4),
                    topRight: const Radius.circular(4),
                    bottomLeft: Radius.circular(_expanded ? 0 : 4),
                    bottomRight: Radius.circular(_expanded ? 0 : 4),
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
                    const Icon(
                      Icons.access_time,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      timeLabel,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: Colors.white,
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),

            // ── Expanded body only ──
            if (_expanded) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
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
              Container(
                constraints: const BoxConstraints(maxHeight: 180),
                child: Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: items.asMap().entries.map((entry) {
                        final item = Map<String, dynamic>.from(entry.value as Map);
                        final name = item['name']?.toString() ?? '';
                        final qty = item['qty'] ?? 1;
                        final note = item['note']?.toString() ?? '';
                        final isLast = entry.key == items.length - 1;
                        final List modifiers = item['modifiers'] ?? [];
                        final List addons = item['addons'] ?? [];

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
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: item['status']?.toString().toLowerCase() == 'cancelled' ||
                                                item['status']?.toString().toLowerCase() == 'cancel'
                                                ? Colors.red
                                                : Colors.black87,
                                            decoration: item['status']?.toString().toLowerCase() == 'cancelled' ||
                                                item['status']?.toString().toLowerCase() == 'cancel'
                                                ? TextDecoration.lineThrough
                                                : null,
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

                                        /// -------- MODIFIERS (RED) --------
                                        if (modifiers.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(left: 12, top: 4),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: modifiers.map<Widget>((modifier) {
                                                final modifierName = modifier is Map
                                                    ? modifier['name']?.toString() ?? ''
                                                    : modifier.toString();

                                                return Padding(
                                                  padding: const EdgeInsets.only(bottom: 2),
                                                  child: Text(
                                                    "• $modifierName",
                                                    style: const TextStyle(
                                                      color: Colors.red,
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                            ),
                                          ),

                                        /// -------- ADDONS (BLUE) --------
                                        if (addons.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(left: 12, top: 2),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: addons.map<Widget>((addon) {
                                                final addonName = addon is Map
                                                    ? addon['name']?.toString() ?? ''
                                                    : addon.toString();

                                                final addonQty = addon is Map
                                                    ? (addon['qty'] ?? 1)
                                                    : 1;

                                                return Padding(
                                                  padding: const EdgeInsets.only(bottom: 2),
                                                  child: Text(
                                                    "+ $addonQty × $addonName",
                                                    style: const TextStyle(
                                                      color: Colors.blue,
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    'X $qty',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          item['status']?.toString().toLowerCase() ==
                                                      'cancelled' ||
                                                  item['status']
                                                          ?.toString()
                                                          .toLowerCase() ==
                                                      'cancel'
                                              ? Colors.red
                                              : Colors.black87,
                                      decoration:
                                          item['status']?.toString().toLowerCase() ==
                                                      'cancelled' ||
                                                  item['status']
                                                          ?.toString()
                                                          .toLowerCase() ==
                                                      'cancel'
                                              ? TextDecoration.lineThrough
                                              : null,
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
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

Widget _buildEmptyState({required Color color, required String title}) {
  return Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: color.withOpacity(.03),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(.35)),
    ),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 75,
            height: 75,
            decoration: BoxDecoration(
              color: color.withOpacity(.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.room_service_outlined, color: color, size: 42),
          ),

          const SizedBox(height: 15),

          Text(
            "Drop here to move to",
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),

          const SizedBox(height: 4),

          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    ),
  );
}
