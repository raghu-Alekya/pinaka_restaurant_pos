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
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFEFCDCD),
                    Colors.white,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: const Border(
                  top: BorderSide(color: Color(0xFFD83434), width: 4),
                  left: BorderSide(color: Color(0xFFD83434), width: 0.1),
                  right: BorderSide(color: Color(0xFFD83434), width: 0.1),
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
                          color: Colors.white,
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
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF373535),
                              ),
                            ),

                            const SizedBox(height: 10),

                            RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  color: Color(0xFF656161),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                                children: [

                                  TextSpan(text: message),

                                  if (highlightedText != null)
                                    TextSpan(
                                      text: highlightedText,
                                      style: const TextStyle(
                                        color: Color(0xFF373535), // Same as normal text
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  if (trailingMessage != null)
                                    TextSpan(
                                      text: trailingMessage,
                                      style: const TextStyle(
                                        color: Color(0xFF656161),
                                        fontWeight: FontWeight.w600,
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
                            backgroundColor: const Color(0xFFF6F6F6),
                            side: const BorderSide(
                              color: Color(0xFFC3C3C3),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            cancelButtonText,
                            style: const TextStyle(
                              color: Color(0xFF535353),
                              fontWeight: FontWeight.w600,
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