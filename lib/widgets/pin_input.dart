import 'package:flutter/material.dart';

class PinInput extends StatelessWidget {
  final String pin;

  const PinInput({super.key, required this.pin});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // no hard width
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(6, (index) {
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              height: 55,
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
                alignment: Alignment(0, 0.2),
                child: Text(
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