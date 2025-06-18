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

  static Widget buildTableContent(String name, String area, int guestCount) {
    final hasGuests = guestCount > 0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Table #$name',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: hasGuests ? Colors.red : Colors.green,
            fontSize: 13,
          ),
        ),
        SizedBox(height: 6),
        Icon(
          Icons.group,
          size: 25,
          color: hasGuests ? Colors.red : Colors.green,
        ),
        if (hasGuests)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '$guestCount',
               style: TextStyle(
                color: Colors.red,

                fontWeight: FontWeight.bold,

                fontSize: 14,
              ),
            ),
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
