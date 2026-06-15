import 'package:flutter/material.dart';
import 'package:kds_app/widgets/completed_orders.dart';

import 'active_orderscreen.dart';
import 'kitchen_display_screen.dart';

enum OrderTypeFilter {
  all,
  dineIn,
  takeaway,
  online,
}

enum KotView {
  pending,
  active,
  history,
}

class TopBarWidget extends StatelessWidget {
  final OrderTypeFilter selectedFilter;
  final KotView selectedView;

  final ValueChanged<OrderTypeFilter> onFilterChanged;
  final ValueChanged<KotView> onViewChanged;

  const TopBarWidget({
    super.key,
    required this.selectedFilter,
    required this.selectedView,
    required this.onFilterChanged,
    required this.onViewChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 10,
      ),
      color: const Color(0xfff4f4f4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.08),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Row(
              children: [
                _filterButton(
                  title: "All",
                  selected:
                  selectedFilter == OrderTypeFilter.all,
                  onTap: () =>
                      onFilterChanged(OrderTypeFilter.all),
                ),

                _filterButton(
                  title: "Dine-In",
                  selected:
                  selectedFilter == OrderTypeFilter.dineIn,
                  icon: Icons.restaurant,
                  iconColor: Colors.orange,
                  onTap: () =>
                      onFilterChanged(OrderTypeFilter.dineIn),
                ),

                _filterButton(
                  title: "Takeaways",
                  selected: selectedFilter ==
                      OrderTypeFilter.takeaway,
                  icon: Icons.shopping_bag_outlined,
                  iconColor: Colors.blueGrey,
                  onTap: () => onFilterChanged(
                      OrderTypeFilter.takeaway),
                ),

                _filterButton(
                  title: "Online Orders",
                  selected:
                  selectedFilter == OrderTypeFilter.online,
                  icon: Icons.delivery_dining,
                  iconColor: Colors.green,
                  onTap: () =>
                      onFilterChanged(OrderTypeFilter.online),
                ),
              ],
            ),
          ),

          const Spacer(),

          Container(
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.teal,
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ActiveOrdersScreen(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 25,
                    ),
                    decoration: BoxDecoration(
                      color: selectedView == KotView.active
                          ? Colors.teal
                          : Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(7),
                        bottomLeft: Radius.circular(7),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "Active KOT's",
                      style: TextStyle(
                        color: selectedView == KotView.active
                            ? Colors.white
                            : Colors.teal,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                GestureDetector(
                  onTap: () {
                    onViewChanged(KotView.pending);

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const KitchenDashboardScreen(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                    ),
                    decoration: BoxDecoration(
                      color: selectedView == KotView.pending
                          ? Colors.teal
                          : Colors.white,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "Pending KOT's",
                      style: TextStyle(
                        color: selectedView == KotView.pending
                            ? Colors.white
                            : Colors.teal,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 20),

          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CompletedOrdersScreen(
                    token: '',
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Row(
              children: [
                Text(
                  "KOT's History",
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward,
                  color: Colors.white,
                  size: 18,
                )
              ],
            ),
          ),

          const SizedBox(width: 20),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  child: Icon(Icons.person),
                ),
                SizedBox(width: 10),
                Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  mainAxisAlignment:
                  MainAxisAlignment.center,
                  children: [
                    Text(
                      "Madhuri Thota",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      "Head Chef",
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterButton({
    required String title,
    required bool selected,
    required VoidCallback onTap,
    IconData? icon,
    Color? iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xff2F4376)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            if (icon != null)
              Icon(
                icon,
                size: 16,
                color: iconColor,
              ),
            if (icon != null)
              const SizedBox(width: 4),
            Text(
              title,
              style: TextStyle(
                color: selected
                    ? Colors.white
                    : Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}