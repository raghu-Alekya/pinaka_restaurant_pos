import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';

class TableHelpers {
  static Widget buildChairRect(Color color) {
    return Container(
      width: 13,
      height: 45,
      decoration: ShapeDecoration(
        color: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(9),
            bottomRight: Radius.circular(9),
          ),
        ),
      ),
    );
  }

  static Widget buildLegendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  static Widget buildTableContent(String name, String area, int capacity, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          name,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group, size: 25, color: color),
            const SizedBox(width: 5),
            Text(
              '$capacity',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static Size getPlacedTableSize(int capacity, String shape) {
    switch (shape) {
      case "circle":
      case "square":
        {
          double baseSize = 50.0;
          double increasePerSeat = 10.0;
          double size = (baseSize + (capacity * increasePerSeat)).clamp(
            90.0,
            160.0,
          );
          return Size(size, size);
        }

      case "rectangle":
        {
          double baseWidth = 80.0;
          double increasePerSeat = 35.0;
          double width = (baseWidth + (capacity * increasePerSeat)).clamp(
            170.0,
            450.0,
          );
          double height = 110.0;
          return Size(width, height);
        }

      default:
        return Size(120, 120);
    }
  }
  static Offset clampPositionToCanvas(Offset position, Size tableSize) {
    final double canvasWidth = 90000;
    final double canvasHeight = 60000;
    const double buffer = 12.0;

    final double clampedX = position.dx.clamp(
      buffer,
      canvasWidth - tableSize.width - buffer,
    );
    final double clampedY = position.dy.clamp(
      buffer,
      canvasHeight - tableSize.height - buffer,
    );

    return Offset(clampedX, clampedY);
  }

  static Offset findNonOverlappingPosition(
      Offset pos,
      Size size, {
        required bool Function(Offset pos, Size size) isOverlapping,
      }) {
    const int maxAttempts = 1000;
    const double step = 27.0;

    Offset current = pos;
    int dx = 0, dy = 0;
    int segmentLength = 1;
    int xDir = 1, yDir = 0;

    for (int i = 0; i < maxAttempts; i++) {
      if (!isOverlapping(current, size)) {
        return current;
      }

      current = Offset(pos.dx + dx * step, pos.dy + dy * step);

      if (i % segmentLength == 0) {
        final temp = xDir;
        xDir = -yDir;
        yDir = temp;
        if (yDir == 0) segmentLength++;
      }

      dx += xDir;
      dy += yDir;
    }

    return pos;
  }

  static Widget buildAddContentPrompt({
    required double scale,
    required VoidCallback onTap,
  }) {
    return Stack(
      children: [
        Positioned(
          top: 120,
          left: 0,
          right: 0,
          child: Transform.scale(
            scale: scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Start by adding your first table\nor seating area.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 15),
                DottedBorder(
                  color: Colors.grey,
                  strokeWidth: 1,
                  borderType: BorderType.RRect,
                  radius: Radius.circular(20),
                  dashPattern: [6, 4],
                  child: InkWell(
                    onTap: onTap,
                    child: Container(
                      padding: EdgeInsets.all(25),
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Color(0xFFF1F3F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, size: 20, color: Colors.blueGrey),
                            SizedBox(height: 8),
                            Text(
                              'Add table',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.blueGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
