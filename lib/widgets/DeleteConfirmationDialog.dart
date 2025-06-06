import 'package:flutter/material.dart';

/// A confirmation dialog widget that prompts the user to confirm deletion of a table within a specific area.
///
/// This dialog displays a warning message with the table and area names highlighted in bold,
/// and provides two action buttons:
/// - **No, Keep It.** to cancel the deletion and close the dialog.
/// - **Yes, Delete!** to confirm the deletion and execute the provided callback before closing the dialog.
///
/// The dialog uses a rounded rectangular shape with custom padding and colors,
/// and includes an image icon at the top for visual emphasis.
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
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      backgroundColor: const Color(0xFFFDFDFD),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      content: SizedBox(
        width: 300,
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
            const Text(
              'Are you sure ?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: const TextStyle(color: Colors.black87),
                children: [
                  const TextSpan(text: 'Do you want to really delete the '),
                  TextSpan(
                    text: tableName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: '? This will be deleted in '),
                  TextSpan(
                    text: areaName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFF1F4F8),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'No, Keep It.',
                    style: TextStyle(color: Color(0xFF4C5F7D)),
                  ),
                ),
                const SizedBox(width: 12),
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFDA4A38),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    onConfirm();
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Yes, Delete!',
                    style: TextStyle(color: Colors.white),
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
