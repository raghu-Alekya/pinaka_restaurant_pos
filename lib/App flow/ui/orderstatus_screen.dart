// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// // import 'package:orderlist/api_integration/order_bloc.dart';
// // import 'package:orderlist/api_integration/order_state.dart';
// // import 'package:orderlist/api_integration/order_event.dart';
// // import 'package:orderlist/models/order_model.dart';
// // import 'package:orderlist/orderlist/ViewOrderDialog.dart';
//
// import '../widgets/vieworderscreen.dart';
//
// class OrdersListTable extends StatefulWidget {
//   const OrdersListTable({super.key, required List orders});
//
//   @override
//   State<OrdersListTable> createState() => _OrdersListTableState();
// }
//
// class _OrdersListTableState extends State<OrdersListTable> {
//   int _currentPage = 0;
//   final int _rowsPerPage = 6;
//   final TextEditingController _searchController = TextEditingController();
//   String _searchQuery = "";
//
//   @override
//   void initState() {
//     super.initState();
//     // Trigger fetch
//     context.read<OrderBloc>().add(FetchOrders());
//
//     _searchController.addListener(() {
//       setState(() {
//         _searchQuery = _searchController.text.toLowerCase();
//         _currentPage = 0;
//       });
//     });
//   }
//
//   Color _statusColor(String status) {
//     switch (status.toLowerCase()) {
//       case "completed":
//         return Colors.green;
//         //case "pending":
//         return Colors.orange;
//       case "processing":
//         return Colors.orange;
//       case "declined":
//         return Colors.red;
//       case "yet-to-prepare":
//         return Colors.red;
//       default:
//         return Colors.grey;
//     }
//   }
//
//   List<OrderModel> _filterOrders(List<OrderModel> orders) {
//     if (_searchQuery.isEmpty) return orders;
//     return orders.where((order) {
//       return (order.customerName ?? '').toLowerCase().contains(_searchQuery) ||
//           (order.customerPhone ?? '').toLowerCase().contains(_searchQuery) ||
//           (order.orderId?.toString() ?? '').toLowerCase().contains(_searchQuery);
//     }).toList();
//   }
//
//   List<OrderModel> _currentPageOrders(List<OrderModel> filtered) {
//     final startIndex = _currentPage * _rowsPerPage;
//     final endIndex = (_currentPage + 1) * _rowsPerPage;
//     return filtered.sublist(
//       startIndex,
//       endIndex > filtered.length ? filtered.length : endIndex,
//     );
//   }
//
//   void _nextPage(int totalFiltered) {
//     if ((_currentPage + 1) * _rowsPerPage < totalFiltered) {
//       setState(() => _currentPage++);
//     }
//   }
//
//   void _previousPage() {
//     if (_currentPage > 0) setState(() => _currentPage--);
//   }
//   List<int> _visiblePages(int totalPages) {
//     const int maxVisible = 4;
//
//     int startPage = _currentPage - (_currentPage % maxVisible);
//
//     if (startPage + maxVisible > totalPages) {
//       startPage = totalPages - maxVisible;
//     }
//
//     if (startPage < 0) startPage = 0;
//
//     final visibleCount =
//     (totalPages - startPage) >= maxVisible ? maxVisible : totalPages - startPage;
//
//     return List.generate(visibleCount, (i) => startPage + i);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return BlocBuilder<OrderBloc, OrderState>(
//       builder: (context, state) {
//         if (state is OrderLoading) {
//           return const Center(child: CircularProgressIndicator());
//         } else if (state is OrderLoaded) {
//           final orders = state.orders;
//
//           // ======= Debug prints =======
//           for (var order in orders) {
//             print('==============================');
//             print('Order ID    : ${order.orderId}');
//             print('Type        : ${order.orderType}');
//             print('Date        : ${order.date}');
//             print('Customer    : ${order.customerName}');
//             print('Phone       : ${order.customerPhone}');
//             print('Amount      : ${order.amount}');
//             print('Discount    : ${order.discount}');
//             print('Total       : ${order.total}');
//             print('Status      : ${order.status}');
//             print('Is Parent   : ${order.isParent}');
//             print('--- KOT ORDERS ---');
//
//             if (order.kotOrders != null && order.kotOrders!.isNotEmpty) {
//               for (var kot in order.kotOrders!) {
//                 print('  KOT Order ID : ${kot.kotOrderId}');
//                 print('  Status       : ${kot.status}');
//                 print('  Total        : ${kot.total}');
//                 print('  Created At   : ${kot.createdAt}');
//                 print('  Is Parent    : ${kot.isParent}');
//                 print('  --- LINE ITEMS ---');
//                 if (kot.lineItems != null && kot.lineItems!.isNotEmpty) {
//                   for (var item in kot.lineItems!) {
//                     print('    Item ID   : ${item.itemId}');
//                     print('    Name      : ${item.name}');
//                     print('    Qty       : ${item.quantity}');
//                     print('    Amount    : ${item.amount}');
//                     print('    Total     : ${item.total}');
//                   }
//                 } else {
//                   print('    No line items found.');
//                 }
//               }
//             } else {
//               print('No KOT Orders found.');
//             }
//           }
//           // ===========================
//
//           final filtered = _filterOrders(orders);
//           final pageOrders = _currentPageOrders(filtered);
//           final totalPages = ((filtered.length - 1) ~/ _rowsPerPage) + 1;
//
//           return Container(
//             margin: const EdgeInsets.all(8),
//             padding: const EdgeInsets.all(8),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(color: const Color(0xFFF1F1F3), width: 1),
//             ),
//             child: Column(
//               children: [
//                 /// HEADER ROW
//                 Row(
//                   children: [
//                     const Text(
//                       "Orders List",
//                       style: TextStyle(
//                           fontSize: 18, fontWeight: FontWeight.bold),
//                     ),
//                     const Spacer(),
//
//                     // Search bar
//                     Container(
//                       height: 36,
//                       width: 250,
//                       padding: const EdgeInsets.symmetric(horizontal: 6),
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(8),
//                         border: Border.all(color: const Color(0xFFF1F1F3)),
//                         boxShadow: const [
//                           BoxShadow(
//                             color: Color(0x3F717171),
//                             blurRadius: 4,
//                             offset: Offset(0, 1),
//                             spreadRadius: 1,
//                           ),
//                         ],
//                       ),
//                       child: Row(
//                         children: [
//                           const Icon(Icons.search,
//                               size: 18, color: Colors.grey),
//                           const SizedBox(width: 6),
//                           Expanded(
//                             child: TextField(
//                               controller: _searchController,
//                               decoration: const InputDecoration(
//                                 hintText: 'Name or Order ID',
//                                 hintStyle:
//                                 TextStyle(color: Color(0xFFA19A9B)),
//                                 border: InputBorder.none,
//                                 isDense: true,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//
//                 const SizedBox(height: 12),
//
//                 /// TABLE SECTION
//                 Expanded(
//                   child: Container(
//                     decoration: BoxDecoration(
//                       color: const Color(0xFFFFFFFF),
//                       borderRadius: BorderRadius.circular(12),
//                       border: Border.all(color: const Color(0xFFF1F1F3), width: 6),
//                     ),
//                     child: Column(
//                       children: [
//                         Expanded(
//                           child: Container(
//                             margin: const EdgeInsets.all(12),
//                             padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
//                             decoration: BoxDecoration(
//                               color: Colors.white,
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             child: SingleChildScrollView(
//                               scrollDirection: Axis.horizontal,
//                               child: DataTable(
//                                 headingRowHeight: 45,
//                                 dataRowHeight: 40,
//                                 headingTextStyle: const TextStyle(
//                                   fontWeight: FontWeight.bold,
//                                   color: Colors.black,
//                                   height: 1.10,
//                                 ),
//                                 dataTextStyle: const TextStyle(
//                                   fontSize: 13,
//                                   color: Colors.black87,
//                                 ),
//                                 headingRowColor:
//                                 MaterialStateProperty.all(const Color(0xFFE7F5FD)),
//                                 columnSpacing: 30,
//                                 dividerThickness: 0,
//                                 columns: const [
//                                   DataColumn(label: Text("Order ID")),
//                                   DataColumn(label: Text("Order Type")),
//                                   DataColumn(label: Text("            Date")),
//                                   DataColumn(label: Text("Customer Name")),
//                                   DataColumn(label: Text("Customer Phone")),
//                                   DataColumn(label: Text("Payment Type")),
//                                   DataColumn(label: Text("Amount")),
//                                   DataColumn(label: Text("Discount")),
//                                   DataColumn(label: Text("Total")),
//                                   DataColumn(label: Text("Status")),
//                                   DataColumn(label: Text("Action")),
//                                 ],
//                                 rows: List.generate(pageOrders.length, (i) {
//                                   final order = pageOrders[i];
//                                   return DataRow(
//                                     color: MaterialStateProperty.all(const Color(0xFFFAFDFF)),
//                                     cells: [
//                                       DataCell(Text(order.orderId?.toString() ?? '')),
//                                       DataCell(Text(order.orderType ?? '')),
//                                       DataCell(Text(order.date ?? '')),
//                                       DataCell(Text(order.customerName ?? '')),
//                                       DataCell(Text(order.customerPhone ?? '')),
//                                       DataCell(Text(order.paymentType ?? '')),
//                                       DataCell(Text(order.amount?.toString() ?? '')),
//                                       DataCell(Text(order.discount?.toString() ?? '')),
//                                       DataCell(Text(order.total?.toString() ?? '')),
//
//                                       DataCell(Container(
//                                         width: 90,
//                                         height: 28,
//                                         decoration: BoxDecoration(
//                                           color: _statusColor(order.status ?? '').withOpacity(0.1),
//                                           borderRadius: BorderRadius.circular(50),
//                                         ),
//                                         alignment: Alignment.center,
//                                         child: Text(
//                                           order.status ?? '',
//                                           style: TextStyle(
//                                             color: _statusColor(order.status ?? ''),
//                                             fontWeight: FontWeight.w500,
//                                             fontSize: 12,
//                                           ),
//                                           overflow: TextOverflow.ellipsis,
//                                         ),
//                                       )),
//                                       DataCell(
//                                         Row(
//                                           children: [
//                                             GestureDetector(
//                                               onTap: () {
//                                                 showDialog(
//                                                     context: context,
//                                                     builder: (context) =>ViewOrderScreen(order: order.toMapForView())
//                                                   // <-- convert OrderModel to Map),
//                                                 );
//                                               },
//                                               child: Image.asset('assets/view.png', width: 20, height: 20),
//                                             ),
//                                             const SizedBox(width: 16),
//                                             GestureDetector(
//                                               onTap: () {
//                                                 print("Print clicked for order ID ${order.orderId}");
//                                               },
//                                               child: Image.asset('assets/print.png', width: 20, height: 20),
//                                             ),
//                                           ],
//                                         ),
//                                       ),
//
//                                     ],
//                                   );
//                                 }),
//                               ),
//                             ),
//                           ),
//                         ),
//
//                         /// PAGINATION
//
//                         Padding(
//                           padding: const EdgeInsets.only(right: 16.0),
//                           child: Align(
//                             alignment: Alignment.centerRight,
//                             child: Row(
//                               mainAxisSize: MainAxisSize.min,
//                               children: [
//                                 GestureDetector(
//                                   onTap: _previousPage,
//                                   child: _paginationButton(
//                                     text: "Previous",
//                                     borderRadius: const BorderRadius.only(
//                                       topLeft: Radius.circular(3),
//                                       bottomLeft: Radius.circular(3),
//                                     ),
//                                   ),
//                                 ),
//                                 Row(
//                                   children: _visiblePages(totalPages).map((index) {
//                                     final isActive = index == _currentPage;
//
//                                     return GestureDetector(
//                                       onTap: () => setState(() => _currentPage = index),
//                                       child: Container(
//                                         width: 30,
//                                         height: 30,
//                                         margin: const EdgeInsets.symmetric(horizontal: 2),
//                                         decoration: BoxDecoration(
//                                           color: isActive ? Colors.red : Colors.white,
//                                           border: Border.all(color: const Color(0xFFEEEEEE)),
//                                         ),
//                                         child: Center(
//                                           child: Text(
//                                             "${index + 1}",
//                                             style: TextStyle(
//                                               color: isActive ? Colors.white : const Color(0xFF727272),
//                                               fontSize: 10,
//                                               fontWeight: FontWeight.w500,
//                                             ),
//                                           ),
//                                         ),
//                                       ),
//                                     );
//                                   }).toList(),
//                                 ),
//                                 GestureDetector(
//                                   onTap: () => _nextPage(filtered.length),
//                                   child: _paginationButton(
//                                     text: "Next",
//                                     borderRadius: const BorderRadius.only(
//                                       topRight: Radius.circular(3),
//                                       bottomRight: Radius.circular(3),
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//
//
//                         const SizedBox(height: 10),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           );
//         } else if (state is OrderError) {
//           return Center(child: Text('Error: ${state.message}'));
//         }
//         return const Center(child: Text('No data'));
//       },
//     );
//   }
//
//   Widget _paginationButton(
//       {required String text, required BorderRadius borderRadius}) {
//     return Container(
//       width: 65,
//       height: 30,
//       decoration: ShapeDecoration(
//         shape: RoundedRectangleBorder(
//           side: const BorderSide(width: 1, color: Color(0xFFEEEEEE)),
//           borderRadius: borderRadius,
//         ),
//       ),
//       child: Center(
//         child: Text(
//           text,
//           style: const TextStyle(
//             color: Color(0xFF727272),
//             fontSize: 13,
//             fontWeight: FontWeight.w400,
//           ),
//         ),
//       ),
//     );
//   }
// }