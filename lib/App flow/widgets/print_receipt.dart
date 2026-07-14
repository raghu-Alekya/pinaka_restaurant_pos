import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/Bloc Event/order_event.dart';
import '../../blocs/Bloc Logic/order_bloc.dart';
import '../../models/UserPermissions.dart';
import '../../models/payment/payment_summary_model.dart';
import '../../printer/printer_service.dart';
import '../ui/dashboard screen.dart';
import '../ui/tables_screen.dart';

class PrintRecipt extends StatefulWidget {
  final PaymentSummary paymentSummary;
  final String cashierName;
  final String pin;
  final String token;
  final String restaurantId;
  final String restaurantName;
  final List<Map<String, dynamic>> loadedTables;
  final int? zoneId;
  final bool isTakeAway;
  final UserPermissions? userPermissions;

  const PrintRecipt({
    Key? key,
    required this.paymentSummary,
    required this.cashierName,
    required this.pin,
    required this.token,
    required this.restaurantId,
    required this.restaurantName,
    required this.loadedTables,
    this.zoneId,
    this.isTakeAway = false,
    this.userPermissions,
  }) : super(key: key);

  @override
  State<PrintRecipt> createState() => _PrintReciptState();
}

class _PrintReciptState extends State<PrintRecipt> {
  String _selectedOption = 'Printer';
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _smsController = TextEditingController();
  final List<String> options = ['Printer', 'Email', 'SMS'];
  @override
  void initState() {
    super.initState();
    _selectedOption = 'Printer';
  }

  void _onDonePressed({bool isNoReceipt = false}) async {
    if (!isNoReceipt) {
      // 1️⃣ Validation
      if (_selectedOption == 'Email') {
        final email = _emailController.text.trim();
        if (email.isEmpty || !email.contains("@")) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Please enter a valid email address"),
              duration: Duration(seconds: 1),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      if (_selectedOption == 'SMS') {
        final sms = _smsController.text.trim();
        if (sms.isEmpty || sms.length != 10) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Please enter a valid phone number"),
              duration: Duration(seconds: 1),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      // ✅ Print receipt when Printer is selected
      if (_selectedOption == 'Printer') {
        try {
          await Printer.printBill(
            context: context,
            orderId: widget.paymentSummary.orderId.toString(),
            tableName: widget.paymentSummary.tableName,
            cashierName: widget.cashierName,
            items: widget.paymentSummary.lineItems.map((item) {
              return {
                "name": item.name,
                "qty": item.qty,
                "price": item.price,
                "amount": item.total,
                "modifiers": item.modifiers,
              };
            }).toList(),
            grossTotal: widget.paymentSummary.grossTotal,
            couponDiscount: widget.paymentSummary.coupons,
            merchantDiscount: widget.paymentSummary.discount,
            tipAmount: widget.paymentSummary.tipAmount,
            taxAmount: widget.paymentSummary.tax,
            serviceCharge: widget.paymentSummary.serviceChargeValue,
            netPayable: widget.paymentSummary.netTotal,
          );
        } catch (e) {
          debugPrint("Print failed: $e");
        }
      }
    }

    // ✅ STEP 1: CLOSE THE PRINT DIALOG
    Navigator.of(context).pop();

    // ✅ STEP 2: CLEAR ORDER STATE
    // context.read<OrderBloc>().add(ClearOrder());
    context.read<OrderBloc>().add(ResetOrder());
    // ⏳ Small delay ensures Bloc processes event before navigation
    await Future.delayed(const Duration(milliseconds: 100));

    if (!mounted) return;

    // ✅ STEP 3: NAVIGATE BASED ON ORDER TYPE
    if (widget.isTakeAway) {
      // For Takeaway: Navigate to DashboardScreen with takeaway mode
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => DashboardScreen(
            pin: widget.pin,
            token: widget.token,
            restaurantId: widget.restaurantId,
            restaurantName: widget.restaurantName,
            userPermissions: widget.userPermissions,
            isTakeAway: true,
          ),
        ),
            (route) => false,
      );
    } else {
      // For Dine-in: Navigate to TablesScreen
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => TablesScreen(
            loadedTables: widget.loadedTables,
            pin: widget.pin,
            token: widget.token,
            restaurantId: widget.restaurantId,
            restaurantName: widget.restaurantName,
            zoneId: widget.zoneId,
          ),
        ),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.45,
      height: MediaQuery.of(context).size.height * 0.60,
      padding: EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipOval(
              child: Image.asset(
                'assets/icon/printer.png',
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Please choose how you'd like to",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w500,
                color: Color(0xFF4C5F7D),
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              "share it.",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w500,
                color: Color(0xFF4C5F7D),
              ),
            ),
            SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: options.map((option) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedOption = option;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _selectedOption == option
                          ? Colors.red.shade50
                          : Colors.white,
                      border: Border.all(
                        color: _selectedOption == option
                            ? Colors.redAccent
                            : Color(0xFFE7E2E2),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Radio<String>(
                          value: option,
                          groupValue: _selectedOption,
                          onChanged: (value) {
                            setState(() {
                              _selectedOption = value!;
                            });
                          },
                          activeColor: Colors.redAccent,
                        ),
                        SizedBox(width: 6),
                        Text(
                          option,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFAFACAC),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 10),
            SizedBox(
              height: 70,
              child: AnimatedSwitcher(
                duration: Duration(milliseconds: 300),
                child: _selectedOption == 'Email'
                    ? _buildTextField(
                  hintText: 'Enter Email Address',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                )
                    : _selectedOption == 'SMS'
                    ? _buildTextField(
                  hintText: 'Enter phone number',
                  controller: _smsController,
                  keyboardType: TextInputType.number,
                )
                    : SizedBox.shrink(),
              ),
            ),
            SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildDialogButton(
                  label: 'No Receipt',
                  color: const Color(0xFFECEEF2),
                  textColor: const Color(0xFF4C5F7D),
                  onTap: () => _onDonePressed(isNoReceipt: true),
                ),
                const SizedBox(width: 20),
                _buildDialogButton(
                  label: 'Done',
                  color: const Color(0xFF1BA672),
                  textColor: Colors.white,
                  onTap: () => _onDonePressed(isNoReceipt: false),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String hintText,
    required TextEditingController controller,
    required TextInputType keyboardType,
  }) {
    List<TextInputFormatter> inputFormatters = [];

    if (keyboardType == TextInputType.number) {
      inputFormatters = [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ];
    } else if (keyboardType == TextInputType.emailAddress) {
      inputFormatters = [
        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9@._]')),
        LengthLimitingTextInputFormatter(32),
      ];
    }
    return Container(
      width: MediaQuery.of(context).size.width * 0.48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Color(0xFFE7E2E2), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFE7E2E2),
            blurRadius: 10,
            offset: Offset(0, 1),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: TextStyle(fontSize: 16, color: Colors.black87),
        decoration: InputDecoration(
          hintText: hintText,
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildDialogButton({
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        height: 45,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}