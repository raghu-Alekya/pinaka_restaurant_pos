import 'package:flutter/material.dart';
import '../../models/UserPermissions.dart';
import 'area_movement_notifier.dart';

class BottomNavBar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final UserPermissions? userPermissions;

  const BottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.userPermissions,
  });

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> items = const [
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
      _scrollController.offset - 150,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _scrollRight() {
    _scrollController.animateTo(
      _scrollController.offset + 150,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final totalWidth = items.length * 200; // approximate item width
            final needsScroll = totalWidth > constraints.maxWidth;

            return Stack(
              children: [
                // 🔹 Scrollable Row
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: needsScroll ? 40 : 0),
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    physics: needsScroll
                        ? const BouncingScrollPhysics()
                        : const NeverScrollableScrollPhysics(),
                    child: Row(
                      mainAxisAlignment: needsScroll
                          ? MainAxisAlignment.start
                          : MainAxisAlignment.spaceEvenly,
                      children: List.generate(items.length * 2 - 1, (i) {
                        if (i.isOdd) {
                          // Divider between items
                          return Container(
                            width: 1,
                            height: 15,
                            margin: const EdgeInsets.symmetric(horizontal: 8), // 👈 add spacing between dividers
                            color: Colors.white.withOpacity(0.6),
                          );
                        }

                        final index = i ~/ 2;
                        final isSelected = widget.selectedIndex == index;

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4), // 👈 add space around each item
                          child: InkWell(
                            onTap: () {
                              if (items[index]["label"] == "Dashboard" &&
                                  (widget.userPermissions?.canAccessDashboard ?? false) == false) {
                                AreaMovementNotifier.showPopup(
                                  context: context,
                                  fromArea: '',
                                  toArea: '',
                                  tableName: 'Dashboard',
                                  customMessage:
                                  'You don’t have permissions to access Dashboard',
                                );
                                return;
                              }
                              widget.onItemTapped(index);
                            },
                            child: Container(
                              height: 55,
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFDA4A38)
                                    : const Color(0xFF2A3558),
                                borderRadius: BorderRadius.circular(4),
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
                                  const SizedBox(width: 8),
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
                          ),
                        );
                      }),
                    ),
                  ),
                ),

                // 👈 Left arrow overlay
                if (needsScroll)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 35,
                      color: const Color(0xFF0A1B4D),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new,
                            color: Colors.white, size: 18),
                        onPressed: _scrollLeft,
                      ),
                    ),
                  ),

                // 👉 Right arrow overlay
                if (needsScroll)
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 35,
                      color: const Color(0xFF0A1B4D),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_forward_ios,
                            color: Colors.white, size: 18),
                        onPressed: _scrollRight,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
