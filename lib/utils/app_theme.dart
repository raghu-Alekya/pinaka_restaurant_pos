import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF0F1F5),
    cardColor: Colors.white,
    dividerColor: Colors.grey.shade300,
    shadowColor: Colors.black12,
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF173F7A),
      secondary: Color(0xFFF5A25D),
      surface: Colors.white,
      onSurface: Color(0xFF23263A),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF202433),
    cardColor: const Color(0xFF2A2F45),
    dividerColor: const Color(0xFF3E455C),
    shadowColor: Colors.black54,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF173F7A),
      secondary: Color(0xFFF5A25D),
      surface: Color(0xFF2A2F45),
      onSurface: Colors.white,
    ),
  );
}
class AppColors {
  static Color bg(BuildContext context) =>
      Theme.of(context).scaffoldBackgroundColor;

  static Color card(BuildContext context) =>
      Theme.of(context).cardColor;

  static Color text(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;

  static Color border(BuildContext context) =>
      Theme.of(context).dividerColor;

  static Color shadow(BuildContext context) =>
      Theme.of(context).shadowColor;
}