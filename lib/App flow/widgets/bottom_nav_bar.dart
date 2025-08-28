import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  BottomNavBar({required this.selectedIndex, required this.onItemTapped});

  final List<Map<String, dynamic>> items = [
    {"label": "Tables", "icon": Icons.table_bar},
    {"label": "KOT Status", "icon": Icons.receipt_long},
    {"label": "Reservation", "icon": Icons.calendar_month},
    {"label": "Orders", "icon": Icons.list_alt},
    {"label": "Customers", "icon": Icons.people},
    {"label": "Take Aways", "icon": Icons.inventory_2},
    {"label": "Online Orders", "icon": Icons.delivery_dining},
  ];

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 55,
        color: const Color(0xFF0A1B4D),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(items.length * 2 - 1, (i) {
            if (i.isOdd) {
              return Container(
                width: 1,
                height: 15,
                color: Colors.white,
              );
            }
            final index = i ~/ 2;
            final isSelected = selectedIndex == index;
            return InkWell(
              onTap: () => onItemTapped(index),
              child: Container(
                height: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 30),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Color(0xFFDA4A38)
                      : const Color(0xFF2A3558),
                ),
                child: Row(
                  children: [
                    Icon(
                      items[index]["icon"],
                      size: 20,
                      color: isSelected ? Colors.white : const Color(0xFFC4C7D1),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      items[index]["label"],
                      style: TextStyle(
                        fontSize: 18,
                        color: isSelected ? Colors.white : const Color(0xFFC4C7D1),
                        fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}