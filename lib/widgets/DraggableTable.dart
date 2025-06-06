import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';

/// A draggable table widget that displays a table with a specified shape and capacity.
///
/// This widget supports dragging to another location and double-tap interaction
/// for edit or other actions. It also visually indicates whether it is enabled or disabled.
///
/// The table can have different shapes (circle or rectangle), a name, and an area name.
class DraggableTable extends StatelessWidget {
  /// The seating capacity of the table.
  final int capacity;

  /// The shape of the table. Supported values: `"circle"` or `"rectangle"`.
  final String shape;

  /// Indicates whether the table is enabled for user interaction (drag and double-tap).
  final bool isEnabled;

  /// The name identifier of the table.
  final String tableName;

  /// The area name where this table belongs.
  final String areaName;

  /// Callback executed when a drag operation completes successfully.
  final VoidCallback? onDragCompleted;

  /// Callback executed when the table is double-tapped.
  /// Provides the current table data as a `Map<String, dynamic>`.
  final Function(Map<String, dynamic>)? onDoubleTap;

  /// Creates a draggable table widget.
  ///
  /// All parameters except callbacks are required.
  const DraggableTable({
    Key? key,
    required this.capacity,
    required this.shape,
    required this.isEnabled,
    required this.tableName,
    required this.areaName,
    this.onDragCompleted,
    this.onDoubleTap,
  }) : super(key: key);

  /// Returns a map containing the current table's data.
  Map<String, dynamic> get tableData => {
    'capacity': capacity,
    'tableName': tableName,
    'areaName': areaName,
    'shape': shape,
  };

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      // Absorbs pointer events when the table is disabled to prevent interactions.
      absorbing: !isEnabled,
      child: Draggable<Map<String, dynamic>>(
        // Data passed when dragging starts.
        data: tableData,
        // Widget shown under the finger while dragging.
        feedback: Opacity(
          opacity: 0.7,
          child: _buildTableWidget(isEnabled),
        ),
        // Called when drag completes successfully.
        onDragCompleted: onDragCompleted,
        child: GestureDetector(
          // Calls onDoubleTap callback when double tapped if enabled.
          onDoubleTap: () {
            if (isEnabled && onDoubleTap != null) {
              onDoubleTap!(tableData);
            }
          },
          child: _buildTableWidget(isEnabled),
        ),
      ),
    );
  }

  /// Builds the visual representation of the table widget with
  /// dotted border and shape-based appearance.
  ///
  /// [isHighlighted] controls the color of the border and text.
  Widget _buildTableWidget(bool isHighlighted) {
    final borderColor = isHighlighted ? Color(0xFF2874F0) : Colors.black45;
    final textColor = isHighlighted ? Color(0xFF2874F0) : Colors.black45;

    double width = 70;
    double height = 70;
    BorderType borderType = BorderType.RRect;
    Radius radius = Radius.circular(14);

    // Adjust dimensions and border type based on shape.
    if (shape == "rectangle") {
      width = 150;
      height = 60;
    } else if (shape == "circle") {
      borderType = BorderType.Circle;
      radius = Radius.circular(0);
    }

    return DottedBorder(
      color: borderColor,
      strokeWidth: 1.5,
      dashPattern: [6, 3],
      borderType: borderType,
      radius: radius,
      child: Container(
        width: width,
        height: height,
        alignment: Alignment.center,
        // Shape-based clipping of the inner container.
        child: shape == "circle"
            ? ClipOval(
          child: Container(
            color: Colors.grey[200],
            alignment: Alignment.center,
            child: _buildTableText(textColor),
          ),
        )
            : ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            color: Colors.grey[200],
            alignment: Alignment.center,
            child: _buildTableText(textColor),
          ),
        ),
      ),
    );
  }

  /// Builds the text widget shown inside the table.
  ///
  /// Displays "Drag to\nFloor" centered, with the given [textColor].
  Widget _buildTableText(Color textColor) {
    return Text(
      "Drag to\nFloor",
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 14,
        color: textColor,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}