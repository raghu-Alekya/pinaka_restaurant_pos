import 'package:flutter/material.dart';

/// A customizable numeric keypad widget.
class NumberPad extends StatelessWidget {
  final Function(String) onKeyPressed;

  const NumberPad({super.key, required this.onKeyPressed});

  @override
  Widget build(BuildContext context) {
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
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                keyLabel,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF4C5F7D),
                  height: 0.35,
                ),
              ),
            )
                : Text(
              keyLabel,
              style: const TextStyle(
                fontSize: 30,
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