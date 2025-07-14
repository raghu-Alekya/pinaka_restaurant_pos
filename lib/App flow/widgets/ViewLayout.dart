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
    return Container(
      width: 160,
      height: 52,
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: Container(
          width: double.infinity,
          height: 42,
          decoration: ShapeDecoration(
            color: const Color(0xFFF8F6F6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildIcon(ViewMode.normal, selectedMode, Icons.center_focus_strong),
              _buildIcon(ViewMode.gridShapeBased, selectedMode, Icons.grid_on),
              _buildIcon(ViewMode.gridCommonImage, selectedMode, Icons.grid_view),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(ViewMode mode, ViewMode selected, IconData icon) {
    final isSelected = mode == selected;

    return GestureDetector(
      onTap: () => onModeSelected(mode),
      child: Container(
        width: 40,
        height: 34,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: Color(0x3F000000),
              blurRadius: 2,
              offset: Offset(0, 1),
            )
          ]
              : [],
        ),
        child: Center(
          child: Icon(
            icon,
            size: 22,
            color: isSelected ? Colors.blue : Color(0xFF000000),
          ),
        ),
      ),
    );
  }
}