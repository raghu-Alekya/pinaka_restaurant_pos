import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../active_orderscreen.dart';
import '../models/complete_order_model.dart';
import '../providers/order_provider.dart';
import '../services/api_services.dart';
import '../services/completeorder_api service.dart';
import '../top_bar.dart';

class CompletedOrdersScreen extends StatefulWidget {
  final String token;
  final int restaurantId;
  final bool isEmbedded;
  final VoidCallback? onRecallSuccess;

  const CompletedOrdersScreen({
    super.key,
    required this.token,
    required this.restaurantId,
    this.isEmbedded = false,
    this.onRecallSuccess,
  });

  @override
  State<CompletedOrdersScreen> createState() => _CompletedOrdersScreenState();
}

class _CompletedOrdersScreenState extends State<CompletedOrdersScreen> {
  List<CompletedOrderModel> allOrders = [];
  List<CompletedOrderModel> filteredOrders = [];
  OrderTypeFilter selectedFilter = OrderTypeFilter.all;
  KotView selectedView = KotView.history;

  String selectedOrderType = 'All';
  String searchText = '';
  String? selectedDuration;
  int currentPage = 1;
  int rowsPerPage = 8;
  String selectedStatus = 'All Status';

  List<CompletedOrderModel> paginatedOrders = [];

  List<CompletedOrderModel> orders = [];
  bool isLoading = true;
  // ADD THESE
  DateTime? selectedDate;
  final TextEditingController _dateController = TextEditingController();
  int get totalPages {
    if (filteredOrders.isEmpty) return 1;
    return (filteredOrders.length / rowsPerPage).ceil();
  }

  int get totalKotsCount {
    return allOrders
        .where((order) => _matchAllFiltersExceptStatus(order))
        .length;
  }

  int get completedKotsCount {
    return allOrders
        .where(
          (order) =>
              _matchAllFiltersExceptStatus(order) &&
              order.status.toLowerCase() == 'completed',
        )
        .length;
  }

  int get cancelledKotsCount {
    return allOrders
        .where(
          (order) =>
              _matchAllFiltersExceptStatus(order) &&
              order.status.toLowerCase() == 'cancelled',
        )
        .length;
  }

  bool _matchAllFiltersExceptStatus(CompletedOrderModel order) {
    // Search Filter
    final matchSearch =
        searchText.isEmpty ||
        order.orderId.toString().contains(searchText) ||
        order.kotNumber.toLowerCase().contains(searchText.toLowerCase());

    // Order Type Filter
    bool matchType = false;
    if (selectedOrderType == 'All') {
      matchType = true;
    } else if (selectedOrderType.toLowerCase().contains('dine')) {
      matchType = order.orderType.toLowerCase().contains('dine');
    } else if (selectedOrderType.toLowerCase().contains('take')) {
      matchType = order.orderType.toLowerCase().contains('take');
    } else if (selectedOrderType.toLowerCase().contains('online')) {
      matchType = order.orderType.toLowerCase().contains('online');
    } else {
      matchType = order.orderType.toLowerCase().contains(
        selectedOrderType.toLowerCase(),
      );
    }

    // Date Filter
    bool matchDate = true;
    if (selectedDate != null && order.finishedDateTime != null) {
      final orderDate = order.finishedDateTime!;
      matchDate =
          orderDate.year == selectedDate!.year &&
          orderDate.month == selectedDate!.month &&
          orderDate.day == selectedDate!.day;
    }

    // Duration Filter
    bool matchDuration = true;
    if (selectedDuration != null && order.finishedDateTime != null) {
      final now = DateTime.now();
      final orderDate = order.finishedDateTime!;
      final diff = now.difference(orderDate);

      switch (selectedDuration) {
        case '30 Min':
          matchDuration = diff.inMinutes <= 30;
          break;
        case '60 Min':
          matchDuration = diff.inMinutes <= 60;
          break;
        case '5 Hours':
          matchDuration = diff.inHours <= 5;
          break;
        case '24 Hours':
          matchDuration = diff.inHours <= 24;
          break;
      }
    }

    return matchSearch && matchType && matchDate && matchDuration;
  }

  @override
  void initState() {
    super.initState();
    loadOrders();
    print("CompletedOrdersScreen Opened");
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  void applyPagination() {
    if (filteredOrders.isEmpty) {
      paginatedOrders = [];
      return;
    }

    final start = (currentPage - 1) * rowsPerPage;

    if (start >= filteredOrders.length) {
      currentPage = 1;
    }

    final newStart = (currentPage - 1) * rowsPerPage;

    final end =
        (newStart + rowsPerPage) > filteredOrders.length
            ? filteredOrders.length
            : (newStart + rowsPerPage);

    paginatedOrders = filteredOrders.sublist(newStart, end);
  }

  Future<void> loadOrders() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
    });

    try {
      final fetched = await getCompletedOrders(
        token: widget.token,
        restaurantId: widget.restaurantId,
        page: 1,
        perPage: 1000,

        // Default: today
        fromDate:
            selectedDate != null
                ? DateTime(
                  selectedDate!.year,
                  selectedDate!.month,
                  selectedDate!.day,
                )
                : DateTime(
                  DateTime.now().year,
                  DateTime.now().month,
                  DateTime.now().day,
                ),

        // Default: today
        toDate: DateTime.now(),
        orderType: null,
        status: null,
      );

      if (!mounted) return;
      setState(() {
        allOrders = fetched.orders;
        filteredOrders = List.from(allOrders);
        currentPage = 1;
        applyFilters();
      });
    } catch (e) {
      debugPrint("Load Orders Error: $e");
    }

    if (!mounted) return;
    setState(() {
      isLoading = false;
    });
  }

  void applyFilters() {
    filteredOrders =
        allOrders.where((order) {
          // Search Filter
          final matchSearch =
              searchText.isEmpty ||
              order.orderId.toString().contains(searchText) ||
              order.kotNumber.toLowerCase().contains(searchText.toLowerCase());

          // Order Type Filter
          bool matchType = false;
          if (selectedOrderType == 'All') {
            matchType = true;
          } else if (selectedOrderType.toLowerCase().contains('dine')) {
            matchType = order.orderType.toLowerCase().contains('dine');
          } else if (selectedOrderType.toLowerCase().contains('take')) {
            matchType = order.orderType.toLowerCase().contains('take');
          } else if (selectedOrderType.toLowerCase().contains('online')) {
            matchType = order.orderType.toLowerCase().contains('online');
          } else {
            matchType = order.orderType.toLowerCase().contains(
              selectedOrderType.toLowerCase(),
            );
          }

          // Status Filter
          bool matchStatus = true;
          if (selectedStatus != 'All Status') {
            matchStatus =
                order.status.toLowerCase() == selectedStatus.toLowerCase();
          }

          // Date Filter
          bool matchDate = true;
          if (selectedDate != null && order.finishedDateTime != null) {
            final orderDate = order.finishedDateTime!;
            matchDate =
                orderDate.year == selectedDate!.year &&
                orderDate.month == selectedDate!.month &&
                orderDate.day == selectedDate!.day;
          }

          // Duration Filter
          bool matchDuration = true;
          if (selectedDuration != null && order.finishedDateTime != null) {
            final now = DateTime.now();
            final orderDate = order.finishedDateTime!;
            final diff = now.difference(orderDate);

            switch (selectedDuration) {
              case '30 Min':
                matchDuration = diff.inMinutes <= 30;
                break;
              case '60 Min':
                matchDuration = diff.inMinutes <= 60;
                break;
              case '5 Hours':
                matchDuration = diff.inHours <= 5;
                break;
              case '24 Hours':
                matchDuration = diff.inHours <= 24;
                break;
            }
          }

          return matchSearch &&
              matchType &&
              matchStatus &&
              matchDate &&
              matchDuration;
        }).toList();

    currentPage = 1;
    applyPagination();
  }

  void setFilter(OrderTypeFilter filter) {
    setState(() {
      selectedFilter = filter;
      switch (filter) {
        case OrderTypeFilter.all:
          selectedOrderType = 'All';
          break;
        case OrderTypeFilter.dineIn:
          selectedOrderType = 'Dine In';
          break;
        case OrderTypeFilter.takeaway:
          selectedOrderType = 'Takeaway';
          break;
        case OrderTypeFilter.online:
          selectedOrderType = 'Online';
          break;
      }
      currentPage = 1;
    });
    applyFilters();
  }

  Widget _filterButtonGroup() {
    return Container(
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
        mainAxisSize: MainAxisSize.min,
        children: [
          _filterButton(
            title: "All",
            selected: selectedFilter == OrderTypeFilter.all,
            icon: Icons.grid_view,
            iconColor: const Color(0xff2F4376),
            onTap: () => setFilter(OrderTypeFilter.all),
          ),
          _filterButton(
            title: "Dine-In",
            selected: selectedFilter == OrderTypeFilter.dineIn,
            icon: Icons.restaurant,
            iconColor: Colors.orange,
            onTap: () => setFilter(OrderTypeFilter.dineIn),
          ),
          _filterButton(
            title: "Takeaways",
            selected: selectedFilter == OrderTypeFilter.takeaway,
            icon: Icons.shopping_bag_outlined,
            iconColor: Colors.blueGrey,
            onTap: () => setFilter(OrderTypeFilter.takeaway),
          ),
          _filterButton(
            title: "Online Orders",
            selected: selectedFilter == OrderTypeFilter.online,
            icon: Icons.delivery_dining,
            iconColor: Colors.green,
            onTap: () => setFilter(OrderTypeFilter.online),
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
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xff2F4376) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              Icon(icon, size: 16, color: selected ? Colors.white : iconColor),
            if (icon != null) const SizedBox(width: 4),
            Text(
              title,
              style: TextStyle(
                color: selected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final contentWidget = Column(
      children: [
        // Row 1: Title, Search Bar, Order Filters
        Padding(
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: 4,
          ),
          child: Row(
            children: [
              if (!widget.isEmbedded) ...[
                InkWell(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(
                    Icons.arrow_back,
                    size: 24,
                    color: Color(0xff222222),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              const Text(
                "KOT History",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff1E293B),
                ),
              ),
              const SizedBox(width: 30),
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: TextField(
                    onChanged: (value) {
                      searchText = value;
                      applyFilters();
                    },
                    decoration: InputDecoration(
                      hintText: "Search Order ID or KOT ID...",
                      prefixIcon: const Icon(Icons.search, size: 20),
                      filled: true,
                      fillColor: const Color(0xfff8fafc),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 30),
              _filterButtonGroup(),
            ],
          ),
        ),

        const SizedBox(height: 2),

        // Row 2: Metrics and Secondary Filters
        Padding(
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 2,
            bottom: 4,
          ),
          child: Row(
            children: [
              // Date Picker
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setState(() {
                      selectedDate = picked;
                      _dateController.text = DateFormat(
                        'dd/MM/yy',
                      ).format(picked);
                    });
                    await loadOrders();
                  }
                },
                child: Container(
                  width: 150,
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        _dateController.text.isEmpty ? "Select Date" : _dateController.text,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff1e293b),
                        ),
                      ),
                      const Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Duration Dropdown
              Container(
                width: 110,
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedDuration,
                    hint: const Text(
                      "Duration",
                      style: TextStyle(fontSize: 13),
                    ),
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                        value: '30 Min',
                        child: Text('30 Min', style: TextStyle(fontSize: 13)),
                      ),
                      DropdownMenuItem(
                        value: '60 Min',
                        child: Text('60 Min', style: TextStyle(fontSize: 13)),
                      ),
                      DropdownMenuItem(
                        value: '5 Hours',
                        child: Text('5 Hours', style: TextStyle(fontSize: 13)),
                      ),
                      DropdownMenuItem(
                        value: '24 Hours',
                        child: Text('24 Hours', style: TextStyle(fontSize: 13)),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedDuration = value;
                        applyFilters();
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Status Dropdown
              Container(
                width: 110,
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedStatus,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                        value: 'All Status',
                        child: Text(
                          'All Status',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'Completed',
                        child: Text(
                          'Completed',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'Cancelled',
                        child: Text(
                          'Cancelled',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        selectedStatus = value;
                        currentPage = 1;
                      });
                      applyFilters();
                    },
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Refresh Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff3B82F6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: loadOrders,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text(
                  "Refresh",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),

              const Spacer(),

              // Stats
              _summaryCard(
                title: "Total KOT's",
                value: "$totalKotsCount",
                color: const Color(0xff1E40AF),
                bgColor: const Color(0xffEFF6FF),
                borderColor: const Color(0xffBFDBFE),
                icon: Icons.list_alt,
              ),
              const SizedBox(width: 12),
              _summaryCard(
                title: "Completed",
                value: "$completedKotsCount",
                color: const Color(0xff15803D),
                bgColor: const Color(0xffF0FDF4),
                borderColor: const Color(0xffBBF7D0),
                icon: Icons.check_circle,
              ),
              const SizedBox(width: 12),
              _summaryCard(
                title: "Cancelled",
                value: "$cancelledKotsCount",
                color: const Color(0xffB91C1C),
                bgColor: const Color(0xffFEF2F2),
                borderColor: const Color(0xffFCA5A5),
                icon: Icons.cancel,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),

        Expanded(
          child: Container(
            width: double.infinity,
            margin: EdgeInsets.zero,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xffE5E7EB)),
            ),
            child:
                isLoading
                    ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xff2F4376),
                      ),
                    )
                    : LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: constraints.maxWidth,
                            ),
                            child: DataTable(
                              headingRowHeight: 40,
                              dataRowMinHeight: 40,
                              dataRowMaxHeight: 40,
                              showCheckboxColumn: false,
                              horizontalMargin: 16,
                              columnSpacing: 46, // Fixed spacing
                              headingRowColor: WidgetStateProperty.all(
                                const Color(0xff173F7A),
                              ),
                              border: TableBorder(
                                horizontalInside: BorderSide(
                                  color: Colors.grey.shade200,
                                ),
                              ),
                              columns: const [
                                DataColumn(
                                  label: Text(
                                    "Order ID",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    "KOT No.",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    "  Type",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    "Table No.",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    "Received Time",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    "Prep. Time",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    " Status",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    "Actions",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                              rows:
                                  paginatedOrders.map((order) {
                                    return DataRow(
                                      cells: [
                                        // Order ID
                                        DataCell(
                                          Text(
                                            //"#${order.orderId}",
                                            "${order.orderId}",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xff444444),
                                            ),
                                          ),
                                        ),

                                        // KOT No.
                                        DataCell(
                                          Text(
                                            order.kotNumber.isEmpty
                                                ? "-"
                                                : order.kotNumber,
                                            style: const TextStyle(
                                              color: Color(0xff3B82F6),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),

                                        // Type
                                        DataCell(
                                          buildOrderTypeBadge(order.orderType),
                                        ),

                                        // Table No.
                                        DataCell(
                                          Text(
                                            order.tableName.isEmpty
                                                ? "-"
                                                : order.tableName,
                                          ),
                                        ),

                                        // Ord. Received
                                        DataCell(
                                          Text(
                                            order.finishedTime.isEmpty
                                                ? "-"
                                                : order.finishedTime,
                                          ),
                                        ),

                                        // Prep Time
                                        DataCell(
                                          Text(
                                            order.prepTime.isEmpty
                                                ? "-"
                                                : order.prepTime,
                                          ),
                                        ),

                                        // Status
                                        DataCell(
                                          buildStatusBadge(order.status),
                                        ),

                                        // Action
                                        DataCell(
                                          order.canRecall
                                              ? InkWell(
                                                onTap: () async {
                                                  final api = OrderApiService(
                                                    getToken:
                                                        () async =>
                                                            widget.token,
                                                    restaurantId:
                                                        widget.restaurantId,
                                                  );

                                                  await api.updateKotOrderStatus(
                                                    orderId: order.kotOrderId,
                                                    parentId: order.orderId,
                                                    zoneId:
                                                        order
                                                            .zoneId, // <-- must exist
                                                    restaurantId:
                                                        order.restaurantId,
                                                    status: "preparing",
                                                  );
                                                  debugPrint(
                                                    "Restaurant ID: ${order.restaurantId}",
                                                  );
                                                  debugPrint(
                                                    "Zone ID: ${order.zoneId}",
                                                  );
                                                  debugPrint(
                                                    "Order ID: ${order.orderId}",
                                                  );
                                                  // Refresh KDS orders
                                                  await context
                                                      .read<OrderProvider>()
                                                      .loadExistingOrders();

                                                  // if (!mounted) return;

                                                  if (!mounted) return;

                                                  if (widget.isEmbedded) {
                                                    widget.onRecallSuccess
                                                        ?.call();
                                                  } else {
                                                    Navigator.pushReplacement(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder:
                                                            (
                                                              _,
                                                            ) => ActiveOrdersScreen(
                                                              token:
                                                                  widget.token,
                                                              restaurantId:
                                                                  widget
                                                                      .restaurantId,
                                                            ),
                                                      ),
                                                    );
                                                  }
                                                },
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 8,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: const Color(
                                                      0xff2563EB,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: const [
                                                      Icon(
                                                        Icons.refresh,
                                                        size: 14,
                                                        color: Colors.white,
                                                      ),
                                                      SizedBox(width: 6),
                                                      Text(
                                                        "Recall/Alter",
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              )
                                              : const Center(
                                                child: Text(
                                                  "-",
                                                  style: TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ),
        const SizedBox(height: 2),

        Padding(
          padding: const EdgeInsets.only(right: 12, bottom: 4, top: 2),
          child: Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap:
                      currentPage > 1
                          ? () {
                            setState(() {
                              currentPage--;
                              applyPagination();
                            });
                          }
                          : null,
                  child: paginationButton("Previous", currentPage > 1),
                ),

                ...List.generate(totalPages, (index) {
                  final page = index + 1;

                  return InkWell(
                    onTap: () {
                      setState(() {
                        currentPage = page;
                        applyPagination();
                      });
                    },
                    child: pageButton(page.toString(), currentPage == page),
                  );
                }),

                InkWell(
                  onTap:
                      currentPage < totalPages
                          ? () {
                            setState(() {
                              currentPage++;
                              applyPagination();
                            });
                          }
                          : null,
                  child: paginationButton("Next", currentPage < totalPages),
                ),
              ],
            ),
          ),
        ),
      ],
    );
    if (widget.isEmbedded) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xffe2e8f0)),
        ),
        child: contentWidget,
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xffF4F4F4),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.zero,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: contentWidget,
          ),
        ),
      ),
    );
  }

  Widget pageButton(String text, bool selected) {
    return Container(
      width: 26,
      height: 26,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? const Color(0xff173F7A) : Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: selected ? const Color(0xff173F7A) : const Color(0xffE5E7EB),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: selected ? Colors.white : const Color(0xff1E293B),
        ),
      ),
    );
  }

  Widget paginationButton(String text, bool enabled) {
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xffE5E7EB)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: enabled ? const Color(0xff1E293B) : Colors.grey.shade400,
        ),
      ),
    );
  }

  Widget buildStatusBadge(String status) {
    final isCompleted = status.toLowerCase() == "completed";

    final Color bgColor =
        isCompleted ? const Color(0xffD1FAE5) : const Color(0xffFEE2E2);

    final Color textColor =
        isCompleted ? const Color(0xff065F46) : const Color(0xff991B1B);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCompleted ? Icons.check_circle : Icons.cancel,
            color: textColor,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            isCompleted ? "Completed" : "Cancelled",
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildOrderTypeBadge(String type) {
    final isDineIn = type.toLowerCase().contains('dine');
    final isTakeaway = type.toLowerCase().contains('take');
    final isOnline = type.toLowerCase().contains('online');

    final Color bgColor;
    final Color textColor;
    final String displayText;

    if (isDineIn) {
      bgColor = const Color(0xffFFE4D8);
      textColor = const Color(0xffF26B3A);
      displayText = "Dine-In";
    } else if (isTakeaway) {
      bgColor = const Color(0xffD9E9FF);
      textColor = const Color(0xff3B73B9);
      displayText = "Takeaways";
    } else if (isOnline) {
      bgColor = const Color(0xffD1FAE5);
      textColor = const Color(0xff065F46);
      displayText = "Online Orders";
    } else {
      bgColor = const Color(0xffF3F4F6);
      textColor = const Color(0xff374151);
      displayText = type;
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: 110,
        height: 22,
        alignment: Alignment.center,
        padding: EdgeInsets.zero,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          displayText,
          style: TextStyle(
            color: textColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

Widget _summaryCard({
  required String title,
  required String value,
  required Color color,
  required Color bgColor,
  required Color borderColor,
  required IconData icon,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: borderColor, width: 1),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "$title : ",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(width: 10),
        Icon(icon, color: color, size: 18),
      ],
    ),
  );
}
