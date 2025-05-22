import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';

class DraggableTable extends StatelessWidget {
  final int capacity;
  final String shape;
  final bool isEnabled;
  final String tableName;
  final String areaName;
  final VoidCallback? onDragCompleted;
  final Function(Map<String, dynamic>)? onDoubleTap;

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

  Map<String, dynamic> get tableData => {
    'capacity': capacity,
    'tableName': tableName,
    'areaName': areaName,
    'shape': shape,
  };

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: !isEnabled,
      child: Draggable<Map<String, dynamic>>(
        data: tableData,
        feedback: Opacity(
          opacity: 0.7,
          child: _buildTableWidget(isEnabled),
        ),
        onDragCompleted: onDragCompleted,
        child: GestureDetector(
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

  Widget _buildTableWidget(bool isHighlighted) {
    final borderColor = isHighlighted ? Color(0xFF2874F0) : Colors.black45;
    final textColor = isHighlighted ? Color(0xFF2874F0) : Colors.black45;

    double width = 90;
    double height = 90;
    BorderType borderType = BorderType.RRect;
    Radius radius = Radius.circular(16);

    if (shape == "rectangle") {
      width = 150;
      height = 80;
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
