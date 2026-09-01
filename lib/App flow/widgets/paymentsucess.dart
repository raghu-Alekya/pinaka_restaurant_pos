import 'package:flutter/material.dart';
import 'package:pinaka_restaurant_pos/App%20flow/widgets/print_receipt.dart';
import 'package:pinaka_restaurant_pos/blocs/Bloc%20Event/order_event.dart';
import 'package:pinaka_restaurant_pos/blocs/Bloc%20Logic/order_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/payment/payment_summary_model.dart';

class Paymentsucess extends StatelessWidget {
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
    this.isTakeAway = false,
  }) : super(key: key);

  @override
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
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

              _buildInfoRow(context, paymentMode, amount),

              const SizedBox(height: 15),

              _buildChangeRow(context, changeAmount),

              const SizedBox(height: 25),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildActionButton(
                    context,
                    label: 'Void',
                    color: Colors.red.shade400,
                    onTap: () async {
                      final shouldVoid =
                      await _showVoidConfirmation(context);
                      if (shouldVoid == true) {
                        if (!context.mounted) return;
                        Navigator.pop(context, "void");
                      }
                    },
                  ),

                  const SizedBox(width: 30),

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
                                loadedTables: loadedTables,
                                pin: pin,
                                token: token,
                                restaurantId: restaurantId,
                                restaurantName: restaurantName,
                                zoneId: zoneId,
                                paymentSummary: paymentSummary,
                                cashierName: cashierName,
                                isTakeAway: isTakeAway,
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
                  ? const Color(0xFF498FFF) // Dark mode
                  : theme.colorScheme.onSurface, // Light mode
            ),
          ),

          Text(
            "₹$formattedAmount",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: isDark
                  ? const Color(0xFF498FFF) // Dark mode
                  : theme.colorScheme.onSurface, // Light mode
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChangeRow(BuildContext context, String? change) {
    debugPrint("🟢 Change received in UI = $change");

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

  Future<bool?> _showVoidConfirmation(BuildContext context) {
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
          insetPadding: const EdgeInsets.symmetric(horizontal: 30),
          child: Container(
            width: 500,
            constraints: const BoxConstraints(maxWidth: 556),
            padding: const EdgeInsets.fromLTRB(30, 30, 30, 30),
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
                // ============================================================
                // ICON + TITLE + MESSAGE
                // ============================================================
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

                // ============================================================
                // BUTTONS
                // Starts aligned with the text, not the warning icon
                // ============================================================
                Padding(
                  padding: const EdgeInsets.only(left: 100),
                  child: Row(
                    children: [
                      // ------------------------------------------------------
                      // CANCEL
                      // ------------------------------------------------------
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.of(
                                dialogContext,
                              ).pop(false);
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
                              padding: EdgeInsets.zero,
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

                      // ------------------------------------------------------
                      // VOID
                      // ------------------------------------------------------
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(
                                dialogContext,
                              ).pop(true);
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
                              padding: EdgeInsets.zero,
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