import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pinaka_restaurant_pos/App%20flow/ui/payment_screen.dart';
import 'package:pinaka_restaurant_pos/App%20flow/ui/view_order_details_screen.dart';
import 'package:pinaka_restaurant_pos/repositories/order_list_repository.dart';

import '../../blocs/Bloc Event/order_event.dart';
import '../../blocs/Bloc Event/order_list_event.dart';
// import '../../blocs/Bloc Logic/orders_list_bloc.dart';
// import '../../blocs/Bloc State/orders_list_state.dart';
import '../../blocs/Bloc Logic/discount_bloc.dart';
import '../../blocs/Bloc Logic/order_bloc.dart';
import '../../blocs/Bloc Logic/order_list_bloc.dart';
import '../../blocs/Bloc Logic/payment_bloc.dart';
import '../../blocs/Bloc State/order_list_state.dart';
import '../../constants/constants.dart';
import '../../models/UserPermissions.dart';
// import '../../models/orderslist/orders_list_model.dart';
import '../../models/order/guest_details.dart';
import '../../models/order/order_model.dart';
import '../../models/order_list/order_list_model.dart';
import '../../repositories/order_repository.dart';
import '../../services/api_exception.dart';
import '../../utils/SessionManager.dart';
import '../../utils/logger.dart';
import '../widgets/NavigationHelper.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/top_bar.dart';
import '../widgets/vieworderscreen.dart';
import 'home_screen.dart';

class OrdersListTable extends StatefulWidget {
  final String token;
  final String pin;
  final String restaurantId;
  final String restaurantName;
  final UserPermissions? userPermissions;
  final List<Map<String, dynamic>> loadedTables;
  final String? initialOrderType;

  const OrdersListTable({
    super.key,
    required this.token,
    required List orders,
    required this.pin,
    required this.restaurantId,
    required this.restaurantName,
    this.userPermissions,
    required this.loadedTables,
    this.initialOrderType,
  });

  @override
  State<OrdersListTable> createState() => _OrdersListTableState();
}

class _OrdersListTableState extends State<OrdersListTable> {
  UserPermissions? _userPermissions;
  int _selectedIndex = 4;
  String? _selectedStatus;
  String? _selectedOrderType;
  String? _selectedDate;
  bool _isRefreshing = false;
  Timer? _searchDebounce;
  String _currency = "₹";
  final List<String> statusOptions = [
    'All',
    'Completed',
    'Processing',
    'cancelled',
  ];
  final List<String> orderTypeOptions = [
    'All Types',
    'Dine In',
    'Takeaway',
    'Online Orders',
  ];
  DateTime? selectedDate;

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

  int _currentPage = 0;
  final int _rowsPerPage = 10;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  String _searchQuery = "";
  List<OrderlistModel> _allOrders = [];
  List<OrderlistModel> _filteredOrders = [];

  @override
  void initState() {
    super.initState();
    _userPermissions = widget.userPermissions;
    _selectedOrderType = widget.initialOrderType ?? 'All Types';
    _loadPermissions();
    _loadCurrency();
    final today = DateTime.now();
    selectedDate = today;
    final todayStr = DateFormat('yyyy-MM-dd').format(today);
    _dateController.text = DateFormat('dd/MM/yyyy').format(today);
    context.read<OrderstatusBloc>().add(
      FetchOrders(
        token: widget.token,
        date: todayStr,
        restaurantId: widget.restaurantId,
      ),
    );
    _selectedStatus = 'All';
    _searchController.addListener(() {
      _searchDebounce?.cancel();
      _searchDebounce = Timer(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _searchQuery = _searchController.text.toLowerCase();
            _currentPage = 0;
            _updateFilteredOrders();
          });
        }
      });
    });
  }
  Future<void> _refreshOrders() async {
    if (_isRefreshing) return;

    final refreshDate = selectedDate ?? DateTime.now();

    final dateStr = DateFormat(
      'yyyy-MM-dd',
    ).format(refreshDate);

    setState(() {
      _isRefreshing = true;
      _currentPage = 0;
    });

    context.read<OrderstatusBloc>().add(
      FetchOrders(
        token: widget.token,
        date: dateStr,
        restaurantId: widget.restaurantId,
        forceRefresh: true,
      ),
    );
  }
  Future<void> _loadCurrency() async {
    final currency = await SessionManager.getCurrencySymbol();

    if (mounted) {
      setState(() {
        _currency = currency ?? "₹";
      });
    }
  }

  Future<void> _loadPermissions() async {
    final savedPermissions = await SessionManager.loadPermissions();
    if (savedPermissions != null) {
      setState(() {
        _userPermissions = savedPermissions;
      });
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
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

  DateTime? _parseOrderDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    final parsed = DateTime.tryParse(dateStr);
    if (parsed != null) return parsed.toLocal();
    try {
      return DateFormat("yyyy-MM-dd HH:mm:ss").parse(dateStr).toLocal();
    } catch (_) {}
    try {
      return DateFormat("yyyy-MM-dd'T'HH:mm:ss").parse(dateStr).toLocal();
    } catch (_) {}
    try {
      return DateFormat("yyyy-MM-dd").parse(dateStr).toLocal();
    } catch (_) {}
    try {
      return DateFormat("d MMMM, yyyy").parse(dateStr).toLocal();
    } catch (_) {}
    try {
      return DateFormat("d MMM, yyyy").parse(dateStr).toLocal();
    } catch (_) {}
    try {
      return DateFormat("dd/MM/yyyy").parse(dateStr).toLocal();
    } catch (_) {}
    return null;
  }

  List<OrderlistModel> _filterOrders(List<OrderlistModel> orders) {
    final query = _searchQuery.toLowerCase();

    return orders.where((order) {
      final matchesSearch =
          query.isEmpty ||
              (order.orderId?.toString().toLowerCase() ?? '').contains(query) ||
              (order.orderType?.toLowerCase() ?? '').contains(query) ||
              (order.zoneName?.toLowerCase() ?? '').contains(query) ||
              (order.tableName?.toLowerCase() ?? '').contains(query) ||
              (order.customerPhone?.toLowerCase() ?? '').contains(query) ||
              (order.customerName?.toLowerCase() ?? '').contains(query);

      bool matchesStatus = true;
      if (_selectedStatus != null && _selectedStatus != 'All') {
        matchesStatus =
            (order.status?.toLowerCase() ?? '') ==
                _selectedStatus!.toLowerCase();
      }

      bool matchesOrderType = true;
      if (_selectedOrderType != null && _selectedOrderType != 'All Types') {
        final typeLower = (order.orderType ?? '').toLowerCase();
        final selLower = _selectedOrderType!.toLowerCase();
        if (selLower.contains('online')) {
          matchesOrderType = typeLower.contains('online') ||
              typeLower.contains('delivery') ||
              typeLower.contains('doordash') ||
              typeLower.contains('ubereats') ||
              typeLower.contains('grubhub') ||
              typeLower.contains('wc') ||
              typeLower.contains('synced') ||
              typeLower.contains('shop') ||
              typeLower.contains('processing') ||
              typeLower.contains('pending') ||
              typeLower.isEmpty ||
              ((order.tableId == null || order.tableId == 0) &&
                  !typeLower.contains('takeaway'));
        } else if (selLower.contains('takeaway')) {
          matchesOrderType = typeLower.contains('takeaway');
        } else if (selLower.contains('dine')) {
          matchesOrderType = typeLower.contains('dine') ||
              (order.tableId != null && order.tableId! > 0);
        } else {
          matchesOrderType = typeLower.contains(selLower);
        }
      }

      bool matchesDate = true;
      if (selectedDate != null) {
        final orderDate = _parseOrderDate(order.date);
        if (orderDate != null) {
          matchesDate =
              orderDate.year == selectedDate!.year &&
                  orderDate.month == selectedDate!.month &&
                  orderDate.day == selectedDate!.day;
        }
      }

      return matchesSearch && matchesStatus && matchesOrderType && matchesDate;
    }).toList();
  }

  void _updateFilteredOrders() {
    _filteredOrders = _filterOrders(_allOrders);

    if (_currentPage * _rowsPerPage >= _filteredOrders.length) {
      _currentPage = 0;
    }
  }

  bool _isResetEnabled() {
    return _searchQuery.isNotEmpty ||
        (_selectedStatus != null && _selectedStatus != 'All') ||
        (_selectedOrderType != null && _selectedOrderType != 'All Types') ||
        selectedDate != null;
  }

  List<OrderlistModel> _currentPageOrders(List<OrderlistModel> filtered) {
    final startIndex = _currentPage * _rowsPerPage;
    final endIndex = (_currentPage + 1) * _rowsPerPage;
    return filtered.sublist(
      startIndex,
      endIndex > filtered.length ? filtered.length : endIndex,
    );
  }

  void _nextPage(int totalFiltered) {
    if ((_currentPage + 1) * _rowsPerPage < totalFiltered) {
      setState(() => _currentPage++);
    }
  }

  void _previousPage() {
    if (_currentPage > 0) setState(() => _currentPage--);
  }

  List<int> _visiblePages(int totalPages) {
    const int maxVisible = 4;

    int startPage = _currentPage - (_currentPage % maxVisible);

    if (startPage + maxVisible > totalPages) {
      startPage = totalPages - maxVisible;
    }

    if (startPage < 0) startPage = 0;

    final visibleCount =
    (totalPages - startPage) >= maxVisible
        ? maxVisible
        : totalPages - startPage;

    return List.generate(visibleCount, (i) => startPage + i);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _dateController.dispose();
    super.dispose();
  }
  int _getOrderModificationCount(OrderlistModel order) {
    int count = 0;

    for (final kot in order.kotOrders ?? []) {
      // Each unique voidedAt/modification timestamp represents
      // one modification revision.
      final modificationTimes = <String>{};

      for (final item in kot.voidedItems ?? []) {
        final time = item.voidedAt?.toIso8601String();

        if (time != null && time.isNotEmpty) {
          modificationTimes.add(time);
        }
      }

      count += modificationTimes.length;
    }

    return count;
  }
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
      isDark ? const Color(0xFF161A26) : const Color(0xFFF6F6F6),
      appBar: TopBar(
        token: widget.token,
        pin: widget.pin,
        restaurantId: widget.restaurantId,
        restaurantName: widget.restaurantName,
        userPermissions: _userPermissions,
        isHomeScreen: false,
        onPermissionsReceived: (permissions) {
          setState(() {
            _userPermissions = permissions;
          });
        },
      ),
      body: Column(
        children: [
          // InkWell(
          //   onTap: () {
          //     Navigator.pushReplacement(
          //       context,
          //       MaterialPageRoute(
          //         builder: (_) => HomeScreen(
          //           pin: widget.pin,
          //           token: widget.token,
          //           restaurantId: widget.restaurantId,
          //           restaurantName: widget.restaurantName,
          //         ),
          //       ),
          //     );
          //   },
          //   child: Container(
          //     width: 40,
          //     height: 40,
          //     decoration: BoxDecoration(
          //       color: Colors.white,
          //       borderRadius: BorderRadius.circular(8),
          //       boxShadow: const [
          //         BoxShadow(
          //           color: Colors.black12,
          //           blurRadius: 4,
          //         ),
          //       ],
          //     ),
          //     child: const Icon(
          //       Icons.arrow_back,
          //       color: Color(0xFF0A1B4D),
          //     ),
          //   ),
          // ),
          const SizedBox(height: 4),

          // MAIN CONTENT (BlocBuilder)
          Expanded(
            child: BlocConsumer<OrderstatusBloc, OrderstatusState>(
              buildWhen: (previous, current) {
                return current is OrderLoading ||
                    current is OrderLoaded ||
                    current is OrderError;
              },

              listener: (context, state) {
                if (state is OrderLoaded || state is OrderError) {
                  if (mounted) {
                    setState(() {
                      _isRefreshing = false;
                    });
                  }
                }
              },

              builder: (context, state) {
                if (state is OrderLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is OrderLoaded) {
                  final orders = state.orders;

                  if (_allOrders != orders) {
                    _allOrders = orders;
                    _updateFilteredOrders();
                    OrderstatusRepository().primeCache(
                      orders,
                    ); // ADDED: warms Details/Edit cache instantly
                  }

                  final pageOrders = _currentPageOrders(_filteredOrders);

                  final totalPages =
                  _filteredOrders.isEmpty
                      ? 1
                      : ((_filteredOrders.length - 1) ~/ _rowsPerPage) + 1;

                  final int totalOrders = _allOrders.length;
                  final int displayedOrders = _filteredOrders.length;

                  /// 🔹 TABLE + PAGINATION CONTAINER
                  return Container(
                    margin: const EdgeInsets.all(10),
                    padding: const EdgeInsets.all(8),
                    // decoration: BoxDecoration(
                    //   color: Colors.white,
                    //   borderRadius: BorderRadius.circular(12),
                    //   border: Border.all(color: const Color(0xFFF1F1F3), width: 1),
                    // ),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF202433) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow:
                      isDark
                          ? []
                          : const [
                        BoxShadow(
                          color: Color(0x3F474747),
                          blurRadius: 10,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        /// HEADER + SEARCH
                        Row(
                          children: [
                            const SizedBox(width: 8),

                            Text(
                              "Orders List",
                              style: TextStyle(
                                color:
                                isDark
                                    ? Colors.white
                                    : const Color(0xFF3D3D3D),
                                fontSize: 24,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            const Spacer(),

                            /// SEARCH
                            Container(
                              height: 40,
                              width: 360,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              decoration: ShapeDecoration(
                                color:
                                isDark
                                    ? const Color(0xFF2B3042)
                                    : Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                shadows: const [
                                  BoxShadow(
                                    color: Color(0x4204347F),
                                    blurRadius: 5,
                                    offset: Offset(0, 0),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.search,
                                    size: 18,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: TextField(
                                      controller: _searchController,
                                      textAlignVertical:
                                      TextAlignVertical.center,
                                      decoration: const InputDecoration(
                                        hintText:
                                        'Search order ID, Order Type, Zone, Table, or Cust name, phone....',
                                        border: InputBorder.none,
                                        isDense: true,
                                        contentPadding: EdgeInsets.only(
                                          bottom:
                                          6, // moves text slightly upward
                                        ),
                                        hintStyle: TextStyle(
                                          color: Color(0xFFB0B0B0),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 12),

                            /// DATE DROPDOWN
                            SizedBox(
                              width: 180,
                              height: 40,
                              child: Container(
                                decoration: BoxDecoration(
                                  color:
                                  isDark
                                      ? const Color(0xFF12171E)
                                      : Colors.white,
                                  border: Border.all(
                                    color:
                                    isDark
                                        ? const Color(0xFF374151)
                                        : Colors.grey.shade300,
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow:
                                  isDark
                                      ? [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(
                                        0.35,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                      : const [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: TextField(
                                  controller: _dateController,
                                  readOnly: true,
                                  textAlignVertical: TextAlignVertical.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color:
                                    isDark
                                        ? Colors.white
                                        : const Color(0xFF111827),
                                  ),
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate:
                                      selectedDate ?? DateTime.now(),
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2030),
                                      builder: (context, child) {
                                        return Theme(
                                          data: Theme.of(context).copyWith(
                                            colorScheme:
                                            isDark
                                                ? const ColorScheme.dark(
                                              primary: Color(
                                                0xFFFFFFFF,
                                              ),
                                              onPrimary: Colors.black,
                                              surface: Color(
                                                0xFF1F2937,
                                              ),
                                              onSurface: Colors.white,
                                            )
                                                : Theme.of(
                                              context,
                                            ).colorScheme,
                                            dialogTheme: DialogThemeData(
                                              backgroundColor:
                                              isDark
                                                  ? const Color(0xFF1F2937)
                                                  : Colors.white,
                                            ),
                                          ),
                                          child: child!,
                                        );
                                      },
                                    );
                                    if (picked != null) {
                                      setState(() {
                                        selectedDate = picked;
                                        _dateController.text =
                                        "${picked.day.toString().padLeft(2, '0')}/"
                                            "${picked.month.toString().padLeft(2, '0')}/"
                                            "${picked.year}";
                                        _currentPage = 0;
                                      });

                                      final dateStr = DateFormat(
                                        'yyyy-MM-dd',
                                      ).format(picked);

                                      context.read<OrderstatusBloc>().add(
                                        FetchOrders(
                                          token: widget.token,
                                          date: dateStr,
                                          restaurantId: widget.restaurantId,
                                        ),
                                      );
                                    }
                                  },
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    suffixIcon: Icon(
                                      Icons.calendar_today,
                                      size: 18,
                                      color:
                                      isDark
                                          ? Colors.white70
                                          : const Color(0xFF6B7280),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 12),

                            //  Order Type dropdown
                            Container(
                              height: 40,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color:
                                isDark
                                    ? const Color(0xFF34384F)
                                    : const Color(0xFF4C81F1),
                                border: Border.all(
                                  color:
                                  isDark
                                      ? Colors.white24
                                      : const Color(0xFF4C81F1),
                                ),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedOrderType,
                                  dropdownColor:
                                  isDark
                                      ? const Color(0xFF34384F)
                                      : const Color(0xFF4C81F1),
                                  iconEnabledColor: Colors.white,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                  items:
                                  orderTypeOptions
                                      .map(
                                        (e) => DropdownMenuItem<String>(
                                      value: e,
                                      child: Text(
                                        e,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  )
                                      .toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      _selectedOrderType = val;
                                      _currentPage = 0;
                                      _updateFilteredOrders();
                                    });
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            //  status dropdown
                            Container(
                              height: 40,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color:
                                isDark
                                    ? const Color(0xFF34384F)
                                    : const Color(0xFF4C81F1),
                                border: Border.all(
                                  color:
                                  isDark
                                      ? Colors.white24
                                      : const Color(0xFF4C81F1),
                                ),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedStatus,
                                  dropdownColor:
                                  isDark
                                      ? const Color(0xFF34384F)
                                      : const Color(0xFF4C81F1),
                                  iconEnabledColor: Colors.white,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                  items:
                                  statusOptions
                                      .map(
                                        (e) => DropdownMenuItem<String>(
                                      value: e,
                                      child: Text(
                                        e,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  )
                                      .toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      _selectedStatus = val;
                                      _currentPage = 0;
                                      _updateFilteredOrders();
                                    });
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // =========================
                                // RESET BUTTON
                                // =========================
                                SizedBox(
                                  height: 40,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                      _isResetEnabled()
                                          ? (isDark
                                          ? const Color(0xFF34384F)
                                          : const Color(0xFFFDF8F8))
                                          : (isDark
                                          ? const Color(0xFF2B3042)
                                          : Colors.grey.shade300),
                                      foregroundColor:
                                      _isResetEnabled()
                                          ? Colors.red
                                          : (isDark
                                          ? Colors.white54
                                          : Colors.grey),
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        side: BorderSide(
                                          color:
                                          _isResetEnabled()
                                              ? Colors.red
                                              : (isDark
                                              ? Colors.white24
                                              : Colors.grey.shade400),
                                        ),
                                      ),
                                    ),
                                    onPressed: _isResetEnabled()
                                        ? () {
                                      final today = DateTime.now();

                                      setState(() {
                                        // Search
                                        _searchQuery = '';
                                        _searchController.clear();

                                        // Status
                                        _selectedStatus = 'All';

                                        // Order Type
                                        _selectedOrderType = 'All Types';

                                        // Date → RESET TO TODAY
                                        selectedDate = today;
                                        _dateController.text =
                                            DateFormat('dd/MM/yyyy').format(today);

                                        // Pagination
                                        _currentPage = 0;
                                      });

                                      // Fetch today's orders
                                      final dateStr =
                                      DateFormat('yyyy-MM-dd').format(today);

                                      context.read<OrderstatusBloc>().add(
                                        FetchOrders(
                                          token: widget.token,
                                          date: dateStr,
                                          restaurantId: widget.restaurantId,
                                        ),
                                      );
                                    }
                                        : null,
                                    icon: Icon(
                                      Icons.refresh,
                                      size: 16,
                                      color:
                                      _isResetEnabled()
                                          ? Colors.red
                                          : (isDark
                                          ? Colors.white54
                                          : Colors.grey),
                                    ),
                                    label: Text(
                                      "Reset",
                                      style: TextStyle(
                                        color:
                                        _isResetEnabled()
                                            ? Colors.red
                                            : (isDark
                                            ? Colors.white54
                                            : Colors.grey),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 8),

                                // =========================
                                // REFRESH BUTTON
                                // =========================
                                SizedBox(
                                  height: 40,
                                  width: 42,
                                  child: ElevatedButton(
                                    onPressed: _isRefreshing ? null : _refreshOrders,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isDark
                                          ? const Color(0xFF34384F)
                                          : Colors.white,
                                      foregroundColor: const Color(0xFF1E2A5A),
                                      elevation: 0,
                                      padding: EdgeInsets.zero,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        side: BorderSide(
                                          color: isDark
                                              ? Colors.white24
                                              : const Color(0xFF1E2A5A),
                                        ),
                                      ),
                                    ),
                                    child: Center(
                                      child: _isRefreshing
                                          ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Color(0xFF1E2A5A),
                                        ),
                                      )
                                          : const Icon(
                                        Icons.sync,
                                        size: 24,
                                        color: Color(0xFF1E2A5A),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // TABLE
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color:
                              isDark
                                  ? const Color(0xFF202433)
                                  : const Color(0xFFF2F2F2),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(8),
                                topRight: Radius.circular(8),
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Theme(
                              data: Theme.of(
                                context,
                              ).copyWith(dividerColor: Colors.grey.shade200),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: SizedBox(
                                  width:
                                  MediaQuery.of(context).size.width * 0.99,
                                  child: DataTable(
                                    showCheckboxColumn: false,
                                    headingTextStyle: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      height: 1.10,
                                    ),
                                    headingRowHeight: 45,
                                    dataRowHeight: 45,
                                    headingRowColor: MaterialStateProperty.all(
                                      isDark
                                          ? const Color(0xFF34384F)
                                          : const Color(0xFF2A3558),
                                    ),
                                    dataRowColor: MaterialStateProperty.all(
                                      isDark
                                          ? const Color(0xFF202433)
                                          : const Color(0xFFFCFCFF),
                                    ),
                                    columnSpacing: 30,
                                    dividerThickness: 0,
                                    columns: const [
                                      DataColumn(label: Text("Order ID")),
                                      DataColumn(label: Text("Order Type")),
                                      DataColumn(label: Text("Date")),
                                      DataColumn(label: Text("Zone")),
                                      DataColumn(label: Text("Table")),
                                      DataColumn(label: Text("Payment")),
                                      DataColumn(label: Text("Total")),
                                      DataColumn(label: Text("Status")),
                                      DataColumn(
                                        label: Text("Actions"),
                                      ), // New column
                                    ],
                                    rows:
                                    pageOrders.map((order) {
                                      // Check if this specific row is a Takeaway or Online order
                                      final bool isTakeAwayType =
                                          [
                                            "takeaway",
                                            "online",
                                            "takeaways",
                                          ].contains(
                                            (order.orderType ?? "")
                                                .toLowerCase(),
                                          ) ||
                                              (order.tableId == null ||
                                                  order.tableId == 0);
                                      return DataRow(
                                        cells: [
                                          DataCell(
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  order.orderId?.toString() ?? '-',
                                                  style: TextStyle(
                                                    color: isDark ? Colors.white : Colors.black,
                                                  ),
                                                ),

                                                const SizedBox(width: 4),

                                                if (_getOrderModificationCount(order) > 0)
                                                // Text(
                                                //   '✏️ ${_getOrderModificationCount(order)}×',
                                                //   style: const TextStyle(
                                                //     color: Color(0xFFB45309),
                                                //     fontSize: 10,
                                                //     fontFamily: 'Inter',
                                                //     fontWeight: FontWeight.w600,
                                                //     height: 1.38,
                                                //   ),
                                                // ),
                                                  Container(
                                                    width: 40,
                                                    height: 20,
                                                    decoration: ShapeDecoration(
                                                      color: const Color(0xFFFEF3C7),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                    ),
                                                    alignment: Alignment.center,
                                                    child: Text(
                                                      '✏️ ${_getOrderModificationCount(order)}×',
                                                      style: const TextStyle(
                                                        color: Color(0xFFB45309),
                                                        fontSize: 10,
                                                        fontFamily: 'Inter',
                                                        fontWeight: FontWeight.w600,
                                                        height: 1.38,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              (order.orderType != null &&
                                                  order.orderType!.trim().isNotEmpty &&
                                                  order.orderType != '-')
                                                  ? order.orderType!
                                                  : (isTakeAwayType ? 'Online Order' : 'Dine In'),
                                              style: TextStyle(
                                                color:
                                                isDark
                                                    ? Colors.white
                                                    : Colors.black,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              order.date ?? '-',
                                              style: TextStyle(
                                                color:
                                                isDark
                                                    ? Colors.white
                                                    : Colors.black,
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              isTakeAwayType
                                                  ? 'N/A'
                                                  : (order.zoneName ?? '-'),
                                              style: TextStyle(
                                                color:
                                                isDark
                                                    ? Colors.white
                                                    : Colors.black,
                                              ),
                                            ),
                                          ),
                                          // 2. Table Cell (Displays 'N/A' if it is a takeaway order)
                                          DataCell(
                                            Text(
                                              isTakeAwayType
                                                  ? 'N/A'
                                                  : (order.tableName ??
                                                  '-'),
                                              style: TextStyle(
                                                color:
                                                isDark
                                                    ? Colors.white
                                                    : Colors.black,
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              order.paymentType ?? '-',
                                              style: TextStyle(
                                                color:
                                                isDark
                                                    ? Colors.white
                                                    : Colors.black,
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              "$_currency${order.displayTotal.toStringAsFixed(2)}",
                                              style: TextStyle(
                                                color:
                                                isDark
                                                    ? Colors.white
                                                    : Colors.black,
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Container(
                                              padding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: _statusColor(
                                                  order.status ?? '',
                                                ).withOpacity(
                                                  isDark ? 0.25 : 0.1,
                                                ),
                                                borderRadius:
                                                BorderRadius.circular(
                                                  12,
                                                ),
                                              ),
                                              child: Text(
                                                order.status?.isNotEmpty ==
                                                    true
                                                    ? order.status!
                                                    : '-',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight:
                                                  FontWeight.w500,
                                                  color: _statusColor(
                                                    order.status ?? '',
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Builder(
                                              builder: (context) {
                                                final String statusLower =
                                                (order.status ?? "")
                                                    .toLowerCase();
                                                final bool hasKot =
                                                    (order.kotOrders != null &&
                                                        order.kotOrders!.isNotEmpty) ||
                                                        (order.kotOrderId != null &&
                                                            order.kotOrderId! > 0);
                                                final bool isPayDisabled =
                                                    statusLower ==
                                                        "completed" ||
                                                        statusLower ==
                                                            "cancelled" ||
                                                        order.displayTotal <= 0 ||
                                                        !hasKot;

                                                return Row(
                                                  mainAxisSize:
                                                  MainAxisSize.min,
                                                  children: [
                                                    // 1. VIEW BUTTON (Enabled by default)
                                                    SizedBox(
                                                      width: 65,
                                                      height: 30,
                                                      child: ElevatedButton(
                                                        onPressed: () async {
                                                          await Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                              builder:
                                                                  (_) => OrdersDetailsScreen(
                                                                token: widget.token,
                                                                pin: widget.pin,
                                                                restaurantId: widget.restaurantId,
                                                                restaurantName: widget.restaurantName,
                                                                userPermissions: _userPermissions,
                                                                orderId: order.orderId ?? 0,
                                                                initialOrder: order,
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                          const Color(
                                                            0xFF4C81F1,
                                                          ),
                                                          foregroundColor:
                                                          Colors.white,
                                                          elevation: 0,
                                                          padding:
                                                          EdgeInsets.zero,
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                          ),
                                                        ),
                                                        child: const Text(
                                                          "View",
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            fontWeight:
                                                            FontWeight
                                                                .w600,
                                                            color:
                                                            Colors
                                                                .white,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 6),

                                                    // 2. PAY BUTTON (Disabled when status is completed or cancelled)
                                                    SizedBox(
                                                      width: 65,
                                                      height: 30,
                                                      child: ElevatedButton(
                                                        onPressed: isPayDisabled
                                                            ? null
                                                            : () async {
                                                          try {
                                                            // Show loading overlay
                                                            showDialog(
                                                              context:
                                                              context,
                                                              barrierDismissible:
                                                              false,
                                                              builder:
                                                                  (
                                                                  _,
                                                                  ) => const Center(
                                                                child:
                                                                CircularProgressIndicator(),
                                                              ),
                                                            );

                                                            final repository =
                                                            OrderRepository(
                                                              baseUrl:
                                                              AppConstants
                                                                  .baseDomain,
                                                            );

                                                            OrderModel?
                                                            orderModel;

                                                            if (isTakeAwayType) {
                                                              final url =
                                                              Uri.parse(
                                                                '${AppConstants.baseDomain}/wp-json/pinaka-restaurant-pos/v1/orders/${order.orderId}',
                                                              );

                                                              final body = {
                                                                "flag_type":
                                                                "get_order_details",
                                                                "order_id":
                                                                order
                                                                    .orderId ??
                                                                    0,
                                                                "restaurant_id":
                                                                int.parse(
                                                                  widget
                                                                      .restaurantId,
                                                                ),
                                                              };

                                                              final response = await ApiExceptionHandler.post(
                                                                url,
                                                                headers: {
                                                                  'Content-Type':
                                                                  'application/json',
                                                                  'Authorization':
                                                                  widget.token.startsWith(
                                                                    "Bearer ",
                                                                  )
                                                                      ? widget.token
                                                                      : "Bearer ${widget.token}",
                                                                },
                                                                body: jsonEncode(
                                                                  body,
                                                                ),
                                                              );

                                                              if (response.statusCode ==
                                                                  200 ||
                                                                  response.statusCode ==
                                                                      201) {
                                                                final data =
                                                                jsonDecode(
                                                                  response
                                                                      .body,
                                                                );
                                                                orderModel =
                                                                    OrderModel.fromJson(
                                                                      data,
                                                                    );
                                                              } else {
                                                                orderModel = OrderModel(
                                                                  orderId:
                                                                  order
                                                                      .orderId ??
                                                                      0,
                                                                  tableId:
                                                                  0,
                                                                  tableName:
                                                                  "",
                                                                  zoneId:
                                                                  0,
                                                                  zoneName:
                                                                  "",
                                                                  status:
                                                                  order
                                                                      .status ??
                                                                      "",
                                                                  items:
                                                                  const [],
                                                                  kotOrders:
                                                                  const [],
                                                                  orderDateTime:
                                                                  DateTime.tryParse(
                                                                    order.date ??
                                                                        "",
                                                                  ),
                                                                );
                                                              }
                                                            } else {
                                                              orderModel = await repository.getOrderByTable(
                                                                restaurantId:
                                                                int.parse(
                                                                  widget
                                                                      .restaurantId,
                                                                ),
                                                                tableId:
                                                                order
                                                                    .tableId ??
                                                                    0,
                                                                zoneId:
                                                                order
                                                                    .zoneId ??
                                                                    0,
                                                                token:
                                                                widget
                                                                    .token,
                                                              );
                                                            }

                                                            if (Navigator.canPop(
                                                              context,
                                                            ))
                                                              Navigator.pop(
                                                                context,
                                                              );

                                                            if (orderModel ==
                                                                null) {
                                                              ScaffoldMessenger.of(
                                                                context,
                                                              ).showSnackBar(
                                                                const SnackBar(
                                                                  content: Text(
                                                                    "Unable to load order context.",
                                                                  ),
                                                                  backgroundColor:
                                                                  Colors
                                                                      .red,
                                                                ),
                                                              );
                                                              return;
                                                            }

                                                            context.read<OrderBloc>().add(
                                                              LoadExistingOrder(
                                                                orderId:
                                                                orderModel
                                                                    .orderId,
                                                                tableId:
                                                                orderModel
                                                                    .tableId,
                                                                zoneId:
                                                                orderModel
                                                                    .zoneId,
                                                                tableName:
                                                                orderModel
                                                                    .tableName,
                                                                zoneName:
                                                                orderModel
                                                                    .zoneName,
                                                                restaurantId:
                                                                widget
                                                                    .restaurantId,
                                                                guestDetails: Guestcount(
                                                                  guestCount:
                                                                  orderModel
                                                                      .guestCount,
                                                                ),
                                                                kotList:
                                                                orderModel
                                                                    .kotOrders,
                                                                orderItems:
                                                                orderModel
                                                                    .items,
                                                              ),
                                                            );

                                                            AppLogger.info(
                                                              "Pay clicked - ${isTakeAwayType ? 'Takeaway/Online' : 'Dine In'}",
                                                            );

                                                            Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                builder:
                                                                    (
                                                                    _,
                                                                    ) => MultiBlocProvider(
                                                                  providers: [
                                                                    BlocProvider.value(
                                                                      value:
                                                                      context
                                                                          .read<
                                                                          OrderBloc
                                                                      >(),
                                                                    ),
                                                                    BlocProvider.value(
                                                                      value:
                                                                      context
                                                                          .read<
                                                                          PaymentBloc
                                                                      >(),
                                                                    ),
                                                                    BlocProvider.value(
                                                                      value:
                                                                      context
                                                                          .read<
                                                                          RemoveDiscountBloc
                                                                      >(),
                                                                    ),
                                                                  ],
                                                                  child: PaymentScreen(
                                                                    loadedTables:
                                                                    widget.loadedTables,
                                                                    pin:
                                                                    widget.pin,
                                                                    token:
                                                                    widget.token,
                                                                    restaurantId:
                                                                    widget.restaurantId,
                                                                    restaurantName:
                                                                    widget.restaurantName,
                                                                    zoneId:
                                                                    isTakeAwayType
                                                                        ? 0
                                                                        : orderModel?.zoneId,
                                                                    isTakeAway:
                                                                    isTakeAwayType,
                                                                  ),
                                                                ),
                                                              ),
                                                            );
                                                          } catch (e) {
                                                            if (Navigator.canPop(
                                                              context,
                                                            ))
                                                              Navigator.pop(
                                                                context,
                                                              );
                                                            debugPrint(
                                                              "Error loading order context layer: $e",
                                                            );

                                                            ScaffoldMessenger.of(
                                                              context,
                                                            ).showSnackBar(
                                                              SnackBar(
                                                                content: Text(
                                                                  "Failed to load order: $e",
                                                                ),
                                                                backgroundColor:
                                                                Colors
                                                                    .red,
                                                              ),
                                                            );
                                                          }
                                                        },
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                          const Color(
                                                            0xFF06A629,
                                                          ),
                                                          disabledBackgroundColor:
                                                          isDark
                                                              ? Colors
                                                              .white12
                                                              : Colors
                                                              .grey
                                                              .shade300,
                                                          foregroundColor:
                                                          Colors.white,
                                                          disabledForegroundColor:
                                                          Colors
                                                              .grey
                                                              .shade500,
                                                          elevation: 0,
                                                          padding:
                                                          EdgeInsets.zero,
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                          ),
                                                        ),
                                                        child: Text(
                                                          "Pay",
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            fontWeight:
                                                            FontWeight
                                                                .w600,
                                                            color:
                                                            isPayDisabled
                                                                ? Colors
                                                                .grey
                                                                .shade500
                                                                : Colors
                                                                .white,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                      width: 4,
                                                    ),

                                                    // 3. PRINT BUTTON
                                                    IconButton(
                                                      icon: Icon(
                                                        Icons
                                                            .print_outlined,
                                                        color:
                                                        (order.status ??
                                                            "")
                                                            .toLowerCase() ==
                                                            "cancelled"
                                                            ? Colors
                                                            .grey
                                                            : const Color(
                                                          0xFF4C81F1,
                                                        ),
                                                      ),
                                                      tooltip: "Print",
                                                      onPressed:
                                                      (order.status ??
                                                          "")
                                                          .toLowerCase() ==
                                                          "cancelled"
                                                          ? null
                                                          : () {
                                                        // Print logic
                                                      },
                                                    ),
                                                  ],
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // const SizedBox(height: 12),

                        /// PAGINATION
                        Container(
                          height: 45,
                          decoration: BoxDecoration(
                            color:
                            isDark
                                ? const Color(0xFF202433)
                                : const Color(0xFFF2F2F2),
                            border: Border(
                              top: BorderSide(
                                color:
                                isDark
                                    ? Colors.white24
                                    : const Color(0xFFF2F2F2),
                              ),
                            ),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(10),
                              bottomRight: Radius.circular(10),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                displayedOrders == totalOrders
                                    ? "Total Orders: $totalOrders"
                                    : "Showing $displayedOrders of $totalOrders Orders",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),

                              Container(
                                decoration: BoxDecoration(
                                  color:
                                  isDark
                                      ? const Color(0xFF2B3042)
                                      : Colors.white,
                                  border: Border.all(
                                    color:
                                    isDark
                                        ? Colors.white24
                                        : const Color(0xFFF2F2F2),
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    GestureDetector(
                                      onTap:
                                      _currentPage > 0
                                          ? _previousPage
                                          : null,
                                      child: _paginationButton(
                                        text: "Previous",
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(3),
                                          bottomLeft: Radius.circular(3),
                                        ),
                                      ),
                                    ),

                                    Row(
                                      children:
                                      _visiblePages(totalPages).map((
                                          index,
                                          ) {
                                        final isActive =
                                            index == _currentPage;

                                        return GestureDetector(
                                          onTap:
                                              () => setState(
                                                () => _currentPage = index,
                                          ),
                                          child: Container(
                                            width: 30,
                                            height: 29,
                                            decoration: BoxDecoration(
                                              color:
                                              isActive
                                                  ? const Color(
                                                0xFFFF4D20,
                                              )
                                                  : (isDark
                                                  ? const Color(
                                                0xFF34384F,
                                              )
                                                  : Colors.white),
                                              border: Border(
                                                right: BorderSide(
                                                  color:
                                                  isDark
                                                      ? Colors.white24
                                                      : const Color(
                                                    0xFFEFEFEF,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              "${index + 1}",
                                              style: TextStyle(
                                                color:
                                                isActive
                                                    ? Colors.white
                                                    : (isDark
                                                    ? Colors.white70
                                                    : const Color(
                                                  0xFF727272,
                                                )),
                                                fontSize: 11,
                                                fontWeight:
                                                isActive
                                                    ? FontWeight.w600
                                                    : FontWeight.w400,
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),

                                    GestureDetector(
                                      onTap:
                                      (_currentPage + 1) < totalPages
                                          ? () => _nextPage(
                                        _filteredOrders.length,
                                      )
                                          : null,
                                      child: _paginationButton(
                                        text: "Next",
                                        borderRadius: const BorderRadius.only(
                                          topRight: Radius.circular(3),
                                          bottomRight: Radius.circular(3),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                } else if (state is OrderError) {
                  return Center(child: Text('Error: ${state.message}'));
                }

                return const Center(child: Text('No data'));
              },
            ),
          ),
        ],
      ),

      // BOTTOM NAV BAR
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

  Widget _paginationButton({
    required String text,
    required BorderRadius borderRadius,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 65,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF34384F) : Colors.white,
        borderRadius: borderRadius,
        border: Border.all(
          color: isDark ? Colors.white24 : const Color(0xFFEFEFEF),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isDark ? Colors.white70 : const Color(0xFF727272),
          fontSize: 11,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  Widget _pageButton(int page, {bool selected = false}) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFFF4D20) : Colors.white,
        border: Border.all(color: const Color(0xFFEFEFEF)),
      ),
      child: Text(
        '$page',
        style: TextStyle(
          color: selected ? Colors.white : const Color(0xFF727272),
          fontSize: 11,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }
}
