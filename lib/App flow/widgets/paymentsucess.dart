import 'package:flutter/material.dart';
import 'package:pinaka_restaurant_pos/App%20flow/widgets/print_receipt.dart';

import '../../models/payment/payment_summary_model.dart';
// import 'Print_recipt.dart';

class Paymentsucess extends StatelessWidget {
  final String? amount;
  final String? paymentMode;
  final String? changeAmount;
  final int paymentId;
  final int orderId;
  final PaymentSummary paymentSummary;
  final String cashierName;

  // ✅ ADD THESE
  final List<Map<String, dynamic>> loadedTables;
  final String pin;
  final String token;
  final String restaurantId;
  final String restaurantName;
  final int? zoneId;


  const Paymentsucess({
    Key? key,
    this.amount,
    this.paymentMode,
    this.changeAmount,
    required this.paymentId,
    required this.orderId,
    required this.loadedTables,
    required this.pin,
    required this.token,
    required this.restaurantId,
    required this.restaurantName,
    this.zoneId,
    required this.paymentSummary,
    required this.cashierName,
  }) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery
          .of(context)
          .size
          .width * 0.45,
      height: MediaQuery
          .of(context)
          .size
          .height * 0.60,
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Padding(
        padding: EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomLeft,
                    colors: [Color(0xFFBAE8AB), Color(0xFFFFFFFF)],
                  ),
                  borderRadius: BorderRadius.circular(63),
                ),
                child: Center(
                  child: ClipOval(
                    child: Image.asset(
                      'assets/icon/sucess.png',
                      width: 55,
                      height: 55,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Your transaction is successfully Done!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF4C5F7D),
                  fontSize: 22,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 15),
              _buildInfoRow(context, paymentMode, amount),
              SizedBox(height: 15),
              _buildChangeRow(context, changeAmount),
              SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildActionButton(
                    context,
                    label: 'Void',
                    color: Color(0xFFFD6464),
                    onTap: () async {
                      final shouldVoid = await _showVoidConfirmation(context);
                      if (shouldVoid == true) {
                        if (!context.mounted) return;
                        Navigator.pop(context, "void");
                      }
                    },
                  ),
                  SizedBox(width: 30),
                  _buildActionButton(
                    context,
                    label: 'Print',
                    color: Color(0xFF1BA672),
                    onTap: () {
                      // Close PaymentSuccess dialog and tell parent to open PrintReceipt
                      Navigator.pop(context, "print");
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder:
                            (context) =>
                            Dialog(
                              backgroundColor: Colors.transparent,
                              insetPadding:
                              EdgeInsets.zero, // Remove default margin
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    left: 330,
                                    top: 60,
                                    bottom: 60,
                                  ),
                                  child: PrintRecipt(
                                    loadedTables: loadedTables,
                                    pin: pin,
                                    token: token,
                                    restaurantId: restaurantId,
                                    restaurantName: restaurantName,
                                    zoneId: zoneId,
                                    paymentSummary: paymentSummary,
                                    cashierName: cashierName,
                                    isTakeAway: true,
                                  ),

                                ),
                              ),
                            ),
                      );
                    },
                  ),

                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String? mode, String? amount) {
    return Container(
      height: MediaQuery
          .of(context)
          .size
          .height * 0.07,
      width: MediaQuery
          .of(context)
          .size
          .width * 0.38,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Color(0x10000000), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 1),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            mode ?? '',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: Color(0xFF4C5F7D),
            ),
          ),
          Text(
            "₹${amount ?? '0.00'}",
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: Color(0xFF4C5F7D),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChangeRow(BuildContext context, String? change) {
    debugPrint("🟢 Change received in UI = $change");

    final double changeAmount = double.tryParse(change ?? '') ?? 0.0;
    // final double changeAmount = double.tryParse(change ?? '') ?? 0.0;

    return Container(
      height: MediaQuery
          .of(context)
          .size
          .height * 0.07,
      width: MediaQuery
          .of(context)
          .size
          .width * 0.38,
      decoration: BoxDecoration(
        color: Color(0x101BA672),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Color(0x101BA672), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Color(0x101BA672),
            blurRadius: 10,
            offset: Offset(0, 1),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Change:",
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 20,
              color: Color(0xFF1BA672),
            ),
          ),
          Text(
            "₹${(double.tryParse(change ?? '0.00')?.abs() ?? 0.00)
                .toStringAsFixed(2)}",
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 20,
              color: Color(0xFF1BA672),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, {
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180,
        height: 50,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Color(0x19000000),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Future<bool?> _showVoidConfirmation(BuildContext context) {
    final isDark = Theme
        .of(context)
        .brightness == Brightness.dark;

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Center( // ✅ controls width
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 400, // 👈 reduced width
            ),
            child: Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor:
              isDark ? const Color(0xFF1E1E2E) : Colors.white,
              child: Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 🔴 Icon
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.warning_rounded,
                        color: Colors.red,
                        size: 24,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Title
                    Text(
                      "Void Payment",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Message
                    Text(
                      "Do you want to void this payment?",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () =>
                                Navigator.pop(dialogContext, false),
                            child: const Text("Cancel"),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () =>
                                Navigator.pop(dialogContext, true),
                            child: const Text(
                              "Void",
                              style: TextStyle(
                                  color: Colors.white), // ✅ white text
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}