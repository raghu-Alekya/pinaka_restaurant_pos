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

class OrdersListTable extends StatefulWidget {
  final String token;
  final String pin;
  final String restaurantId;
  final String restaurantName;
  final UserPermissions? userPermissions;

  const OrdersListTable({super.key,required this.token,
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

  final List<String> statusOptions = ['All', 'Completed', 'Processing', 'cancelled'];
  DateTime? selectedDate;

  void _onItemTapped(int index) {
    NavigationHelper.handleNavigation(
      context,
      _selectedIndex,
      index,
      widget.pin,
      widget.token,
      widget.restaurantId,
      widget.restaurantName,
      widget.userPermissions,
    );

    setState(() {
      _selectedIndex = index;
    });
  }

  int _currentPage = 0;
  final int _rowsPerPage = 10;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  String _searchQuery = "";


  @override
  void initState() {
    super.initState();
    _userPermissions = widget.userPermissions;
    // Trigger fetch
    _loadPermissions();
    context.read<OrderstatusBloc>().add(
      FetchOrders(token: widget.token),

    );

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
        _currentPage = 0;
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
      case "pending":
        return Colors.orange;
      case "declined":
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


  bool _isResetEnabled() {
    return _searchQuery.isNotEmpty ||
        _selectedStatus != null ||
        selectedDate != null;
  }


  List<OrderlistModel> _currentPageOrders(List< OrderlistModel> filtered) {
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
    (totalPages - startPage) >= maxVisible ? maxVisible : totalPages - startPage;

    return List.generate(visibleCount, (i) => startPage + i);
  }
  @override
  void dispose() {
    _searchController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: TopBar(
        token: widget.token,
        pin: widget.pin,
        userPermissions: _userPermissions,
        onPermissionsReceived: (permissions) {
          setState(() {
            _userPermissions = permissions;
          });
        },
      ),
      body: Column(
        children: [
          const SizedBox(height: 4),

          // MAIN CONTENT (BlocBuilder)
          Expanded(
            child: BlocBuilder<OrderstatusBloc, OrderstatusState>(
              builder: (context, state) {
                if (state is OrderLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                else if (state is OrderLoaded) {
                  final orders = state.orders;

                  // ======= Debug prints =======
                  for (var order in orders) {
                    print('==============================');
                    print('Order ID        : ${order.orderId}');
                    print('Order Type      : ${order.orderType}');
                    print('Date            : ${order.date}');
                    print('Customer Name   : ${order.customerName}');
                    print('Customer Phone  : ${order.customerPhone}');
                    print('Payment Type    : ${order.paymentType}');
                    print('Amount          : ${order.amount}');
                    print('Discount        : ${order.discount}');
                    print('Total           : ${order.total}');
                    print('Status          : ${order.status}');
                    print('Is Parent       : ${order.isParent}');
                    print('Restaurant ID   : ${order.restaurantId}');
                    print('Zone ID         : ${order.zoneId}');
                    print('Zone Name       : ${order.zoneName}');
                    print('Table ID        : ${order.tableId}');
                    print('Table Name      : ${order.tableName}');
                    print('Table Status    : ${order.tableStatus}');
                    print('--- KOT ORDERS ---');

                    if (order.kotOrders != null && order.kotOrders!.isNotEmpty) {
                      for (var kot in order.kotOrders!) {
                        print('  ----------------------------');
                        print('  KOT Order ID  : ${kot.kotOrderId}');
                        print('  Status        : ${kot.status}');
                        print('  Total         : ${kot.total}');
                        print('  Created At    : ${kot.createdAt}');
                        print('  Is Parent     : ${kot.isParent}');
                        print('  --- LINE ITEMS ---');

                        if (kot.lineItems != null && kot.lineItems!.isNotEmpty) {
                          for (var item in kot.lineItems!) {
                            print('    Item ID     : ${item.itemId}');
                            print('    Name        : ${item.name}');
                            print('    Quantity    : ${item.quantity}');
                            print('    Rate        : ${item.amount}');
                            print('    Total       : ${item.total}');
                          }
                        } else {
                          print('    No line items found.');
                        }
                      }
                    } else {
                      print('No KOT Orders found.');
                    }
                  }
                  print('==================================');

                  // ===========================

                  final filtered = _filterOrders(orders);
                  final pageOrders = _currentPageOrders(filtered);
                  final totalPages = ((filtered.length - 1) ~/ _rowsPerPage) + 1;


                  /// 🔹 TABLE + PAGINATION CONTAINER
                  return Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF1F1F3), width: 1),
                    ),
                    child: Column(
                      children: [
                        /// HEADER + SEARCH
                        Row(
                          children: [
                            const Text(
                              "Orders List",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),

                            /// SEARCH
                            Container(
                              height: 36,
                              width: 360,
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFF1F1F3)),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0xFFFFFFFF),
                                    blurRadius: 4,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.search, size: 18, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: TextField(
                                      controller: _searchController,
                                      decoration: const InputDecoration(
                                        hintText: 'Search order ID, Order Type, Zone, Table, or Cust name, phone....',
                                        border: InputBorder.none,
                                        isDense: true,
                                        hintStyle: TextStyle(
                                          color: Color(0xFFB0B0B0),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                      onChanged: (_) => setState(() {}),
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
                                    initialDate: selectedDate ?? DateTime.now(),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2030),
                                  );
                                  if (picked != null) {
                                    setState(() {
                                      selectedDate = picked;
                                      _dateController.text = DateFormat('dd/MM/yy').format(picked);
                                    });
                                  }
                                },
                                decoration: InputDecoration(
                                  hintText: "Select Date",
                                  hintStyle: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                  ),
                                  suffixIcon: Icon(Icons.calendar_today, size: 18),
                                  filled: true,
                                  fillColor: Colors.grey.shade200,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10),
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
                              padding: const EdgeInsets.symmetric(horizontal: 8),
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
                                  hint: const Text(
                                    'Status',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white,               // hint color
                                    ),
                                  ),
                                  value: _selectedStatus,
                                  items: statusOptions.map(
                                        (e) => DropdownMenuItem<String>(
                                      value: e,
                                      child: Text(
                                        e,
                                        style: const TextStyle(
                                          color: Colors.white,           // item text color
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ).toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      _selectedStatus = val;
                                    });
                                  },
                                ),
                              ),
                            ),

                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isResetEnabled()
                                    ? Colors.red
                                    : Colors.grey.shade300,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: _isResetEnabled()
                                  ? () {
                                setState(() {
                                  // 🔹 Search
                                  _searchQuery = '';
                                  _searchController.clear();

                                  // 🔹 Status
                                  _selectedStatus = null;

                                  // 🔹 Date
                                  selectedDate = null;
                                  _dateController.clear();

                                  // 🔹 Pagination
                                  _currentPage = 0;
                                });
                              }
                                  : null,
                              icon: const Icon(Icons.refresh, size: 16, color: Colors.white),
                              label: const Text(
                                "Reset",
                                style: TextStyle(color: Colors.white, fontSize: 14),
                              ),
                            ),

                          ],
                        ),


                        const SizedBox(height: 12),

                        // TABLE
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width * 0.99, // 80% of screen width
                              child: DataTable(
                                showCheckboxColumn: false,
                                headingTextStyle: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  height: 1.10,
                                ),
                                headingRowHeight: 45,
                                dataRowHeight: 40,
                                headingRowColor: MaterialStateProperty.all(const Color(0xFFE7F5FD)),
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
                                rows: pageOrders.map((order) {
                                  return DataRow(
                                    onSelectChanged: (_) async {
                                      // Wait for the OrdersDetailsScreen to return a value
                                      final bool? didUpdate = await Navigator.push<bool>(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => OrdersDetailsScreen(
                                            token: widget.token,
                                            pin: widget.pin,
                                            restaurantId: widget.restaurantId,
                                            restaurantName: widget.restaurantName,
                                            userPermissions: _userPermissions,
                                            orderId: order.orderId!,
                                          ),
                                        ),
                                      );

                                      // If the screen returned true (order was updated), refetch
                                      if (didUpdate == true) {
                                        context.read<OrderstatusBloc>().add(FetchOrders(token: widget.token));
                                      }
                                    },
                                    cells: [
                                      DataCell(Text(order.orderId?.toString() ?? '-')),
                                      DataCell(Text(order.orderType ?? '-')),
                                      DataCell(Text(order.date ?? '-')),
                                      DataCell(Text(order.zoneName ?? '-')),
                                      DataCell(Text(order.tableName ?? '-')),
                                      DataCell(Text(
                                        order.customerName?.trim().isEmpty == true
                                            ? ''
                                            : order.customerName ?? '-',
                                      )),
                                      DataCell(Text(order.customerPhone ?? '-')),
                                      DataCell(Text(order.paymentType ?? '-')),
                                      // DataCell(Text(order.amount?.toStringAsFixed(2) ?? '0.00')),
                                      // DataCell(Text(order.discount?.toStringAsFixed(2) ?? '0.00')),
                                      DataCell(Text(order.netPayable?.toStringAsFixed(2) ?? '0.00')),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: _statusColor(order.status ?? '').withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            order.status?.isNotEmpty == true ? order.status! : '-',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: _statusColor(order.status ?? ''),
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

                        const SizedBox(height: 12),

                        /// PAGINATION
                        Align(
                          alignment: Alignment.centerRight,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: _previousPage,
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
                                      height: 30,
                                      margin: const EdgeInsets.symmetric(horizontal: 2),
                                      decoration: BoxDecoration(
                                        color: isActive ? Colors.red : Colors.white,
                                        border: Border.all(color: const Color(0xFFEEEEEE)),
                                      ),
                                      child: Center(
                                        child: Text(
                                          "${index + 1}",
                                          style: TextStyle(
                                            color: isActive ? Colors.white : const Color(0xFF727272),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              GestureDetector(
                                onTap: () => _nextPage(filtered.length),
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
                  );

                }
                else if (state is OrderError) {
                  return Center(child: Text('Error: ${state.message}'));
                }

                return const Center(child: Text('No data'));
              },
            ),
          ),
        ],

      ),

      /// 🔹 BOTTOM NAV BAR
      bottomNavigationBar: BottomNavBar(
        selectedIndex: 4,
        userPermissions: _userPermissions,
        onItemTapped: (int index) {
          NavigationHelper.handleNavigation(
            context,
            4,
            index,
            widget.pin,
            widget.token,
            widget.restaurantId,
            widget.restaurantName,
            _userPermissions,
          );
        },
      ),
    );
  }

  Widget _paginationButton(
      {required String text, required BorderRadius borderRadius}) {
    return Container(
      width: 65,
      height: 30,
      decoration: ShapeDecoration(
        shape: RoundedRectangleBorder(
          side: const BorderSide(width: 1, color: Color(0xFFEEEEEE)),
          borderRadius: borderRadius,
        ),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFF727272),
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}