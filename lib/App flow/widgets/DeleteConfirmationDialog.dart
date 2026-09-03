import 'package:flutter/material.dart';

class DeleteConfirmationDialog extends StatelessWidget {
  final String tableName;
  final String areaName;
  final VoidCallback onConfirm;

  const DeleteConfirmationDialog({
    super.key,
    required this.tableName,
    required this.areaName,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    const primaryColor = Color(0xFFDA4A38);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        width: 520,
        padding: const EdgeInsets.fromLTRB(34, 30, 30, 30),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors:
                isDark
                    ? const [Color(0xFF46333A), Color(0xFF202433)]
                    : const [Color(0xFFEFCDCD), Colors.white],
          ),
          borderRadius: BorderRadius.circular(16),
          border: const Border(top: BorderSide(color: primaryColor, width: 4)),
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2A2F3D) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: primaryColor),
                  ),
                  child: Image.asset(
                    'assets/check-broken.png',
                    width: 38,
                    height: 38,
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(width: 18),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Are you sure?',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color:
                              isDark ? Colors.white : const Color(0xFF373535),
                        ),
                      ),

                      const SizedBox(height: 10),

                      RichText(
                        text: TextSpan(
                          style: TextStyle(
                            color:
                                isDark
                                    ? Colors.white70
                                    : const Color(0xFF656161),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          children: [
                            const TextSpan(
                              text: 'Do you really want to delete ',
                            ),

                            TextSpan(
                              text: tableName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color:
                                    isDark
                                        ? Colors.white
                                        : const Color(0xFF373535),
                              ),
                            ),

                            const TextSpan(
                              text: '? This table will be deleted from ',
                            ),

                            TextSpan(
                              text: areaName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color:
                                    isDark
                                        ? Colors.white
                                        : const Color(0xFF373535),
                              ),
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
                        backgroundColor:
                            isDark
                                ? const Color(0xFF2A2F3D)
                                : const Color(0xFFF6F6F6),
                        side: BorderSide(color: theme.dividerColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'No, Keep It.',
                        style: TextStyle(
                          color:
                              isDark ? Colors.white : const Color(0xFF373535),
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
                      onPressed: () {
                        Navigator.of(context).pop();

                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          onConfirm();
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Yes, Delete!',
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
