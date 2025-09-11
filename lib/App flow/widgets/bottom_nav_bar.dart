import 'package:flutter/material.dart';

import '../../models/UserPermissions.dart';
import 'area_movement_notifier.dart';

class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final UserPermissions? userPermissions;

  BottomNavBar({
    required this.selectedIndex,
    required this.onItemTapped,
    required this.userPermissions,
  });

  final List<Map<String, dynamic>> items = [
    {"label": "Dashboard", "icon": Icons.dashboard},
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
              onTap: () {
                if (items[index]["label"] == "Dashboard" &&
                    (userPermissions?.canAccessDashboard ?? false) == false) {
                  AreaMovementNotifier.showPopup(
                    context: context,
                    fromArea: '',
                    toArea: '',
                    tableName: 'Dashboard',
                    customMessage: 'You don’t have permissions to access Dashboard',
                  );
                  return;
                }
                onItemTapped(index);
              },
              child: Container(
                height: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFDA4A38)
                      : const Color(0xFF2A3558),
                ),
                child: Row(
                  children: [
                    Icon(
                      items[index]["icon"],
                      size: 20,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFFC4C7D1),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      items[index]["label"],
                      style: TextStyle(
                        fontSize: 16,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFFC4C7D1),
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
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