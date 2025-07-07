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
    "Dashboard",
    "Tables",
    "Kitchen Status",
    "Reservation List",
    "Orders List",
    "Customers",
  ];

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 15,
      left: 15,
      right: 15,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(
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
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(labels.length, (index) {
            final bool isSelected = selectedIndex == index;

            return InkWell(
              onTap: () => onItemTapped(index),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
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
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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