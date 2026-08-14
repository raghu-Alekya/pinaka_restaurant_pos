import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../constants/color_constants.dart';
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
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _captainName = prefs.getString('display_name') ??
            prefs.getString('fullName') ??
            'Captain';
        _captainRole = prefs.getString('user_role') ?? 'Captain';
      });
    } catch (e) {
      // Fallback to defaults
      setState(() {
        _captainName = 'Captain';
        _captainRole = 'Captain';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios), // 👈 iOS style back icon
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Bill Summary',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black),
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
          }
          if (state is BillGenerated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
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

  Widget _buildContent(BillSummaryEntity? data) {
    if (data == null) return const SizedBox.shrink();

    final dateTime = DateTime.now();
    final formattedDate = DateFormat('dd, MMM yyyy, hh:mm a').format(dateTime);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---- Header ----
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Order ID',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    Text(
                      '#${data.orderId}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: ColorConstants.primaryColor,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Total Amount',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    Text(
                      '\$${data.netTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: ColorConstants.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _captainRole, // 👈 Dynamic role
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    Text(
                      _captainName, // 👈 Dynamic name
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ---- Date & Time ----
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  formattedDate,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ---- Order Items ----
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Order Items',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      '(${data.lineItems.length})',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                const Divider(),
                ...data.lineItems.map((item) => _buildItemRow(item)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ---- Payment Summary ----
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Payment Summary',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Divider(),
                _buildSummaryRow('Items', '${data.lineItems.length} Items'),
                _buildSummaryRow('Net Total', '\$${data.grossTotal.toStringAsFixed(2)}'),
                _buildSummaryRow(
                  'Tax (${data.tax > 0 ? (data.tax / data.grossTotal * 100).toStringAsFixed(1) : '0'}%)',
                  '\$${data.tax.toStringAsFixed(2)}',
                ),
                if (data.serviceChargeValue > 0)
                  _buildSummaryRow(
                    'Service Charge',
                    '\$${data.serviceChargeValue.toStringAsFixed(2)}',
                  ),
                if (data.couponTotal > 0)
                  _buildSummaryRow(
                    'Coupon Discount',
                    '-\$${data.couponTotal.toStringAsFixed(2)}',
                  ),
                if (data.merchantDiscount > 0)
                  _buildSummaryRow(
                    'Merchant Discount',
                    '-\$${data.merchantDiscount.toStringAsFixed(2)}',
                  ),
                if (data.tip > 0)
                  _buildSummaryRow('Tip', '\$${data.tip.toStringAsFixed(2)}'),
                const Divider(),
                _buildSummaryRow(
                  'Total Amount',
                  '\$${data.netTotal.toStringAsFixed(2)}',
                  isTotal: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ---- Generate Bill Button ----
          SizedBox(
            width: double.infinity,
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

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Bill printed successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to print bill: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConstants.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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

  Widget _buildItemRow(LineItemEntity item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              Text(
                '\$${item.total.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          if (item.modifiers.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 2),
              child: Text(
                item.modifiers.map((m) => m.toString()).join(', '),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ),
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
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
              color: isTotal ? ColorConstants.primaryColor : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}