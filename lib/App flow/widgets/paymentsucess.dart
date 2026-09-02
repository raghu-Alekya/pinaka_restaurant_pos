import 'package:flutter/material.dart';
import 'package:pinaka_restaurant_pos/App%20flow/widgets/print_receipt.dart';

import '../../models/payment/payment_summary_model.dart';

class Paymentsucess extends StatefulWidget {
  final String? amount;
  final String? paymentMode;
  final String? changeAmount;
  final int paymentId;
  final int orderId;
  final PaymentSummary paymentSummary;
  final String cashierName;

  final List<Map<String, dynamic>> loadedTables;
  final String pin;
  final String token;
  final String restaurantId;
  final String restaurantName;
  final int? zoneId;
  final bool isTakeAway;
  final bool isFromOrderList;
  const Paymentsucess({
    super.key,
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
    this.isTakeAway = false,
    this.isFromOrderList = false,
  });

  @override
  State<Paymentsucess> createState() => _PaymentsucessState();
}

class _PaymentsucessState extends State<Paymentsucess> {
  bool _hidePaymentSuccess = false;
  @override
  void initState() {
    super.initState();

    debugPrint('========== PAYMENT SUCCESS CREATED ==========');
    debugPrint('isFromOrderList: ${widget.isFromOrderList}');
    debugPrint('isTakeAway: ${widget.isTakeAway}');
    debugPrint('Order ID: ${widget.orderId}');
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return IgnorePointer(
      ignoring: _hidePaymentSuccess,
      child: Opacity(
        opacity: _hidePaymentSuccess ? 0 : 1,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.45,
          height: MediaQuery.of(context).size.height * 0.60,
          decoration: ShapeDecoration(
            color: theme.cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // =========================================================
                  // SUCCESS ICON
                  // =========================================================
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomLeft,
                        colors: isDark
                            ? [
                          Colors.green.shade800,
                          theme.cardColor,
                        ]
                            : const [
                          Color(0xFFBAE8AB),
                          Colors.white,
                        ],
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

                  const SizedBox(height: 12),

                  // =========================================================
                  // TITLE
                  // =========================================================
                  Text(
                    'Your transaction is successfully Done!',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 15),

                  // =========================================================
                  // PAYMENT INFORMATION
                  // =========================================================
                  _buildInfoRow(
                    context,
                    widget.paymentMode,
                    widget.amount,
                  ),

                  const SizedBox(height: 15),

                  // =========================================================
                  // CHANGE AMOUNT
                  // =========================================================
                  _buildChangeRow(
                    context,
                    widget.changeAmount,
                  ),

                  const SizedBox(height: 25),

                  // =========================================================
                  // ACTION BUTTONS
                  // =========================================================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // =====================================================
                      // VOID BUTTON
                      // =====================================================
                      _buildActionButton(
                        context,
                        label: 'Void',
                        color: Colors.red.shade400,
                        onTap: () async {
                          // Hide Payment Success UI.
                          setState(() {
                            _hidePaymentSuccess = true;
                          });

                          // Wait for UI rebuild.
                          await Future.delayed(
                            const Duration(milliseconds: 100),
                          );

                          if (!mounted) return;

                          // Show Void Confirmation.
                          final shouldVoid =
                          await _showVoidConfirmation(context);

                          if (!mounted) return;

                          // ===============================================
                          // YES, VOID
                          // ===============================================
                          if (shouldVoid == true) {
                            // Preserve your original navigation logic.
                            Navigator.pop(context, "void");
                            return;
                          }

                          // ===============================================
                          // CANCEL
                          // ===============================================
                          if (shouldVoid == false) {
                            // Show Payment Success UI again.
                            setState(() {
                              _hidePaymentSuccess = false;
                            });
                          }
                        },
                      ),

                      const SizedBox(width: 30),

                      // =====================================================
                      // PRINT BUTTON
                      // =====================================================
                      _buildActionButton(
                        context,
                        label: 'Print',
                        color: Colors.green.shade600,
                        onTap: () {
                          Navigator.pop(context);

                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => Dialog(
                              backgroundColor: Colors.transparent,
                              insetPadding: EdgeInsets.zero,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    left: 330,
                                    top: 60,
                                    bottom: 60,
                                  ),
                                  child: PrintRecipt(
                                    loadedTables: widget.loadedTables,
                                    pin: widget.pin,
                                    token: widget.token,
                                    restaurantId: widget.restaurantId,
                                    restaurantName: widget.restaurantName,
                                    zoneId: widget.zoneId,
                                    paymentSummary:
                                    widget.paymentSummary,
                                    cashierName: widget.cashierName,
                                    isTakeAway: widget.isTakeAway,
                                    isFromOrderList: widget.isFromOrderList,
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
        ),
      ),
    );
  }

  // =============================================================
  // PAYMENT INFO ROW
  // =============================================================

  Widget _buildInfoRow(
      BuildContext context,
      String? mode,
      String? amount,
      ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final formattedAmount =
    (double.tryParse(amount ?? '0') ?? 0).toStringAsFixed(2);

    return Container(
      height: MediaQuery.of(context).size.height * 0.07,
      width: MediaQuery.of(context).size.width * 0.38,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.3),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.4)
                : Colors.black12,
            blurRadius: 10,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            mode ?? '',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: isDark
                  ? const Color(0xFF498FFF)
                  : theme.colorScheme.onSurface,
            ),
          ),
          Text(
            "₹$formattedAmount",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: isDark
                  ? const Color(0xFF498FFF)
                  : theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // CHANGE ROW
  // =============================================================

  Widget _buildChangeRow(
      BuildContext context,
      String? change,
      ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.07,
      width: MediaQuery.of(context).size.width * 0.38,
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1BA672).withOpacity(0.18)
            : const Color(0x101BA672),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: const Color(0xFF1BA672).withOpacity(0.4),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.35)
                : const Color(0x101BA672),
            blurRadius: 10,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Change:",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 20,
              color: const Color(0xFF1BA672),
            ),
          ),
          Text(
            "₹${(double.tryParse(change ?? '0.00')?.abs() ?? 0.00).toStringAsFixed(2)}",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 20,
              color: const Color(0xFF1BA672),
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // ACTION BUTTON
  // =============================================================

  Widget _buildActionButton(
      BuildContext context, {
        required String label,
        required Color color,
        required VoidCallback onTap,
      }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
              color: isDark
                  ? Colors.black.withOpacity(0.45)
                  : Colors.black.withOpacity(0.10),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  // =============================================================
  // VOID CONFIRMATION POPUP
  // =============================================================

  Future<bool?> _showVoidConfirmation(
      BuildContext context,
      ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.72),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding:
          const EdgeInsets.symmetric(horizontal: 30),
          child: Container(
            width: 500,
            constraints: const BoxConstraints(maxWidth: 556),
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? const [
                  Color(0xFF46333A),
                  Color(0xFF202433),
                ]
                    : const [
                  Color(0xFFF5D0D0),
                  Color(0xFFFFF8F8),
                  Colors.white,
                ],
                stops: isDark
                    ? const [0.0, 1.0]
                    : const [0.0, 0.45, 1.0],
              ),
              borderRadius: BorderRadius.circular(22),
              border: const Border(
                top: BorderSide(
                  color: Color(0xFFFF3B30),
                  width: 6,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(
                    isDark ? 0.45 : 0.22,
                  ),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // =========================================================
                // ICON + TEXT
                // =========================================================

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF2A2F3D)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color(0xFFFF3B30),
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.warning_rounded,
                        color: Color(0xFFE53935),
                        size: 38,
                      ),
                    ),

                    const SizedBox(width: 28),

                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Void Payment?',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF373535),
                                fontSize: 28,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w600,
                                height: 1.2,
                              ),
                            ),

                            const SizedBox(height: 15),

                            Text(
                              'Do you want to really void this payment?',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white70
                                    : const Color(0xFF656161),
                                fontSize: 16,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w500,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // =========================================================
                // BUTTONS
                // =========================================================

                Padding(
                  padding: const EdgeInsets.only(left: 100),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.of(dialogContext).pop(false);
                            },
                            style: OutlinedButton.styleFrom(
                              backgroundColor: isDark
                                  ? const Color(0xFF2A2F3D)
                                  : const Color(0xFFF7F7F7),
                              foregroundColor: isDark
                                  ? Colors.white
                                  : const Color(0xFF373535),
                              side: BorderSide(
                                color: isDark
                                    ? Colors.white24
                                    : const Color(0xFFD8D8D8),
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(15),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF373535),
                                fontSize: 16,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 20),

                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(dialogContext).pop(true);
                            },
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor:
                              const Color(0xFFFF3B30),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(15),
                              ),
                            ),
                            child: const Text(
                              'Yes, Void',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}