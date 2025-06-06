import 'package:flutter/material.dart';

/// A modal popup widget that displays a delete confirmation dialog.
///
/// This widget overlays a semi-transparent dark background and shows a centered
/// dialog asking the user to confirm deletion of a record, specifically referring
/// to the current area name if provided.
///
/// The dialog presents two action buttons:
/// - **No, Keep It.** — cancels the deletion and closes the popup.
/// - **Yes, Delete!** — confirms the deletion and triggers the provided callback.
///
/// The popup is only visible when [isVisible] is true; otherwise, it renders nothing.
///
/// The popup dismisses if the user taps outside the dialog area.
///
/// The UI includes an icon, title text, descriptive rich text referencing the [currentAreaName],
/// and two buttons styled with rounded corners and shadows.
///
class DeleteConfirmationPopup extends StatelessWidget {
  /// Whether the popup is visible on screen.
  final bool isVisible;

  /// The name of the current area to display in the confirmation message.
  /// If null, a default text "this area." is shown.
  final String? currentAreaName;

  /// Callback when the user cancels the deletion.
  final VoidCallback onCancel;

  /// Callback when the user confirms the deletion.
  final VoidCallback onDelete;

  /// Creates a [DeleteConfirmationPopup] widget.
  const DeleteConfirmationPopup({
    Key? key,
    required this.isVisible,
    required this.currentAreaName,
    required this.onCancel,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return SizedBox.shrink();

    return GestureDetector(
      onTap: onCancel,
      child: Container(
        color: Colors.black.withAlpha(80),
        child: Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.22,
            height: MediaQuery.of(context).size.height * 0.33,
            decoration: ShapeDecoration(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Center(
                    child: Image.asset(
                      'assets/check-broken.png',
                      width: 50,
                      height: 30,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Are you sure ?',
                    style: TextStyle(
                      color: Color(0xFF373535),
                      fontSize: 16,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.bold,
                      height: 1.57,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: 383,
                    child: Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(
                            text:
                            'Do you want to really delete the records? This will delete ',
                            style: TextStyle(
                              color: Color(0xFFA19999),
                              fontSize: 12,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w500,
                              height: 1.38,
                            ),
                          ),
                          TextSpan(
                            text: currentAreaName ?? 'this area.',
                            style: const TextStyle(
                              color: Color(0xFF656161),
                              fontSize: 10,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                              height: 1.38,
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: onCancel,
                        child: Container(
                          width: 80,
                          height: 32,
                          decoration: ShapeDecoration(
                            color: const Color(0xFFF6F6F6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            shadows: const [
                              BoxShadow(
                                color: Color(0x19000000),
                                blurRadius: 4,
                                offset: Offset(0, 1),
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'No, Keep It.',
                            style: TextStyle(
                              color: Color(0xFF4C5F7D),
                              fontSize: 11,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w500,
                              height: 1.10,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 25),
                      GestureDetector(
                        onTap: onDelete,
                        child: Container(
                          width: 80,
                          height: 32,
                          decoration: ShapeDecoration(
                            color: const Color(0xFFFD6464),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            shadows: const [
                              BoxShadow(
                                color: Color(0x19000000),
                                blurRadius: 4,
                                offset: Offset(0, 1),
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'Yes, Delete!',
                            style: TextStyle(
                              color: Color(0xFFF9F6F6),
                              fontSize: 11,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w500,
                              height: 1.10,
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
