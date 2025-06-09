import 'package:flutter/material.dart';

/// A widget to display a 6-digit PIN input field.
/// Shows each digit as a masked character ("*") when entered.
/// Empty digits are represented as empty boxes.
///
/// The [pin] string holds the current entered PIN.
class PinInput extends StatelessWidget {
  /// The current PIN string entered by the user.
  final String pin;

  /// Creates a PinInput widget.
  /// Requires a [pin] string which may have 0 to 6 characters.
  const PinInput({super.key, required this.pin});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // The row contains 6 equally spaced input boxes
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(6, (index) {
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              height: 45,
              width: 65,
              clipBehavior: Clip.antiAlias,
              decoration: ShapeDecoration(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                shadows: [
                  BoxShadow(
                    color: const Color(0x23000000),
                    blurRadius: 7,
                    offset: const Offset(0, 4),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Align(
                alignment: const Alignment(0, 0.2),
                child: Text(
                  // Display "*" for filled positions, empty string otherwise
                  index < pin.length ? "*" : "",
                  style: const TextStyle(
                    color: Color(0xFF191919),
                    fontSize: 35,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                    height: 0.46,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}