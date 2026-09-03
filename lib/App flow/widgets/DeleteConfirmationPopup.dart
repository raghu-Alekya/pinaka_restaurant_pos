import 'package:flutter/material.dart';

class DeleteConfirmationPopup extends StatelessWidget {
  final bool isVisible;
  final String? currentAreaName;
  final VoidCallback onCancel;
  final VoidCallback onDelete;

  const DeleteConfirmationPopup({
    super.key,
    required this.isVisible,
    required this.currentAreaName,
    required this.onCancel,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    const primaryColor = Color(0xFFFD6464);

    return GestureDetector(
      onTap: onCancel,
      child: Material(
        color: Colors.black45,
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: Container(
              width: 420,
              padding: const EdgeInsets.fromLTRB(30, 30, 30, 30),
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
                border: const Border(
                  top: BorderSide(color: primaryColor, width: 4),
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
                  // Icon + Content
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color:
                              isDark ? const Color(0xFF2A2F3D) : Colors.white,
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
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color:
                                    isDark
                                        ? Colors.white
                                        : const Color(0xFF373535),
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
                                    text:
                                        'Do you really want to delete the records? This will delete ',
                                  ),

                                  TextSpan(
                                    text: currentAreaName ?? 'this area.',
                                    style: TextStyle(
                                      color:
                                          isDark
                                              ? Colors.white
                                              : const Color(0xFF373535),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
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

                  const SizedBox(height: 15),

                  // Buttons
                  Padding(
                    padding: const EdgeInsets.only(left: 70),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 130,
                          height: 48,
                          child: OutlinedButton(
                            onPressed: onCancel,
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
                                    isDark
                                        ? Colors.white
                                        : const Color(0xFF373535),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 14),

                        SizedBox(
                          width: 130,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: onDelete,
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
                                fontSize: 14,
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
