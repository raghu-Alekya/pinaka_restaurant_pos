import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../active_orderscreen.dart';
import '../kitchen_display_screen.dart';
import '../models/complete_order_model.dart';
import '../providers/order_provider.dart';
import '../services/api_services.dart';
import '../services/completeorder_api service.dart';
import '../top_bar.dart';
import 'kds_drawer.dart';
import 'login_screen.dart';

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
  final GlobalKey<ScaffoldState> _scaffoldKey =
  GlobalKey<ScaffoldState>();

  String selectedOrderType = 'All';
  String searchText = '';
  String? selectedDuration;
  int currentPage = 1;
  int rowsPerPage = 8;
  String selectedStatus = 'All Status';

  List<CompletedOrderModel> paginatedOrders = [];

  List<CompletedOrderModel> orders = [];
  bool isLoading = true;
  final Set<int> _recallingKotIds = {};
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
    final selType = selectedOrderType.toLowerCase();
    final ordType = order.orderType.toLowerCase();
    if (selType == 'all') {
      matchType = true;
    } else if (selType.contains('dine')) {
      matchType = ordType.contains('dine');
    } else if (selType.contains('take')) {
      matchType = ordType.contains('take');
    } else if (selType.contains('online')) {
      matchType = ordType.contains('online');
    } else {
      matchType = ordType.contains(selType);
    }

    // Date Filter
    bool matchDate = true;
    if (selectedDate != null) {
      if (order.kotDateTime != null) {
        final orderDate = order.kotDateTime!;
        matchDate =
            orderDate.year == selectedDate!.year &&
            orderDate.month == selectedDate!.month &&
            orderDate.day == selectedDate!.day;
      } else {
        matchDate = false;
      }
    }

    // Duration Filter (filters by actual prep time of the order)
    bool matchDuration = true;
    if (selectedDuration != null && order.prepTime.isNotEmpty) {
      final prepMinutes = _parsePrepTimeToMinutes(order.prepTime);
      if (prepMinutes != null) {
        switch (selectedDuration) {
          case '30 Min':
            matchDuration = prepMinutes <= 30;
            break;
          case '60 Min':
            matchDuration = prepMinutes <= 60;
            break;
          case '5 Hours':
            matchDuration = prepMinutes <= 300;
            break;
          case '24 Hours':
            matchDuration = prepMinutes <= 1440;
            break;
        }
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

    final fromDateParam =
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
            );
    final toDateParam =
        selectedDate != null
            ? DateTime(
              selectedDate!.year,
              selectedDate!.month,
              selectedDate!.day,
            ).add(const Duration(days: 1))
            : DateTime.now();

    debugPrint("--- CompletedOrdersScreen: loadOrders ---");
    debugPrint("Selected Date Filter: $selectedDate");
    debugPrint("Querying API from_date: $fromDateParam, to_date: $toDateParam");

    try {
      final fetched = await getCompletedOrders(
        token: widget.token,
        restaurantId: widget.restaurantId,
        page: 1,
        perPage: 1000,
        fromDate: fromDateParam,
        toDate: toDateParam,
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
    debugPrint("--- CompletedOrdersScreen: applyFilters ---");
    debugPrint("Total orders fetched from API: ${allOrders.length}");

    filteredOrders =
        allOrders.where((order) {
          // Search Filter
          final matchSearch =
              searchText.isEmpty ||
              order.orderId.toString().contains(searchText) ||
              order.kotNumber.toLowerCase().contains(searchText.toLowerCase());

          // Order Type Filter
          bool matchType = false;
          final selType = selectedOrderType.toLowerCase();
          final ordType = order.orderType.toLowerCase();
          if (selType == 'all') {
            matchType = true;
          } else if (selType.contains('dine')) {
            matchType = ordType.contains('dine');
          } else if (selType.contains('take')) {
            matchType = ordType.contains('take');
          } else if (selType.contains('online')) {
            matchType = ordType.contains('online');
          } else {
            matchType = ordType.contains(selType);
          }

          // Status Filter
          bool matchStatus = true;
          if (selectedStatus != 'All Status') {
            matchStatus =
                order.status.toLowerCase() == selectedStatus.toLowerCase();
          }

          // Date Filter
          bool matchDate = true;
          if (selectedDate != null) {
            if (order.kotDateTime != null) {
              final orderDate = order.kotDateTime!;
              matchDate =
                  orderDate.year == selectedDate!.year &&
                  orderDate.month == selectedDate!.month &&
                  orderDate.day == selectedDate!.day;
            } else {
              matchDate = false;
            }
          }

          // Duration Filter (filters by actual prep time of the order)
          bool matchDuration = true;
          if (selectedDuration != null && order.prepTime.isNotEmpty) {
            final prepMinutes = _parsePrepTimeToMinutes(order.prepTime);
            if (prepMinutes != null) {
              switch (selectedDuration) {
                case '30 Min':
                  matchDuration = prepMinutes <= 30;
                  break;
                case '60 Min':
                  matchDuration = prepMinutes <= 60;
                  break;
                case '5 Hours':
                  matchDuration = prepMinutes <= 300;
                  break;
                case '24 Hours':
                  matchDuration = prepMinutes <= 1440;
                  break;
              }
            }
          }

          return matchSearch &&
              matchType &&
              matchStatus &&
              matchDate &&
              matchDuration;
        }).toList();

    debugPrint("Orders after applying filters: ${filteredOrders.length}");
    for (var o in filteredOrders) {
      debugPrint(
        " - KOT #${o.kotNumber} | Received Time (parsed kotDateTime): ${o.kotDateTime} (Original string: ${o.kotTime})",
      );
    }

    currentPage = 1;
    applyPagination();
  }

  /// Parses a prepTime string like "90 mins", "90", "45 min" into total minutes.
  int? _parsePrepTimeToMinutes(String prepTime) {
    final match = RegExp(r'(\d+)').firstMatch(prepTime);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '');
    }
    return null;
  }

  /// Formats total minutes into a human-readable string.
  /// e.g. 45 → "45 min", 90 → "1 hr 30 min", 60 → "1 hr"
  String _formatPrepTime(String prepTime) {
    if (prepTime.isEmpty) return '-';
    final minutes = _parsePrepTimeToMinutes(prepTime);
    if (minutes == null) return prepTime;
    if (minutes < 60) return '$minutes min';
    final hrs = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) return '$hrs hr';
    return '$hrs hr $mins min';
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
              onTap: () => setFilter(OrderTypeFilter.all),
            ),
          ),
          Expanded(
            child: _filterButton(
              title: "Dine-In",
              selected: selectedFilter == OrderTypeFilter.dineIn,
              icon: Icons.restaurant,
              iconColor: Colors.orange,
              onTap: () => setFilter(OrderTypeFilter.dineIn),
            ),
          ),
          Expanded(
            child: _filterButton(
              title: "Takeaways",
              selected: selectedFilter == OrderTypeFilter.takeaway,
              icon: Icons.shopping_bag_outlined,
              iconColor: Colors.blueGrey,
              onTap: () => setFilter(OrderTypeFilter.takeaway),
            ),
          ),
          Expanded(
            child: _filterButton(
              title: "Online Orders",
              selected: selectedFilter == OrderTypeFilter.online,
              icon: Icons.delivery_dining,
              iconColor: Colors.green,
              onTap: () => setFilter(OrderTypeFilter.online),
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
    final contentWidget = Column(
      children: [
        // Row 1: Title, Search Bar, Order Filters
        Padding(
          //padding: const EdgeInsets.only(top: 2, bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: SizedBox(
            height: 52,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (!widget.isEmbedded) ...[
                  // InkWell(
                  //   onTap: () => Navigator.pop(context),
                  //   child: const Icon(
                  //     Icons.arrow_back,
                  //     size: 24,
                  //     color: Color(0xff222222),
                  //   ),
                  // ),
                  const SizedBox(width: 10),
                ],
                const Text(
                  "Recall",
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
                        _dateController.text.isEmpty
                            ? "Select Date"
                            : _dateController.text,
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
                width: 130,
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
              SizedBox(
                width: 510,
                child: Row(
                  children: [
                    Expanded(
                      child: _summaryCard(
                        title: "Total KOT's",
                        value: "$totalKotsCount",
                        color: const Color(0xff1E40AF),
                        bgColor: const Color(0xffEFF6FF),
                        borderColor: const Color(0xffBFDBFE),
                        icon: Icons.list_alt,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _summaryCard(
                        title: "Completed",
                        value: "$completedKotsCount",
                        color: const Color(0xff15803D),
                        bgColor: const Color(0xffF0FDF4),
                        borderColor: const Color(0xffBBF7D0),
                        icon: Icons.check_circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _summaryCard(
                        title: "Cancelled",
                        value: "$cancelledKotsCount",
                        color: const Color(0xffB91C1C),
                        bgColor: const Color(0xffFEF2F2),
                        borderColor: const Color(0xffFCA5A5),
                        icon: Icons.cancel,
                      ),
                    ),
                  ],
                ),
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
                    : filteredOrders.isEmpty
                    ? const Center(
                      child: Text(
                        "No KOT's fond for the sorted Date",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
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
                                            order.orderType
                                                    .toLowerCase()
                                                    .contains('take')
                                                ? "N/A"
                                                : (order.tableName.isEmpty
                                                    ? "-"
                                                    : order.tableName),
                                          ),
                                        ),

                                        // Ord. Received
                                        DataCell(
                                          Text(
                                            order.kotTime.isEmpty
                                                ? "-"
                                                : order.kotTime,
                                          ),
                                        ),

                                        // Prep Time
                                        DataCell(
                                          Text(
                                            order.status.toLowerCase() ==
                                                        'cancelled' ||
                                                    order.status
                                                            .toLowerCase() ==
                                                        'cancel'
                                                ? "N/A"
                                                : _formatPrepTime(order.prepTime),
                                          ),
                                        ),

                                        // Status
                                        DataCell(
                                          buildStatusBadge(order.status),
                                        ),

                                        // Action
                                        DataCell(
                                          order.status.toLowerCase() ==
                                                      'cancelled' ||
                                                  order.status.toLowerCase() ==
                                                      'cancel'
                                              ? Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 8,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade400,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: SizedBox(
                                                  width: 130,
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: const [
                                                      Icon(
                                                        Icons.not_interested,
                                                        size: 14,
                                                        color: Colors.white,
                                                      ),
                                                      SizedBox(width: 6),
                                                      Text(
                                                        "Couldn't Alter",
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
                                              : (order.canRecall
                                                  ? InkWell(
                                                     onTap: () async {
                                                       if (_recallingKotIds.contains(order.kotOrderId)) return;

                                                       setState(() {
                                                         _recallingKotIds.add(order.kotOrderId);
                                                       });

                                                       try {
                                                         final success = await context
                                                             .read<OrderProvider>()
                                                             .recallOrderFromHistory(
                                                               order: order,
                                                               token: widget.token,
                                                             );

                                                         if (!mounted) return;

                                                         if (success) {
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
                                                                           widget
                                                                               .token,
                                                                       restaurantId:
                                                                           widget
                                                                               .restaurantId,
                                                                     ),
                                                               ),
                                                             );
                                                           }
                                                         } else {
                                                           ScaffoldMessenger.of(context).showSnackBar(
                                                             const SnackBar(
                                                               content: Text("Failed to recall KOT order. Please try again."),
                                                             ),
                                                           );
                                                         }
                                                       } finally {
                                                         if (mounted) {
                                                           setState(() {
                                                             _recallingKotIds.remove(order.kotOrderId);
                                                           });
                                                         }
                                                       }
                                                     },
                                                     child: Container(
                                                       padding:
                                                           const EdgeInsets.symmetric(
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
                                                       child: SizedBox(
                                                         width: 130,
                                                         child: _recallingKotIds.contains(order.kotOrderId)
                                                             ? const Center(
                                                                 child: SizedBox(
                                                                   width: 14,
                                                                   height: 14,
                                                                   child: CircularProgressIndicator(
                                                                     strokeWidth: 2,
                                                                     color: Colors.white,
                                                                   ),
                                                                 ),
                                                               )
                                                             : Row(
                                                                 mainAxisAlignment:
                                                                     MainAxisAlignment
                                                                         .center,
                                                                 children: const [
                                                                   Icon(
                                                                     Icons.refresh,
                                                                     size: 14,
                                                                     color:
                                                                         Colors.white,
                                                                   ),
                                                                   SizedBox(width: 6),
                                                                   Text(
                                                                     "Recall/Alter",
                                                                     style: TextStyle(
                                                                       color:
                                                                           Colors
                                                                               .white,
                                                                       fontSize: 12,
                                                                       fontWeight:
                                                                           FontWeight
                                                                               .bold,
                                                                     ),
                                                                   ),
                                                                 ],
                                                               ),
                                                       ),
                                                     ),
                                                  )
                                                  : const Center(
                                                    child: SizedBox(
                                                      width: 130,
                                                      child: Text(
                                                        "-",
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: TextStyle(
                                                          color: Colors.grey,
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                    ),
                                                  )),
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
      key: _scaffoldKey,

      backgroundColor: const Color(0xffF4F4F4),

      drawer: KdsDrawer(
        onDashboard: () {
          Navigator.pop(context);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => KitchenDashboardScreen(
                token: widget.token,
                restaurantId: widget.restaurantId,
              ),
            ),
          );
        },

        onSelectItemCategory: () {
          Navigator.pop(context);
        },

        onStock: () {
          Navigator.pop(context);
        },

        onRecall: () {
          Navigator.pop(context);
        },

        onSettings: () {
          Navigator.pop(context);
          widget.onRecallSuccess?.call();
        },

        // ========================================================
        // LOGOUT
        // ========================================================

        onLogout: () async {
          Navigator.pop(context);

          final prefs = await SharedPreferences.getInstance();

          final storeBaseUrl =
              prefs.getString('store_base_url') ?? '';

          final storeName =
              prefs.getString('store_name') ?? '';

          final storeId =
              prefs.getString('store_id') ?? '';

          // Remove only login/session information
          await prefs.remove('token');
          await prefs.remove('auth_token');
          await prefs.remove('user_id');
          await prefs.remove('employee_name');
          await prefs.remove('display_name');
          await prefs.remove('role');

          if (!context.mounted) return;

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => EmployeeLoginScreen(
                storeBaseUrl: storeBaseUrl,
                storeName: storeName,
                storeId: storeId,

                onLoginSuccess: (config) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => KitchenDashboardScreen(
                        token: config.apiToken,
                        restaurantId:
                        int.tryParse(config.restaurantId) ?? 0,
                      ),
                    ),
                        (route) => false,
                  );
                },
              ),
            ),
                (route) => false,
          );
        },
      ),

      body: SafeArea(
        child: Column(
          children: [

            // ==================================================
            // YOUR EXISTING COMMON TOP BAR
            // ==================================================

            TopBarWidget(
              token: widget.token,
              restaurantId: widget.restaurantId,
              selectedView: KotView.history,

              onViewChanged: (view) {
                if (view == KotView.history) {
                  return;
                }

                Navigator.pop(context);
              },

              onLogout: widget.onRecallSuccess,

              pendingCount: 0,
              activeCount: 0,
              repeatedCount: 0,

              // =================================================
              // HAMBURGER CLICK
              // =================================================

              onMenuTap: () {
                _scaffoldKey.currentState?.openDrawer();
              },
            ),

            // ==================================================
            // EXISTING RECALL CONTENT
            // ==================================================

            Expanded(
              child: Padding(
                padding: EdgeInsets.zero,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                    BorderRadius.circular(15),
                  ),
                  child: contentWidget,
                ),
              ),
            ),
          ],
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
      width: 110,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
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
      mainAxisAlignment: MainAxisAlignment.center,
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
