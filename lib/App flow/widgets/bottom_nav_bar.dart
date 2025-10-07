import 'package:flutter/material.dart';
import '../../models/UserPermissions.dart';
import 'area_movement_notifier.dart';

class BottomNavBar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final UserPermissions? userPermissions;

  const BottomNavBar({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.userPermissions,
  }) : super(key: key);

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  final ScrollController _scrollController = ScrollController();

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

  void _scrollLeft() {
    _scrollController.animateTo(
      _scrollController.offset - 120,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  void _scrollRight() {
    _scrollController.animateTo(
      _scrollController.offset + 120,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

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
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_left, color: Colors.white),
              onPressed: _scrollLeft,
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(items.length, (index) {
                    final isSelected = widget.selectedIndex == index;

                    return InkWell(
                      onTap: () {
                        // permission check example
                        if (items[index]["label"] == "Dashboard" &&
                            (widget.userPermissions?.canAccessDashboard ?? true) == false) {
                          AreaMovementNotifier.showPopup(
                            context: context,
                            fromArea: '',
                            toArea: '',
                            tableName: 'Dashboard',
                            customMessage: 'You don’t have permission to access Dashboard',
                          );
                          return;
                        }

                        widget.onItemTapped(index);
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
                                fontSize: 14,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFFC4C7D1),
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
            ),
            IconButton(
              icon: const Icon(Icons.arrow_right, color: Colors.white),
              onPressed: _scrollRight,
            ),
          ],
        ),
      ),
    );
  }
}
