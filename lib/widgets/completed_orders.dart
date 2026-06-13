import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/complete_order_model.dart';
import '../providers/order_provider.dart';
import '../services/completeorder_api service.dart';
import '../top_bar.dart';


class CompletedOrdersScreen extends StatefulWidget {
  final String token;

  const CompletedOrdersScreen({
    super.key,
    required this.token,
  });

  @override
  State<CompletedOrdersScreen> createState() =>
      _CompletedOrdersScreenState();
}
class _CompletedOrdersScreenState
    extends State<CompletedOrdersScreen> {
  List<CompletedOrderModel> allOrders = [];
  List<CompletedOrderModel> filteredOrders = [];

  String selectedOrderType = 'All';
  String searchText = '';
  String? selectedDuration;
  int currentPage = 1;
  int rowsPerPage = 10;

  List<CompletedOrderModel> paginatedOrders = [];

  List<CompletedOrderModel> orders = [];
  bool isLoading = true;
  // ADD THESE
  DateTime? selectedDate;
  final TextEditingController _dateController =
  TextEditingController();

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
    final start = (currentPage - 1) * rowsPerPage;

    final end = start + rowsPerPage > filteredOrders.length
        ? filteredOrders.length
        : start + rowsPerPage;

    paginatedOrders = filteredOrders.sublist(start, end);
  }

  Future<void> loadOrders() async {
    try {
      allOrders = await getCompletedOrders(
        token: widget.token,
      );

      filteredOrders = List.from(allOrders);

      applyPagination();
    } catch (e) {
      debugPrint(e.toString());
    }

    setState(() {
      isLoading = false;
    });
  }
  void applyFilters() {
    filteredOrders = allOrders.where((order) {
      // Search Filter
      final matchSearch =
          searchText.isEmpty ||
              order.orderId.toString().contains(searchText);

      // Order Type Filter
      final matchType =
          selectedOrderType == 'All' ||
              order.orderType == selectedOrderType;

      // Date Filter
      bool matchDate = true;

      if (selectedDate != null &&
          order.finishedDateTime != null) {
        final orderDate = order.finishedDateTime!;

        matchDate =
            orderDate.year == selectedDate!.year &&
                orderDate.month == selectedDate!.month &&
                orderDate.day == selectedDate!.day;
      }

      // Duration Filter
      bool matchDuration = true;

      if (selectedDuration != null &&
          order.finishedDateTime != null) {
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
          matchDate &&
          matchDuration;
    }).toList();

    // Reset to first page when filter changes
    currentPage = 1;

    // Apply pagination
    applyPagination();

    setState(() {});
  }


  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
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
          child: Column(
            children: [
              TopBarWidget(orderProvider: orderProvider,),

              const SizedBox(height: 16),

              Container(
                height: 60,
                color: const Color(0xFFE3EDFF),
                padding:
                const EdgeInsets.symmetric(horizontal: 10),
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    SizedBox(width: 10),
                    Text(
                      "Completed Orders",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [

                    // Today
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
                              applyFilters();
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

                    const SizedBox(width: 15),

                    // Last 60 Min
                    Container(
                      width: 150,
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedDuration,
                          hint: const Text("Last 60 Min"),
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(
                              value: '30 Min',
                              child: Text('30 Min'),
                            ),
                            DropdownMenuItem(
                              value: '60 Min',
                              child: Text('60 Min'),
                            ),
                            DropdownMenuItem(
                              value: '5 Hours',
                              child: Text('5 Hours'),
                            ),
                            DropdownMenuItem(
                              value: '24 Hours',
                              child: Text('24 Hours'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedDuration = value;
                              applyFilters();
                            });

                            // Apply your filter here
                          },
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Search Order ID
                    SizedBox(
                      width: 250,
                      height: 50,
                      child: TextField(
                        onChanged: (value) {
                          searchText = value;
                          applyFilters();
                        },
                        decoration: InputDecoration(
                          hintText: "Search Order ID",
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Colors.grey.shade300,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 15),

                    // Order Type
                    SizedBox(
                      width: 180,
                      height: 50,
                      child: DropdownButtonFormField<String>(
                        value: selectedOrderType,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'All',
                            child: Text('All'),
                          ),
                          DropdownMenuItem(
                            value: 'Dine In',
                            child: Text('Dine In'),
                          ),
                          DropdownMenuItem(
                            value: 'Takeaway',
                            child: Text('Takeaway'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedOrderType = value!;
                          });
                          applyFilters();
                        },
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Container(
                  width: double.infinity,
                  margin: EdgeInsets.zero,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: const Color(0xffE5E7EB),
                    ),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minWidth: constraints.maxWidth,
                          ),
                          child: DataTable(
                            headingRowHeight: 55,
                            dataRowHeight: 70,
                            showCheckboxColumn: false,
                            horizontalMargin: 16,
                            columnSpacing: 40, // Fixed spacing
                            headingRowColor: MaterialStateProperty.all(
                              const Color(0xffF4F5F7),
                            ),
                            border: TableBorder(
                              horizontalInside: BorderSide(
                                color: Colors.grey.shade200,
                              ),
                            ),
                            columns: const [
                              DataColumn(
                                label: Text(
                                  "Status",
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  "KOT No.",
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  "Order ID",
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  "Type",
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  "Table No.",
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  "Prep Time",
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  "Reason",
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  "Action",
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                            rows: paginatedOrders.map((order) {
                              return DataRow(
                                cells: [
                                  DataCell(buildStatusBadge(order.status)),

                                  DataCell(
                                    Text(
                                      order.kotNumber.isEmpty
                                          ? "-"
                                          : order.kotNumber,
                                    ),
                                  ),

                                  DataCell(
                                    Text("#${order.orderId}"),
                                  ),

                                  DataCell(
                                    buildOrderTypeBadge(order.orderType),
                                  ),

                                  DataCell(
                                    Text(order.tableName),
                                  ),

                                  DataCell(
                                    Text(
                                      order.prepTime.isEmpty
                                          ? "-"
                                          : order.prepTime,
                                    ),
                                  ),

                                  const DataCell(
                                    Text("-"),
                                  ),

                                  DataCell(
                                    order.canRecall
                                        ? const Text(
                                      "Recall",
                                      style: TextStyle(
                                        color: Color(0xff6A8DFF),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    )
                                        : const Text("-"),
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
              Padding(
                padding: EdgeInsets.zero,

                child: Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      paginationButton("Previous"),
                      pageButton("1", true),
                      pageButton("2", false),
                      pageButton("3", false),
                      pageButton("4", false),
                      pageButton("5", false),
                      paginationButton("Next"),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    ));
  }
  Widget pageButton(
      String text,
      bool selected,
      ) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: selected
            ? Colors.deepOrange
            : Colors.white,
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color:
          selected ? Colors.white : Colors.black,
        ),
      ),
    );
  }

  Widget paginationButton(String text) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
      ),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

  Widget buildStatusBadge(String status) {
    final isCompleted = status.toLowerCase() == "completed";

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: isCompleted
            ? const Color(0xFFDFF5E3)
            : const Color(0xFFFDE2E2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: isCompleted
              ? const Color(0xFF28A745)
              : const Color(0xFFE74C3C),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget buildOrderTypeBadge(String type) {
    final isDineIn = type.toLowerCase() == "dine in";

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: isDineIn
            ? const Color(0xFFF28C52)
            : const Color(0xFF295C89),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        type,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}