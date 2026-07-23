import 'package:flutter/material.dart';

class PinInput extends StatelessWidget {
  final String pin;

  const PinInput({super.key, required this.pin});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(6, (index) {
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              height: 45,
              width: 65,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2A2F3D)
                    : Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isDark
                      ? Colors.white24
                      : Colors.transparent,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black38
                        : const Color(0x23000000),
                    blurRadius: 7,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Align(
                alignment: const Alignment(0, 0.2),
                child: Text(
                  index < pin.length ? "*" : "",
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontSize: 35,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? Colors.white
                        : const Color(0xFF191919),
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