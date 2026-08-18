// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:intl/intl.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../ captain_pin_login/captain_login_data_layer/captain_local_storage.dart';
// import '../../../../constants/color_constants.dart';
// import '../home_screen/TableManagement_Screen.dart';
// import '../printer/printer_service.dart';
// import 'bill_summary_bloc/bill_summary_bloc.dart';
// import 'bill_summary_bloc/bill_summary_event.dart';
// import 'bill_summary_bloc/bill_summary_state.dart';
// import 'bill_summary_domain/bill_summary_entity.dart';
//
// class BillSummaryScreen extends StatefulWidget {
//   final int orderId;
//   final int restaurantId;
//   final String orderType;
//   final int zoneId;
//
//   const BillSummaryScreen({
//     Key? key,
//     required this.orderId,
//     required this.restaurantId,
//     required this.orderType,
//     required this.zoneId,
//   }) : super(key: key);
//
//   @override
//   State<BillSummaryScreen> createState() => _BillSummaryScreenState();
// }
//
// class _BillSummaryScreenState extends State<BillSummaryScreen> {
//   String _captainName = 'Captain';
//   String _captainRole = 'Captain';
//   String _currencySymbol = '\$';
//
//   @override
//   void initState() {
//     super.initState();
//     _loadCaptainDetails();
//     context.read<BillSummaryBloc>().add(
//       LoadBillSummary(
//         orderId: widget.orderId,
//         restaurantId: widget.restaurantId,
//         orderType: widget.orderType,
//         zoneId: widget.zoneId,
//       ),
//     );
//   }
//
//   Future<void> _loadCaptainDetails() async {
//     try {
//       // Load captain details from CaptainLocalStorage (which reads from SharedPreferences)
//       final captainStorage = context.read<CaptainLocalStorage>();
//       final captainData = await captainStorage.getCaptainData();
//
//       setState(() {
//         _captainName = captainData?.data?.displayName ?? 'Captain';
//         _captainRole = captainData?.data?.role ?? 'Captain';
//         _currencySymbol = captainData?.data?.currencySymbol ?? '\$';
//         print('🪙 Bill summary currency symbol: $_currencySymbol');
//       });
//     } catch (e) {
//       setState(() {
//         _captainName = 'Captain';
//         _captainRole = 'Captain';
//         _currencySymbol = '\$';
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F5F5),
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         foregroundColor: Colors.black,
//         elevation: 0.5,
//         centerTitle: true,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: const Text(
//           'Bill Summary',
//           style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black),
//         ),
//       ),
//       body: BlocConsumer<BillSummaryBloc, BillSummaryState>(
//         listener: (context, state) {
//           if (state is BillSummaryError) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(
//                 content: Text(state.message),
//                 backgroundColor: Colors.red,
//               ),
//             );
//           }
//           if (state is BillGenerated) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(
//                 content: Text('Bill printed successfully'),
//                 backgroundColor: Colors.green,
//               ),
//             );
//             // Navigate to TableManagementScreen and clear the stack
//             Navigator.of(context).pushAndRemoveUntil(
//               MaterialPageRoute(
//                 builder: (_) => TableManagementScreen(
//                   captainName: _captainName,
//                   captainRole: _captainRole,
//                 ),
//               ),
//                   (route) => false,
//             );
//           }
//         },
//         builder: (context, state) {
//           if (state is BillSummaryLoading) {
//             return const Center(child: CircularProgressIndicator());
//           } else if (state is BillSummaryLoaded) {
//             return _buildContent(state.data);
//           } else if (state is BillGenerating) {
//             return Stack(
//               children: [
//                 _buildContent(null),
//                 Container(
//                   color: Colors.black.withOpacity(0.3),
//                   child: const Center(child: CircularProgressIndicator()),
//                 ),
//               ],
//             );
//           }
//           return const Center(child: Text('No data'));
//         },
//       ),
//     );
//   }
//
//   Widget _buildContent(BillSummaryEntity? data) {
//     if (data == null) return const SizedBox.shrink();
//
//     final dateTime = DateTime.now();
//     final formattedDate = DateFormat('dd, MMM yyyy, hh:mm a').format(dateTime);
//
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // ---- Header ----
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(12),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.05),
//                   blurRadius: 4,
//                   offset: const Offset(0, 2),
//                 ),
//               ],
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'Order ID',
//                       style: TextStyle(color: Colors.grey, fontSize: 12),
//                     ),
//                     Text(
//                       '#${data.orderId}',
//                       style: const TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 18,
//                         color: ColorConstants.primaryColor,
//                       ),
//                     ),
//                   ],
//                 ),
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.end,
//                   children: [
//                     const Text(
//                       'Total Amount',
//                       style: TextStyle(color: Colors.grey, fontSize: 12),
//                     ),
//                     Text(
//                       '$_currencySymbol${data.netTotal.toStringAsFixed(2)}',
//                       style: const TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 20,
//                         color: ColorConstants.primaryColor,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       _captainRole,
//                       style: const TextStyle(color: Colors.grey, fontSize: 12),
//                     ),
//                     Text(
//                       _captainName,
//                       style: const TextStyle(
//                         fontWeight: FontWeight.w600,
//                         fontSize: 14,
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 16),
//
//           // ---- Date & Time ----
//           Container(
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(12),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.05),
//                   blurRadius: 4,
//                   offset: const Offset(0, 2),
//                 ),
//               ],
//             ),
//             child: Row(
//               children: [
//                 const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
//                 const SizedBox(width: 8),
//                 Text(
//                   formattedDate,
//                   style: const TextStyle(fontWeight: FontWeight.w500),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 16),
//
//           // ---- Order Items ----
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(12),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.05),
//                   blurRadius: 4,
//                   offset: const Offset(0, 2),
//                 ),
//               ],
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     const Text(
//                       'Order Items',
//                       style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                     ),
//                     Text(
//                       '(${data.lineItems.length})',
//                       style: const TextStyle(color: Colors.grey),
//                     ),
//                   ],
//                 ),
//                 const Divider(),
//                 ...data.lineItems.map((item) => _buildItemRow(item)),
//               ],
//             ),
//           ),
//           const SizedBox(height: 16),
//
//           // ---- Payment Summary ----
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(12),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.05),
//                   blurRadius: 4,
//                   offset: const Offset(0, 2),
//                 ),
//               ],
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text(
//                   'Payment Summary',
//                   style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                 ),
//                 const Divider(),
//                 _buildSummaryRow('Items', '${data.lineItems.length} Items'),
//                 _buildSummaryRow('Net Total', '$_currencySymbol${data.grossTotal.toStringAsFixed(2)}'),
//                 _buildSummaryRow(
//                   'Tax (${data.tax > 0 ? (data.tax / data.grossTotal * 100).toStringAsFixed(1) : '0'}%)',
//                   '$_currencySymbol${data.tax.toStringAsFixed(2)}',
//                 ),
//                 if (data.serviceChargeValue > 0)
//                   _buildSummaryRow(
//                     'Service Charge',
//                     '$_currencySymbol${data.serviceChargeValue.toStringAsFixed(2)}',
//                   ),
//                 if (data.couponTotal > 0)
//                   _buildSummaryRow(
//                     'Coupon Discount',
//                     '-$_currencySymbol${data.couponTotal.toStringAsFixed(2)}',
//                   ),
//                 if (data.merchantDiscount > 0)
//                   _buildSummaryRow(
//                     'Merchant Discount',
//                     '-$_currencySymbol${data.merchantDiscount.toStringAsFixed(2)}',
//                   ),
//                 if (data.tip > 0)
//                   _buildSummaryRow('Tip', '$_currencySymbol${data.tip.toStringAsFixed(2)}'),
//                 const Divider(),
//                 _buildSummaryRow(
//                   'Total Amount',
//                   '$_currencySymbol${data.netTotal.toStringAsFixed(2)}',
//                   isTotal: true,
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 24),
//
//           // ---- Generate Bill Button ----
//           SizedBox(
//             width: double.infinity,
//             child: ElevatedButton(
//               onPressed: () async {
//                 try {
//                   final items = data.lineItems.map((item) {
//                     return {
//                       'name': item.name,
//                       'qty': item.qty,
//                       'price': item.price,
//                       'amount': item.total,
//                       'modifiers': item.modifiers.map((m) => m.toString()).toList(),
//                     };
//                   }).toList();
//
//                   await Printer.printBill(
//                     orderId: data.orderId.toString(),
//                     tableName: data.tableName,
//                     cashierName: _captainName,
//                     items: items,
//                     grossTotal: data.grossTotal,
//                     couponDiscount: data.couponTotal,
//                     merchantDiscount: data.merchantDiscount,
//                     tipAmount: data.tip,
//                     taxAmount: data.tax,
//                     serviceCharge: data.serviceChargeValue,
//                     netPayable: data.netTotal,
//                     context: context,
//                   );
//
//                   // The BLoC will emit BillGenerated, which triggers the listener above.
//                   // We don't navigate here to avoid double navigation.
//                 } catch (e) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(
//                       content: Text('Failed to print bill: $e'),
//                       backgroundColor: Colors.red,
//                     ),
//                   );
//                 }
//               },
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: ColorConstants.primaryColor,
//                 foregroundColor: Colors.white,
//                 padding: const EdgeInsets.symmetric(vertical: 14),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//               child: const Text(
//                 'Generate Bill',
//                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//               ),
//             ),
//           ),
//           const SizedBox(height: 20),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildItemRow(LineItemEntity item) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Expanded(
//                 child: Text(
//                   item.name,
//                   style: const TextStyle(fontWeight: FontWeight.w500),
//                 ),
//               ),
//               Text(
//                 '$_currencySymbol${item.total.toStringAsFixed(2)}',
//                 style: const TextStyle(fontWeight: FontWeight.bold),
//               ),
//             ],
//           ),
//           if (item.modifiers.isNotEmpty)
//             Padding(
//               padding: const EdgeInsets.only(left: 8, top: 2),
//               child: Text(
//                 item.modifiers.map((m) => m.toString()).join(', '),
//                 style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
//               ),
//             ),
//           Text(
//             'Qty: ${item.qty}',
//             style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             label,
//             style: TextStyle(
//               fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
//               fontSize: isTotal ? 16 : 14,
//             ),
//           ),
//           Text(
//             value,
//             style: TextStyle(
//               fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
//               fontSize: isTotal ? 16 : 14,
//               color: isTotal ? ColorConstants.primaryColor : Colors.black,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }


////===

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../ captain_pin_login/captain_login_data_layer/captain_local_storage.dart';
import '../../../../constants/color_constants.dart';
import '../home_screen/TableManagement_Screen.dart';
import '../printer/printer_service.dart';
import 'bill_summary_bloc/bill_summary_bloc.dart';
import 'bill_summary_bloc/bill_summary_event.dart';
import 'bill_summary_bloc/bill_summary_state.dart';
import 'bill_summary_domain/bill_summary_entity.dart';

class BillSummaryScreen extends StatefulWidget {
  final int orderId;
  final int restaurantId;
  final String orderType;
  final int zoneId;

  const BillSummaryScreen({
    Key? key,
    required this.orderId,
    required this.restaurantId,
    required this.orderType,
    required this.zoneId,
  }) : super(key: key);

  @override
  State<BillSummaryScreen> createState() => _BillSummaryScreenState();
}

class _BillSummaryScreenState extends State<BillSummaryScreen> {
  String _captainName = 'Captain';
  String _captainRole = 'Captain';
  String _currencySymbol = '\$';

  @override
  void initState() {
    super.initState();
    _loadCaptainDetails();
    context.read<BillSummaryBloc>().add(
      LoadBillSummary(
        orderId: widget.orderId,
        restaurantId: widget.restaurantId,
        orderType: widget.orderType,
        zoneId: widget.zoneId,
      ),
    );
  }

  Future<void> _loadCaptainDetails() async {
    try {
      final captainStorage = context.read<CaptainLocalStorage>();
      final captainData = await captainStorage.getCaptainData();

      setState(() {
        _captainName = captainData?.data?.displayName ?? 'Captain';
        _captainRole = captainData?.data?.role ?? 'Captain';
        _currencySymbol = captainData?.data?.currencySymbol ?? '\$';
        print('🪙 Bill summary currency symbol: $_currencySymbol');
      });
    } catch (e) {
      setState(() {
        _captainName = 'Captain';
        _captainRole = 'Captain';
        _currencySymbol = '\$';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Bill Summary',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black, fontSize: 18),
        ),
      ),
      body: BlocConsumer<BillSummaryBloc, BillSummaryState>(
        listener: (context, state) {
          if (state is BillSummaryError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
            // If there's an error (including no printer), still navigate back
            _goToTableManagement();
          }
        },
        builder: (context, state) {
          if (state is BillSummaryLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is BillSummaryLoaded) {
            return _buildContent(state.data);
          } else if (state is BillGenerating) {
            return Stack(
              children: [
                _buildContent(null),
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ],
            );
          }
          return const Center(child: Text('No data'));
        },
      ),
    );
  }

  void _goToTableManagement() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => TableManagementScreen(
          captainName: _captainName,
          captainRole: _captainRole,
        ),
      ),
          (route) => false,
    );
  }

  Widget _buildContent(BillSummaryEntity? data) {
    if (data == null) return const SizedBox.shrink();

    final dateTime = DateTime.now();
    final formattedDate = DateFormat('dd, MMM yyyy, hh.mm a').format(dateTime);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---- Order info card (matches Figma "Bill Summary" top card) ----
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                _buildInfoRow('Order ID', '#${data.orderId}'),
                _buildInfoRow('Order type', widget.orderType),
                _buildInfoRow(
                  'Total Amount',
                  '$_currencySymbol${data.netTotal.toStringAsFixed(2)}',
                  valueBold: true,
                ),
                _buildInfoRow('Captain', _captainName),
                _buildInfoRow('Date & Time', formattedDate, isLast: true),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ---- Order Items label ----
          Text(
            'Order Items (${data.lineItems.length})',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
          ),
          const SizedBox(height: 10),

          // ---- Order Items card (scrollable list) ----
          Container(
            constraints: const BoxConstraints(maxHeight: 260),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Scrollbar(
              thumbVisibility: true,
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                itemCount: data.lineItems.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: Colors.grey.shade100,
                ),
                itemBuilder: (context, index) => _buildItemRow(data.lineItems[index]),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ---- Payment Summary ----
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Payment Summary',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                _buildSummaryRow('Items', '${data.lineItems.length} Items'),
                _buildSummaryRow('Net Total', '$_currencySymbol${data.grossTotal.toStringAsFixed(2)}'),
                _buildSummaryRow(
                  'Tax (${data.tax > 0 ? (data.tax / data.grossTotal * 100).toStringAsFixed(1) : '0'}%)',
                  '$_currencySymbol${data.tax.toStringAsFixed(2)}',
                ),
                if (data.serviceChargeValue > 0)
                  _buildSummaryRow(
                    'Service Charge',
                    '$_currencySymbol${data.serviceChargeValue.toStringAsFixed(2)}',
                  ),
                if (data.couponTotal > 0)
                  _buildSummaryRow(
                    'Coupon Discount',
                    '-$_currencySymbol${data.couponTotal.toStringAsFixed(2)}',
                  ),
                if (data.merchantDiscount > 0)
                  _buildSummaryRow(
                    'Merchant Discount',
                    '-$_currencySymbol${data.merchantDiscount.toStringAsFixed(2)}',
                  ),
                if (data.tip > 0)
                  _buildSummaryRow('Tip', '$_currencySymbol${data.tip.toStringAsFixed(2)}'),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: _DashedDivider(),
                ),
                _buildSummaryRow(
                  'Total Amount',
                  '$_currencySymbol${data.netTotal.toStringAsFixed(2)}',
                  isTotal: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ---- Generate Bill Button ----
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () async {
                try {
                  final items = data.lineItems.map((item) {
                    return {
                      'name': item.name,
                      'qty': item.qty,
                      'price': item.price,
                      'amount': item.total,
                      'modifiers': item.modifiers.map((m) => m.toString()).toList(),
                    };
                  }).toList();

                  await Printer.printBill(
                    orderId: data.orderId.toString(),
                    tableName: data.tableName,
                    cashierName: _captainName,
                    items: items,
                    grossTotal: data.grossTotal,
                    couponDiscount: data.couponTotal,
                    merchantDiscount: data.merchantDiscount,
                    tipAmount: data.tip,
                    taxAmount: data.tax,
                    serviceCharge: data.serviceChargeValue,
                    netPayable: data.netTotal,
                    context: context,
                  );

                  // Success
                  // ScaffoldMessenger.of(context).showSnackBar(
                  //   const SnackBar(
                  //     content: Text('Bill printed successfully'),
                  //     backgroundColor: Colors.green,
                  //   ),
                  // );

                } catch (e) {
                  // Error (including "No printer selected")
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to print bill: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                // Always navigate to TableManagementScreen after attempting to print
                _goToTableManagement();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConstants.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Generate Bill',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ---- Info row for the top order-details card ----
  Widget _buildInfoRow(String label, String value, {bool valueBold = false, bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: Colors.grey.shade100, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: valueBold ? FontWeight.bold : FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(LineItemEntity item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black87),
                ),
              ),
              Text(
                '$_currencySymbol${item.total.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
              ),
            ],
          ),
          if (item.modifiers.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              item.modifiers.map((m) => m.toString()).join(', '),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
          const SizedBox(height: 2),
          Text(
            'Qty: ${item.qty}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
              color: isTotal ? Colors.black87 : Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
              color: isTotal ? ColorConstants.primaryColor : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

// ---- Simple dashed divider to match the Figma "Payment Summary" separator ----
class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 5.0;
        const dashSpace = 4.0;
        final dashCount = (constraints.constrainWidth() / (dashWidth + dashSpace)).floor();
        return Flex(
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return const SizedBox(
              width: dashWidth,
              height: 1,
              child: DecoratedBox(decoration: BoxDecoration(color: Color(0xFFD9D9D9))),
            );
          }).expand((widget) => [widget, const SizedBox(width: dashSpace)]).toList(),
        );
      },
    );
  }
}