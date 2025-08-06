import 'package:flutter/material.dart';

enum FoodFilter { all, veg, nonVeg }

class FoodTypeToggle extends StatelessWidget {
  final FoodFilter selectedFilter;
  final Function(FoodFilter) onFilterChanged;

  const FoodTypeToggle({
    Key? key,
    required this.selectedFilter,
    required this.onFilterChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView( // Makes Row scrollable if needed
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterButton("All", null, selectedFilter == FoodFilter.all, () {
            onFilterChanged(FoodFilter.all);
          }),
          const SizedBox(width: 6),
          _buildFilterButton(
              "Veg", 'assets/icon/veg_icon.png', selectedFilter == FoodFilter.veg, () {
            onFilterChanged(FoodFilter.veg);
          }),
          const SizedBox(width: 6),
          _buildFilterButton("Nv", 'assets/icon/nonveg_icon.png',
              selectedFilter == FoodFilter.nonVeg, () {
                onFilterChanged(FoodFilter.nonVeg);
              }),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label, String? iconPath, bool isSelected,
      VoidCallback onTap) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFFCDFDC) : Colors.white,
        border: Border.all(
          color: isSelected ? const Color(0xFFDA4A38) : Colors.grey.shade400,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (iconPath != null) ...[
              Image.asset(iconPath, width: 16, height: 16),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? const Color(0xFFDA4A38) : Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
