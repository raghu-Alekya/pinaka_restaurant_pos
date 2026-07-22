import 'package:flutter/material.dart';
import '../../models/view_mode.dart';

class ViewLayoutToggle extends StatelessWidget {
  final ViewMode selectedMode;
  final Function(ViewMode) onModeSelected;

  const ViewLayoutToggle({
    Key? key,
    required this.selectedMode,
    required this.onModeSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 160,
      height: 52,
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        color: theme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: theme.dividerColor),
        ),
        shadows: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Container(
          decoration: ShapeDecoration(
            color: theme.brightness == Brightness.dark
                ? const Color(0xFF30364A)
                : const Color(0xFFF8F6F6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildIcon(
                context,
                ViewMode.normal,
                selectedMode,
                Icons.center_focus_strong,
              ),
              _buildIcon(
                context,
                ViewMode.gridShapeBased,
                selectedMode,
                Icons.grid_on,
              ),
              _buildIcon(
                context,
                ViewMode.gridCommonImage,
                selectedMode,
                Icons.grid_view,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(
      BuildContext context,
      ViewMode mode,
      ViewMode selected,
      IconData icon,
      ) {
    final theme = Theme.of(context);
    final isSelected = mode == selected;

    return GestureDetector(
      onTap: () => onModeSelected(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 40,
        height: 34,
        decoration: BoxDecoration(
          color: isSelected
              ? theme.cardColor
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.25),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ]
              : [],
        ),
        child: Center(
          child: Icon(
            icon,
            size: 22,
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}