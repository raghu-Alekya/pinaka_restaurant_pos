import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pinaka_restaurant_pos/App%20flow/ui/view_order_details_screen.dart';

import '../../blocs/Bloc Event/order_list_event.dart';
// import '../../blocs/Bloc Logic/orders_list_bloc.dart';
// import '../../blocs/Bloc State/orders_list_state.dart';
import '../../blocs/Bloc Logic/order_list_bloc.dart';
import '../../blocs/Bloc State/order_list_state.dart';
import '../../models/UserPermissions.dart';
// import '../../models/orderslist/orders_list_model.dart';
import '../../models/order_list/order_list_model.dart';
import '../../utils/SessionManager.dart';
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

  const OrdersListTable({
    super.key,
    required this.token,
    required List orders,
    required this.pin,
    required this.restaurantId,
    required this.restaurantName,
    this.userPermissions,
  });

  @override
  State<OrdersListTable> createState() => _OrdersListTableState();
}

class _OrdersListTableState extends State<OrdersListTable> {
  UserPermissions? _userPermissions;
  int _selectedIndex = 4;
  String? _selectedStatus;
  String? _selectedDate;
  Timer? _searchDebounce;

  final List<String> statusOptions = [
    'All',
    'Completed',
    'Processing',
    'cancelled',
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
    // Trigger fetch
    _loadPermissions();
    context.read<OrderstatusBloc>().add(FetchOrders(token: widget.token));
    _selectedStatus = 'All'; // <-- Add this line

    _searchController.addListener(() {
      _searchDebounce?.cancel();

      _searchDebounce = Timer(const Duration(milliseconds: 300), () {
        setState(() {
          _searchQuery = _searchController.text.toLowerCase();
          _currentPage = 0;
          _updateFilteredOrders();
        });
      });
    });
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

  List<OrderlistModel> _filterOrders(List<OrderlistModel> orders) {
    final query = _searchQuery.toLowerCase();

    return orders.where((order) {
      final matchesSearch =
          (order.orderId?.toString().toLowerCase() ?? '').contains(query) ||
              (order.orderType?.toLowerCase() ?? '').contains(query) ||
              (order.zoneName?.toLowerCase() ?? '').contains(query) ||
              (order.tableName?.toLowerCase() ?? '').contains(query) ||
              (order.customerPhone?.toLowerCase() ?? '').contains(query);

      bool matchesStatus = true;
      if (_selectedStatus != null && _selectedStatus != 'All') {
        matchesStatus =
            (order.status?.toLowerCase() ?? '') ==
                _selectedStatus!.toLowerCase();
      }

      bool matchesDate = true;
      if (selectedDate != null) {
        final orderDate = DateTime.tryParse(order.date ?? '');
        if (orderDate == null) {
          matchesDate = false;
        } else {
          matchesDate =
              orderDate.year == selectedDate!.year &&
                  orderDate.month == selectedDate!.month &&
                  orderDate.day == selectedDate!.day;
        }
      }

      return matchesSearch && matchesStatus && matchesDate;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE4E9F9),
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
            child: BlocBuilder<OrderstatusBloc, OrderstatusState>(
              buildWhen: (previous, current) {
                return current is OrderLoading ||
                    current is OrderLoaded ||
                    current is OrderError;
              },
              builder: (context, state) {
                if (state is OrderLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is OrderLoaded) {
                  final orders = state.orders;

                  if (_allOrders != orders) {
                    _allOrders = orders;
                    _updateFilteredOrders();
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
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
                            // InkWell(
                            //   onTap: () {
                            //     Navigator.pop(context);
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
                            const SizedBox(width: 8),

                            const Text(
                              "Orders List",
                              style: TextStyle(
                                color: Color(0xFF3D3D3D),
                                fontSize: 24,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            const Spacer(),

                            /// SEARCH
                            Container(
                              height: 36,
                              width: 360,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              decoration: ShapeDecoration(
                                color: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
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
                                      decoration: const InputDecoration(
                                        hintText:
                                        'Search order ID, Order Type, Zone, Table, or Cust name, phone....',
                                        border: InputBorder.none,
                                        isDense: true,
                                        hintStyle: TextStyle(
                                          color: Color(0xFFB0B0B0),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                      // onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 12),

                            /// DATE DROPDOWN
                            SizedBox(
                              height: 36,
                              width: 150,
                              child: TextField(
                                controller: _dateController,
                                readOnly: true,
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    barrierDismissible: false,
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
                                      _currentPage = 0;
                                      _updateFilteredOrders();
                                    });
                                  }
                                },
                                decoration: InputDecoration(
                                  hintText: "Select Date",
                                  hintStyle: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                  ),
                                  suffixIcon: Icon(
                                    Icons.calendar_month_sharp,
                                    size: 18,
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade200,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                style: TextStyle(fontSize: 14),
                              ),
                            ),

                            const SizedBox(width: 12),

                            //  status dropdown
                            Container(
                              height: 36,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: const Color(0xFF4C81F1),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  dropdownColor: const Color(0xFF4C81F1),
                                  iconEnabledColor: Colors.white,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                  value: _selectedStatus,
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
                            SizedBox(
                              height: 40, // Set your desired height
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                  _isResetEnabled()
                                      ? Colors.red
                                      : Colors.grey.shade300,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 0,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed:
                                _isResetEnabled()
                                    ? () {
                                  setState(() {
                                    // 🔹 Search
                                    _searchQuery = '';
                                    _searchController.clear();

                                    // 🔹 Status
                                    _selectedStatus = 'All';

                                    // 🔹 Date
                                    selectedDate = null;
                                    _dateController.clear();

                                    // 🔹 Pagination
                                    _currentPage = 0;
                                    _updateFilteredOrders();
                                  });
                                }
                                    : null,
                                icon: const Icon(
                                  Icons.refresh,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  "Reset",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            )],
                        ),

                        const SizedBox(height: 12),

                        // TABLE
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(8),
                                topRight: Radius.circular(8),
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SizedBox(
                                width:
                                MediaQuery.of(context).size.width *
                                    0.99, // 80% of screen width
                                child: DataTable(
                                  showCheckboxColumn: false,
                                  headingTextStyle: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    height: 1.10,
                                  ),
                                  headingRowHeight: 45,
                                  dataRowHeight: 40,
                                  headingRowColor: MaterialStateProperty.all(
                                    const Color(0xFF2A3558),
                                  ),
                                  columnSpacing: 40,
                                  dividerThickness: 0,
                                  columns: const [
                                    DataColumn(label: Text("Order ID")),
                                    DataColumn(label: Text("Order Type")),
                                    DataColumn(label: Text("Date")),
                                    DataColumn(label: Text("Zone")),
                                    DataColumn(label: Text("Table")),
                                    DataColumn(label: Text("Cust. Name")),
                                    DataColumn(label: Text("Cust. Phone")),
                                    DataColumn(label: Text("Payment")),
                                    // DataColumn(label: Text("Amount")),
                                    // DataColumn(label: Text("Discount")),
                                    DataColumn(label: Text("Total")),
                                    DataColumn(label: Text("Status")),
                                  ],
                                  rows:
                                  pageOrders.map((order) {
                                    return DataRow(
                                      onSelectChanged: (_) async {
                                        // Wait for the OrdersDetailsScreen to return a value
                                        final bool?
                                        didUpdate = await Navigator.push<
                                            bool
                                        >(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (_) => OrdersDetailsScreen(
                                              token: widget.token,
                                              pin: widget.pin,
                                              restaurantId:
                                              widget.restaurantId,
                                              restaurantName:
                                              widget.restaurantName,
                                              userPermissions:
                                              _userPermissions,
                                              orderId: order.orderId!,
                                            ),
                                          ),
                                        );

                                        // If the screen returned true (order was updated), refetch
                                        if (didUpdate == true) {
                                          context
                                              .read<OrderstatusBloc>()
                                              .add(
                                            FetchOrders(
                                              token: widget.token,
                                            ),
                                          );
                                        }
                                      },
                                      cells: [
                                        DataCell(
                                          Text(
                                            order.orderId?.toString() ??
                                                '-',
                                          ),
                                        ),
                                        DataCell(
                                          Text(order.orderType ?? '-'),
                                        ),
                                        DataCell(Text(order.date ?? '-')),
                                        DataCell(
                                          Text(order.zoneName ?? '-'),
                                        ),
                                        DataCell(
                                          Text(order.tableName ?? '-'),
                                        ),
                                        DataCell(
                                          Text(
                                            order.customerName
                                                ?.trim()
                                                .isEmpty ==
                                                true
                                                ? 'Guest'
                                                : order.customerName ?? '-',
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            order.customerPhone
                                                ?.trim()
                                                .isEmpty ==
                                                true
                                                ? '-'
                                                : order.customerPhone ??
                                                '-',
                                          ),
                                        ),
                                        DataCell(
                                          Text(order.paymentType ?? '-'),
                                        ),
                                        // DataCell(Text(order.amount?.toStringAsFixed(2) ?? '0.00')),
                                        // DataCell(Text(order.discount?.toStringAsFixed(2) ?? '0.00')),
                                        DataCell(
                                          Text(
                                            "₹${order.netPayable?.toStringAsFixed(2) ?? '0.00'}",
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
                                              ).withOpacity(0.1),
                                              borderRadius:
                                              BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              order.status?.isNotEmpty ==
                                                  true
                                                  ? order.status!
                                                  : '-',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: _statusColor(
                                                  order.status ?? '',
                                                ),
                                              ),
                                            ),
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

                        const SizedBox(height: 12),

                        /// PAGINATION
                        Container(
                          height: 45,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF7F7F7),
                            border: Border(
                              top: BorderSide(
                                color: Color(0xFFE0E0E0),
                              ),
                            ),
                            borderRadius: BorderRadius.only(
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
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),

                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                    color: const Color(0xFFEFEFEF),
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    GestureDetector(
                                      onTap: _currentPage > 0 ? _previousPage : null,
                                      child: _paginationButton(
                                        text: "Previous",
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(3),
                                          bottomLeft: Radius.circular(3),
                                        ),
                                      ),
                                    ),

                                    Row(
                                      children: _visiblePages(totalPages).map((index) {
                                        final isActive = index == _currentPage;

                                        return GestureDetector(
                                          onTap: () => setState(() => _currentPage = index),
                                          child: Container(
                                            width: 30,
                                            height: 29,
                                            decoration: BoxDecoration(
                                              color: isActive
                                                  ? const Color(0xFFFF4D20)
                                                  : Colors.white,
                                              border: const Border(
                                                right: BorderSide(
                                                  color: Color(0xFFEFEFEF),
                                                ),
                                              ),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              "${index + 1}",
                                              style: TextStyle(
                                                color: isActive
                                                    ? Colors.white
                                                    : const Color(0xFF727272),
                                                fontSize: 11,
                                                fontWeight: isActive
                                                    ? FontWeight.w600
                                                    : FontWeight.w400,
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),

                                    GestureDetector(
                                      onTap: (_currentPage + 1) < totalPages
                                          ? () => _nextPage(_filteredOrders.length)
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
    return Container(
      width: 65,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: borderRadius,
        border: Border.all(
          color: const Color(0xFFEFEFEF),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF727272),
          fontSize: 11,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
  Widget _pageButton(
      int page, {
        bool selected = false,
      }) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFFF4D20) : Colors.white,
        border: Border.all(
          color: const Color(0xFFEFEFEF),
        ),
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