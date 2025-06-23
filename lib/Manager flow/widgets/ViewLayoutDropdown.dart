import 'package:flutter/material.dart';

import '../../CaptainFlow/ui/CaptainTablesScreen.dart';

class ViewLayoutDropdown extends StatefulWidget {
  final Function(ViewMode) onModeSelected;

  const ViewLayoutDropdown({Key? key, required this.onModeSelected}) : super(key: key);

  @override
  _ViewLayoutDropdownState createState() => _ViewLayoutDropdownState();
}

ViewMode _currentViewMode = ViewMode.normal;

class _ViewLayoutDropdownState extends State<ViewLayoutDropdown> {
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<ViewMode>(
      onSelected: (ViewMode mode) {
        setState(() {
          _currentViewMode = mode;
        });
        widget.onModeSelected(mode);
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      offset: Offset(0, 40),
      color: Colors.white, // Set dropdown background color to white
      itemBuilder: (BuildContext context) => <PopupMenuEntry<ViewMode>>[
        _buildMenuItem(ViewMode.normal, 'Advanced layout', Icons.center_focus_strong),
        _buildMenuItem(ViewMode.gridShapeBased, 'Standard layout', Icons.grid_on),
        _buildMenuItem(ViewMode.gridCommonImage, 'Basic layout',Icons.grid_view),
      ],
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 52, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'View layout',
              style: TextStyle(
                color: const Color(0xFF5D5A5A),
                fontSize: 16,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(width:10),
            Icon(Icons.arrow_drop_down, color: Colors.black),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<ViewMode> _buildMenuItem(ViewMode mode, String title, IconData icon) {
    bool isSelected = _currentViewMode == mode;

    return PopupMenuItem<ViewMode>(
      value: mode,
      padding: EdgeInsets.zero,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isSelected ? Colors.grey.shade300 : Colors.white,
        ),
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            if (isSelected)
              Icon(Icons.circle, color: Colors.orange, size: 10)
            else
              SizedBox(width: 10),
            SizedBox(width: 10),
            Icon(icon, size: 24, color: Colors.black),
            SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color: const Color(0xFF5D5A5A),
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
