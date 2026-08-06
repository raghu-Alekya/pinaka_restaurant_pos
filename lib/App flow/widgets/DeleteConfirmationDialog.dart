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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      backgroundColor: isDark
          ? const Color(0xFF202433)
          : Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 16,
      ),
      content: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Image.asset(
                'assets/check-broken.png',
                width: 70,
                height: 50,
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(height: 16),

            Text(
              'Are you sure ?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? Colors.white
                    : const Color(0xFF373535),
              ),
            ),

            const SizedBox(height: 12),

            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(
                  color: isDark
                      ? Colors.white70
                      : Colors.black87,
                  fontSize: 14,
                ),
                children: [
                  const TextSpan(
                    text: 'Do you want to really delete the ',
                  ),
                  TextSpan(
                    text: tableName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? Colors.white
                          : Colors.black87,
                    ),
                  ),
                  const TextSpan(
                    text: '? This will be deleted in ',
                  ),
                  TextSpan(
                    text: areaName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? Colors.white
                          : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: isDark
                          ? const Color(0xFF34384F)
                          : const Color(0xFFF1F4F8),
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: isDark
                              ? Colors.white24
                              : Colors.transparent,
                        ),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      'No, Keep It.',
                      style: TextStyle(
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF4C5F7D),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFFDA4A38),
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        onConfirm();
                      });
                    },
                    child: const Text(
                      'Yes, Delete!',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
