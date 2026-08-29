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
  void initState() {
    super.initState();

    widget.areaNameController.addListener(() {
      if (mounted) setState(() {});
    });
  }
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                width: 340,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF202433)
                      : Colors.white,
                  gradient: isDark
                      ? null
                      : const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFECFFEC),
                      Colors.white,
                    ],
                    stops: [0.35, 1.0],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? Colors.white24
                        : const Color(0xFF1F9724),
                    width: isDark ? 1 : 2,
                  ),
                  boxShadow: isDark
                      ? []
                      : const [
                    BoxShadow(
                      color: Color(0x4C4C5F7D),
                      blurRadius: 10,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF2B3042)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white24
                                  : const Color(0xFF1F9724),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Image.asset(
                              'assets/table_area.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),

                        const SizedBox(width: 14),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              Text(
                                "Create a Area/Zone",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                              SizedBox(height: 4),

                              Text(
                                "Create a zone to organize tables and manage seating",
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white70
                                      : const Color(0xFF6E6E6E),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 5),
                    Text(
                      "Area/Zone",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    SizedBox(height: 5),
                    Container(
                      height: 46,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF2B3042)
                            : const Color(0xFFF6F6F6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? Colors.white24
                              : const Color(0xFFF1F1F1),
                        ),
                        boxShadow: isDark
                            ? []
                            : const [
                          BoxShadow(
                            color: Color(0x26000000),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [

                          Expanded(
                            child: TextField(
                              controller: widget.areaNameController,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: "Type a Area/Zone name",
                                hintStyle: TextStyle(
                                  color: isDark
                                      ? Colors.white54
                                      : const Color(0xFFA19999),
                                  fontSize: 14,
                                ),
                                isDense: true,
                              ),
                            ),
                          ),

                          if (widget.areaNameController.text.isNotEmpty)
                            InkWell(
                              onTap: () {
                                setState(() {
                                  widget.areaNameController.clear();
                                });
                              },
                              child: const Icon(
                                Icons.close,
                                color: Colors.red,
                                size: 20,
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
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        SizedBox(
                          width: 130,
                          height: 40,
                          child: OutlinedButton(
                            onPressed: () {
                              widget.togglePopup();
                            },
                            // onPressed: widget.isLoading
                            //     ? null
                            //     : () {
                            //   setState(() {
                            //     widget.areaNameController.clear();
                            //   });
                            // },
                            style: OutlinedButton.styleFrom(
                              backgroundColor: isDark
                                  ? const Color(0xFF34384F)
                                  : const Color(0xFFF6F6F6),
                              side: BorderSide(
                                color: isDark
                                    ? Colors.white24
                                    : const Color(0xFFC3C3C3),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              "Cancel",
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF535353),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 7),
                        SizedBox(
                          width: 130,
                          height: 40,
                          child: ElevatedButton(
                            onPressed: widget.isLoading ? null : widget.createArea,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1F9724),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                            ),
                            child: widget.isLoading
                                ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                                : const Text(
                              "Create",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
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
            ),
          ),
        ),
      ),
    );
  }
}
