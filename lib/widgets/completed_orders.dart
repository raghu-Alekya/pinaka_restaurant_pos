import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/complete_order_model.dart';
import '../services/completeorder_api service.dart';


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

  Future<void> loadOrders() async {
    try {
      allOrders = await getCompletedOrders(
        token: widget.token,
      );

      filteredOrders = List.from(allOrders);
    } catch (e) {
      debugPrint(e.toString());
    }

    setState(() {
      isLoading = false;
    });
  }
  void applyFilters() {
    setState(() {
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
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F4F4),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 16,
            ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            children: [

              Container(
                height: 60,
                color: const Color(0xFFE3EDFF),
                padding:
                const EdgeInsets.symmetric(horizontal: 20),
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
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xffE5E5E5)),
                  ),
                  child: SingleChildScrollView(
                    child: DataTable(
                      columnSpacing: 70,
                      headingRowHeight: 60,
                      dataRowHeight: 65,
                      headingRowColor: WidgetStateProperty.all(
                        const Color(0xffF5F5FA),
                      ),
                      columns: const [
                        DataColumn(label: Text("Order ID")),
                        DataColumn(label: Text("Type")),
                        DataColumn(label: Text("Table")),
                        DataColumn(label: Text("Finished Time")),
                        DataColumn(label: Text("Prep Time")),
                        DataColumn(label: Text("Recall")),
                      ],
                      rows: filteredOrders.map((order) {
                        return DataRow(
                          cells: [
                            DataCell(Text('#${order.orderId}')),

                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: order.orderType == 'Dine In'
                                      ? Colors.indigo
                                      : Colors.orange,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  order.orderType,
                                  style: const TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),

                            DataCell(Text(order.tableName)),

                            DataCell(
                              Text(
                                order.finishedTime.isEmpty
                                    ? '-'
                                    : order.finishedTime,
                              ),
                            ),

                            DataCell(
                              Text(
                                order.prepTime.isEmpty
                                    ? '-'
                                    : order.prepTime,
                              ),
                            ),

                            DataCell(
                              order.canRecall
                                  ? TextButton.icon(
                                onPressed: () {
                                  // Recall API
                                },
                                icon: const Icon(Icons.refresh),
                                label: const Text('Recall'),
                              )
                                  : const Text('-'),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    ));
  }
}