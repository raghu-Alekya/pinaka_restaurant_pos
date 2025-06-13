import 'package:flutter/material.dart';

/// A placeholder widget displayed when no table setups exist.
/// Shows a friendly message prompting the user to create their first table setup.
/// Provides basic instructions about customizing table size, shape, and seating capacity.
class EmptyAreaPlaceholder extends StatelessWidget {
  const EmptyAreaPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 30.0,
        vertical: 6.0,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: const [
          SizedBox(height: 15),
          Text(
            "Let’s Set the Table!",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10),
          Text(
            "Start by creating your first table setup to manage your restaurant floor with ease. Customize table size, shape, and seating capacity based on your layout.",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF4C5F7D),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}