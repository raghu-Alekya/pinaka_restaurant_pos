import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  BottomNavBar({required this.selectedIndex, required this.onItemTapped});

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
      bottom: 28,
      left: 140,
      right: 140,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 18, horizontal: 10),
        decoration: BoxDecoration(
          color: Color(0xFF0A1B4D),
          borderRadius: BorderRadius.circular(25),
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
                padding: isSelected
                    ? EdgeInsets.symmetric(horizontal: 50, vertical: 10)
                    : EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: isSelected
                    ? BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(15),
                )
                    : null,
                child: Text(
                  labels[index],
                  style: TextStyle(
                    fontSize: 20,
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