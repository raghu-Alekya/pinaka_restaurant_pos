import 'package:flutter/material.dart';
import '../../../../constants/color_constants.dart';

class MiniSubcategoryFilter extends StatelessWidget {
  final List<String> names; // e.g. ['Idly', 'Dosa', 'Pongal', 'Vada']
  final String selected; // 'All' or one of `names`
  final ValueChanged<String> onSelected;

  const MiniSubcategoryFilter({
    Key? key,
    required this.names,
    required this.selected,
    required this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Show first 3 inline, collapse the rest behind "More".
    const visibleCount = 3;
    final visible = names.take(visibleCount).toList();
    final overflow = names.skip(visibleCount).toList();

    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _chip(context, 'All'),
          const SizedBox(width: 8),
          for (final name in visible) ...[
            _chip(context, name),
            const SizedBox(width: 8),
          ],
          if (overflow.isNotEmpty) _moreButton(context, overflow),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, String label) {
    final isSelected = label == selected;
    return GestureDetector(
      onTap: () => onSelected(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? ColorConstants.primaryColor.withOpacity(0.12) : Colors.white,
          borderRadius: BorderRadius.circular(4), // square-cornered
          border: Border.all(
            color: isSelected ? ColorConstants.primaryColor : Colors.grey.shade300,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? ColorConstants.primaryColor : Colors.black54,
          ),
        ),
      ),
    );
  }

  Widget _moreButton(BuildContext context, List<String> overflow) {
    final isOverflowSelected = overflow.contains(selected);
    return GestureDetector(
      onTap: () async {
        final choice = await showMenu<String>(
          context: context,
          position: const RelativeRect.fromLTRB(200, 300, 16, 0),
          items: overflow
              .map((name) => PopupMenuItem<String>(value: name, child: Text(name)))
              .toList(),
        );
        if (choice != null) onSelected(choice);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isOverflowSelected ? ColorConstants.primaryColor.withOpacity(0.12) : Colors.white,
          borderRadius: BorderRadius.circular(4), // square-cornered
          border: Border.all(
            color: isOverflowSelected ? ColorConstants.primaryColor : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isOverflowSelected ? selected : 'More',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isOverflowSelected ? ColorConstants.primaryColor : Colors.black54,
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.keyboard_arrow_down, size: 16,
                color: isOverflowSelected ? ColorConstants.primaryColor : Colors.black54),
          ],
        ),
      ),
    );
  }
}