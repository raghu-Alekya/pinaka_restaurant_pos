import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/complete_order_model.dart';
import '../providers/order_provider.dart';
import '../services/completeorder_api service.dart';
import '../top_bar.dart';

class CompletedOrdersScreen extends StatefulWidget {
  final String token;

  const CompletedOrdersScreen({super.key, required this.token});

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
    try {
      allOrders = await getCompletedOrders(token: widget.token);

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
    filteredOrders =
        allOrders.where((order) {
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
                //Raghu*** - Top bar widget removed as per new design (CR-implemented)
                // TopBarWidget(
                //   selectedFilter: selectedFilter,
                //   selectedView: selectedView,

                //   onFilterChanged: (filter) {
                //     setState(() {
                //       selectedFilter = filter;
                //     });
                //   },

                //   onViewChanged: (view) {
                //     setState(() {
                //       selectedView = view;
                //     });
                //   },
                // ),
                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// Left Side
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InkWell(
                              onTap: () => Navigator.pop(context),
                              child: const Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Icon(
                                  Icons.arrow_back,
                                  size: 24,
                                  color: Color(0xff222222),
                                ),
                              ),
                            ),

                            const SizedBox(width: 10),

                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  "KOT's History",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xff222222),
                                  ),
                                ),

                                SizedBox(height: 4),

                                Text(
                                  "View Completed & Cancelled KOT's",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xff6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      /// Right Side Cards
                      Row(
                        children: [
                          _summaryCard(
                            title: "Total KOT's",
                            value: "${allOrders.length}",
                            color: const Color(0xff2563EB),
                            icon: Icons.receipt_long,
                          ),

                          const SizedBox(width: 18),

                          _summaryCard(
                            title: "Completed",
                            value:
                                "${allOrders.where((e) => e.status.toLowerCase() == 'completed').length}",
                            color: const Color(0xff16A34A),
                            icon: Icons.check_circle,
                          ),

                          const SizedBox(width: 18),

                          _summaryCard(
                            title: "Cancelled",
                            value:
                                "${allOrders.where((e) => e.status.toLowerCase() == 'cancelled').length}",
                            color: const Color(0xffEF4444),
                            icon: Icons.cancel,
                          ),
                        ],
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
                        height: 40,
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
                                _dateController.text = DateFormat(
                                  'dd/MM/yy',
                                ).format(picked);
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
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
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
                        height: 40,
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
                      const SizedBox(width: 15),

                      // All Status
                      Container(
                        width: 170,
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
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
                                child: Text('All Status'),
                              ),
                              DropdownMenuItem(
                                value: 'Completed',
                                child: Text('Completed'),
                              ),
                              DropdownMenuItem(
                                value: 'Cancelled',
                                child: Text('Cancelled'),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                selectedStatus = value!;
                              });
                              applyFilters();
                            },
                          ),
                        ),
                      ),

                      const Spacer(),

                      // const Spacer(),

                      // Search Order ID
                      SizedBox(
                        width: 250,
                        height: 40,
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

                      const SizedBox(width: 10),
                      //Raghu*** - Order type dropdown box is not required as per design(CR).
                      // Order Type//
                      // SizedBox(
                      //   width: 180,
                      //   height: 40,
                      //   child: DropdownButtonFormField<String>(
                      //     value: selectedOrderType,
                      //     decoration: InputDecoration(
                      //       border: OutlineInputBorder(
                      //         borderRadius: BorderRadius.circular(8),
                      //       ),
                      //     ),
                      //     items: const [
                      //       DropdownMenuItem(value: 'All', child: Text('All')),
                      //       DropdownMenuItem(
                      //         value: 'Dine In',
                      //         child: Text('Dine In'),
                      //       ),
                      //       DropdownMenuItem(
                      //         value: 'Takeaway',
                      //         child: Text('Takeaway'),
                      //       ),
                      //     ],
                      //     onChanged: (value) {
                      //       setState(() {
                      //         selectedOrderType = value!;
                      //       });
                      //       applyFilters();
                      //     },
                      //   ),
                      // ),
                    ],
                  ),
                ),

                Expanded(
                  child: Container(
                    width: double.infinity,
                    margin: EdgeInsets.zero,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xffE5E7EB)),
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
                              headingRowHeight: 50,
                              dataRowHeight: 58,
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
                                    "Order ID",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    "KOT No.",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    "Type",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    "Table No.",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    "Ord. received",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    "Prep Time",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    "Status",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    "Action",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
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
                                            "#${order.orderId}",
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
                                              ? Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: const [
                                                  Icon(
                                                    Icons.refresh,
                                                    size: 15,
                                                    color: Color(0xff3B82F6),
                                                  ),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    "Recall/Alter",
                                                    style: TextStyle(
                                                      color: Color(0xff3B82F6),
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              )
                                              : const Text(
                                                "-",
                                                style: TextStyle(
                                                  color: Colors.grey,
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
                const SizedBox(height: 10),

                Padding(
                  padding: const EdgeInsets.only(right: 10, bottom: 10, top: 5),
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
                            child: pageButton(
                              page.toString(),
                              currentPage == page,
                            ),
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
                          child: paginationButton(
                            "Next",
                            currentPage < totalPages,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget pageButton(String text, bool selected) {
    return Container(
      width: 24,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? const Color(0xffFF5722) : Colors.white,
        border: Border.all(color: const Color(0xffD9D9D9)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: selected ? Colors.white : const Color(0xff666666),
        ),
      ),
    );
  }

  Widget paginationButton(String text, bool enabled) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xffD9D9D9)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: enabled ? const Color(0xff666666) : Colors.grey.shade400,
        ),
      ),
    );
  }

  Widget buildStatusBadge(String status) {
    final isCompleted = status.toLowerCase() == "completed";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isCompleted ? const Color(0xFFDFF5E3) : const Color(0xFFFDE2E2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color:
              isCompleted ? const Color(0xFF28A745) : const Color(0xFFE74C3C),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget buildOrderTypeBadge(String type) {
    final isDineIn = type.toLowerCase() == "dine in";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isDineIn ? const Color(0xFFF28C52) : const Color(0xFF295C89),
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

Widget _summaryCard({
  required String title,
  required String value,
  required Color color,
  required IconData icon,
}) {
  return Container(
    width: 160,
    height: 62,
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withOpacity(.25)),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(.03), blurRadius: 4),
      ],
    ),
    child: Row(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: color.withOpacity(.12),
          child: Icon(icon, color: color, size: 18),
        ),

        const SizedBox(width: 8),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 14, color: Color(0xff6B7280)),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
