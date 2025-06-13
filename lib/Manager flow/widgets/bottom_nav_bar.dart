import 'package:flutter/material.dart';

/// A customizable bottom navigation bar widget with animated item selection.
///
/// This widget displays a row of text labels representing different navigation items.
/// The selected item is highlighted with a background color and larger horizontal padding.
/// The widget triggers a callback when an item is tapped to notify the parent about the selection.
///
class BottomNavBar extends StatelessWidget {
  /// The index of the currently selected navigation item.
  final int selectedIndex;

  /// Callback fired when a navigation item is tapped.
  /// Provides the index of the tapped item.
  final Function(int) onItemTapped;

  /// Creates a [BottomNavBar] widget.
  ///
  /// Requires [selectedIndex] to indicate the active item,
  /// and [onItemTapped] callback to handle taps.
  BottomNavBar({required this.selectedIndex, required this.onItemTapped});

  /// List of labels shown on the navigation bar.
  final List<String> labels = [
    "Tables",
    "Register",
    "Orders",
    "Customers",
    "Settings",
    "Log Out"
  ];

  @override
  Widget build(BuildContext context) {
    return Positioned(
      // Positioned near the bottom with horizontal padding.
      bottom: 15,
      left: 100,
      right: 100,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 15, horizontal: 6),
        decoration: BoxDecoration(
          // Background color of the nav bar
          color: Color(0xFF0A1B4D),
          borderRadius: BorderRadius.circular(23),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          // Evenly space the navigation items
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(labels.length, (index) {
            // Check if this item is selected
            final bool isSelected = selectedIndex == index;

            return InkWell(
              // Trigger callback on tap with the tapped index
              onTap: () => onItemTapped(index),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                // Animate padding and background color changes smoothly
                duration: Duration(milliseconds: 200),
                padding: isSelected
                    ? EdgeInsets.symmetric(horizontal: 40, vertical: 6)
                    : EdgeInsets.symmetric(horizontal: 15, vertical: 6),
                decoration: isSelected
                    ? BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(15),
                )
                    : null,
                child: Text(
                  labels[index],
                  style: TextStyle(
                    fontSize: 17,
                    fontFamily: 'Inter',
                    color: isSelected ? Colors.white : Colors.grey[300],
                    fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
