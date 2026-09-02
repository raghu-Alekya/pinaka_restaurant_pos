import 'package:flutter/material.dart';

class LogoutConfirmationDialog extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const LogoutConfirmationDialog({
    super.key,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    const Color primaryColor = Color(0xFFF86157);

    return GestureDetector(
      onTap: onCancel,
      child: Material(
        color: Colors.black45,
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: Container(
              width: 520,
              margin: const EdgeInsets.symmetric(horizontal: 20),
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
                  // Icon and content
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Warning icon container
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

                      // Text content
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Logout Confirmation',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF373535),
                                ),
                              ),

                              const SizedBox(height: 10),

                              Text(
                                'Are you sure you want to logout and clear '
                                    'session data?',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white70
                                      : const Color(0xFF656161),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Buttons aligned with text
                  Padding(
                    padding: const EdgeInsets.only(left: 90),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 170,
                          height: 48,
                          child: OutlinedButton(
                            onPressed: onCancel,
                            style: OutlinedButton.styleFrom(
                              elevation: 0,
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
                            onPressed: onConfirm,
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Logout',
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
          ),
        ),
      ),
    );
  }
}