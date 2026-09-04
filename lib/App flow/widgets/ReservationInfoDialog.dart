import 'package:flutter/material.dart';

class ReservationInfoDialog extends StatelessWidget {
  final String reservationDate;
  final String reservationTime;
  final VoidCallback onOk;

  const ReservationInfoDialog({
    super.key,
    required this.reservationDate,
    required this.reservationTime,
    required this.onOk,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    const primaryColor = Color(0xFFF86157);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: 520,
        padding: const EdgeInsets.fromLTRB(34, 30, 30, 30),
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
              Color(0xFFEFCDCD),
              Colors.white,
            ],
          ),
          borderRadius: BorderRadius.circular(16),

          // Same top border as ConfirmationPopup
          border: const Border(
            top: BorderSide(
              color: primaryColor,
              width: 4,
            ),
          ),

          boxShadow: const [
            BoxShadow(
              color: Color(0x334C5F7D),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),

        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // =====================================================
            // ICON + CONTENT
            // =====================================================
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ICON CONTAINER
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2A2F3D)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: primaryColor,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Image.asset(
                    'assets/info.png',
                    width: 38,
                    height: 38,
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(width: 18),

                // =================================================
                // TEXT CONTENT
                // =================================================
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Table Reserved',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF373535),
                        ),
                      ),

                      const SizedBox(height: 10),

                      RichText(
                        textAlign: TextAlign.start,
                        text: TextSpan(
                          style: TextStyle(
                            color: isDark
                                ? Colors.white70
                                : const Color(0xFF656161),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                          ),
                          children: [
                            const TextSpan(
                              text: 'This table is reserved until ',
                            ),

                            TextSpan(
                              text: reservationDate,
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF373535),
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const TextSpan(text: ' at '),

                            TextSpan(
                              text: reservationTime,
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF373535),
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const TextSpan(
                              text:
                              '.\nWould you like to continue with the order?',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // =====================================================
            // BUTTONS
            //
            // Padding left = icon width + gap
            // This makes buttons start where text starts
            // =====================================================
            Padding(
              padding: const EdgeInsets.only(left: 90),
              child: Row(
                children: [
                  SizedBox(
                    width: 170,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: isDark
                            ? const Color(0xFF2A2F3D)
                            : const Color(0xFFF6F6F6),
                        side: BorderSide(
                          color: theme.dividerColor,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF373535),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  SizedBox(
                    width: 170,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: onOk,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'OK',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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
  }
}