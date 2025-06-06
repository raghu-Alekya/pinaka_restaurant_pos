import 'package:flutter/material.dart';

/// A customizable numeric keypad widget.
/// Displays keys 0-9, a clear ("C") button, and a backspace ("⌫") button.
/// Calls [onKeyPressed] callback with the label of the key pressed.
class NumberPad extends StatelessWidget {
  /// Callback invoked when a key is pressed, providing the key label as a string.
  final Function(String) onKeyPressed;

  /// Creates a NumberPad widget.
  /// Requires [onKeyPressed] to handle key presses.
  const NumberPad({super.key, required this.onKeyPressed});

  @override
  Widget build(BuildContext context) {
    // List of keys to display on the keypad
    List<String> keys = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "C", "0", "⌫"];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.9,
      ),
      itemCount: keys.length,
      itemBuilder: (context, index) {
        final keyLabel = keys[index];
        return GestureDetector(
          onTap: () => onKeyPressed(keyLabel),
          child: Container(
            margin: const EdgeInsets.all(9),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: const Color(0x25000000),
                  blurRadius: 7,
                  offset: const Offset(0, 4),
                  spreadRadius: 0,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: keyLabel == "⌫"
                ? Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Text(
                keyLabel,
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF4C5F7D),
                  height: 0.35,
                ),
              ),
            )
                : Text(
              keyLabel,
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w500,
                color: Color(0xFF4C5F7D),
                height: 0.35,
              ),
            ),
          ),
        );
      },
    );
  }
}
