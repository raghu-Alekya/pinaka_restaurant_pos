import 'package:flutter/material.dart';

/// A popup widget that allows the user to create a new Area or Zone.
///
/// This widget includes:
/// - A text field for entering the name of the area
/// - Validation and display of duplicate area name errors
/// - Buttons to clear the input or create the area
/// - A close button to dismiss the popup
///
/// The popup is displayed centered on the screen with a translucent black background.
/// It also adjusts for the keyboard by using `MediaQuery.of(context).viewInsets.bottom`.

class AreaPopup extends StatefulWidget {
  /// Controller for the area name input field
  final TextEditingController areaNameController;

  /// Flag to indicate whether the entered area name is a duplicate
  final bool isDuplicateName;

  /// Error message to show when the area name is duplicate
  final String errorMessage;

  /// Callback function to close the popup
  final VoidCallback togglePopup;

  /// Callback function to create a new area
  final VoidCallback createArea;

  final bool isLoading;

  const AreaPopup({
    Key? key,
    required this.areaNameController,
    required this.isDuplicateName,
    required this.errorMessage,
    required this.togglePopup,
    required this.createArea,
    required this.isLoading,
  }) : super(key: key);

  @override
  _AreaPopupState createState() => _AreaPopupState();
}

/// State class for `AreaPopup` that handles user interactions, validation,
/// and UI building for area name input and creation.
class _AreaPopupState extends State<AreaPopup> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.togglePopup,
      child: Container(
        color: Colors.black.withAlpha(100), // Translucent background
        child: Center(
          child: GestureDetector(
            onTap: () {}, // Prevent popup dismissal on tap inside
            behavior: HitTestBehavior.translucent,
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom, // Adjust for keyboard
              ),
              child: Container(
                width: 280,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 5),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        Align(
                          alignment: Alignment.center,
                          child: Padding(
                            padding: const EdgeInsets.only(
                              top: 25,
                              right: 25,
                              bottom: 20,
                            ),
                            child: Text(
                              "Let’s Create an Area/Zone",
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: GestureDetector(
                            onTap: widget.togglePopup,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Color(0xFFF86157),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0x3F000000),
                                    blurRadius: 11,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 5),
                    Text(
                      "Area/Zone",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(height: 5),
                    Container(
                      height: 45,
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Color(0xFFECEBEB)),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [BoxShadow(color: Color(0x19000000))],
                      ),
                      child: Row(
                        children: [
                          SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: widget.areaNameController,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Type an Area/Zone name',
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 5),
                    if (widget.isDuplicateName)
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 4.0,
                          bottom: 6,
                        ),
                        child: Text(
                          widget.errorMessage,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFDA4A38),
                          ),
                        ),
                      ),
                    SizedBox(height: 7),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          onPressed: widget.isLoading ? null : () {
                            setState(() {
                              widget.areaNameController.clear();
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[100],
                            foregroundColor: Color(0xFF4C5F7D),
                            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 3),
                            minimumSize: Size(0, 30),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text("Clear", style: TextStyle(fontSize: 12)),
                        ),
                        SizedBox(width: 7),
                        ElevatedButton(
                          onPressed: widget.isLoading ? null : widget.createArea,
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.resolveWith<Color>(
                                  (Set<WidgetState> states) {
                                return Colors.red;
                              },
                            ),
                            foregroundColor: WidgetStateProperty.all<Color>(Colors.white),
                            padding: WidgetStateProperty.all<EdgeInsets>(
                              const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
                            ),
                            minimumSize: WidgetStateProperty.all<Size>(const Size(0, 30)),
                            shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                          child: widget.isLoading
                              ? const SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                              backgroundColor: Colors.transparent,
                            ),
                          )
                              : const Text(
                            "Create",
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
      ),
    );
  }
}
