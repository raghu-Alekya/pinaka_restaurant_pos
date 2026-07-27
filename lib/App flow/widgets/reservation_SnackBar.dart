import 'package:flutter/material.dart';

class AppSnackBar {
  static void show(
      BuildContext context, {
        required String message,
        required bool success,
      }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: success ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.fixed, // Normal snackbar
          duration: const Duration(seconds: 2),
        ),
      );
  }
}