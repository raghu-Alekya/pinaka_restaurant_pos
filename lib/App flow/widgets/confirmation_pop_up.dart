import 'package:flutter/material.dart';

class ConfirmationPopup extends StatelessWidget {
  final String title;
  final String message;
  final String? highlightedText;
  final String? trailingMessage;

  final String cancelButtonText;
  final String confirmButtonText;

  final Color primaryColor;
  final Color gradientColor;

  final String imagePath;

  final bool isLoading;

  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const ConfirmationPopup({
    super.key,
    required this.title,
    required this.message,
    this.highlightedText,
    this.trailingMessage,
    this.cancelButtonText = "Cancel",
    this.confirmButtonText = "Confirm",
    this.primaryColor = Colors.red,
    this.gradientColor = const Color(0xFFFCE9E9),
    required this.imagePath,
    required this.isLoading,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return GestureDetector(
      onTap: onCancel,
      child: Material(
        color: Colors.black45,
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: Container(
              width: 556,
              padding: const EdgeInsets.fromLTRB(34, 30, 1, 30),
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
                borderRadius: BorderRadius.circular(16), // smaller curve
                border: Border(
                  top: BorderSide(
                    color: isDark ? primaryColor : primaryColor,
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
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: primaryColor,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Image.asset(
                          imagePath,
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
                              title,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : const Color(0xFF373535),
                              ),
                            ),

                            const SizedBox(height: 10),

                            RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white70
                                      : const Color(0xFF656161),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                                children: [

                                  TextSpan(text: message),

                                  if (highlightedText != null)
                                    TextSpan(
                                      text: highlightedText,
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF373535),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  if (trailingMessage != null)
                                    TextSpan(
                                      text: trailingMessage,
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white70
                                            : const Color(0xFF656161),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
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

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [

                      SizedBox(
                        width: 170,
                        height: 48,
                        child: OutlinedButton(
                          onPressed: isLoading ? null : onCancel,
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
                            cancelButtonText,
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
                          onPressed: isLoading ? null : onConfirm,
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                              : Text(
                            confirmButtonText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
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
      ),
    );
  }
}