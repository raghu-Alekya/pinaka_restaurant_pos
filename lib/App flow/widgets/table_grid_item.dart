import 'package:flutter/material.dart';

class ShapeBasedGridItem extends StatelessWidget {
  final Map<String, dynamic> tableData;
  final VoidCallback? onTap;

  const ShapeBasedGridItem({
    super.key,
    required this.tableData,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final shape = tableData['shape'];
    final name = tableData['tableName'];
    final guestCount = tableData['guestCount'] ?? 0;

    String imagePath;
    if (shape == 'circle') {
      imagePath = guestCount > 0 ? 'assets/circle2.png' : 'assets/circle1.png';
    } else if (shape == 'square') {
      imagePath = guestCount > 0 ? 'assets/square2.png' : 'assets/square1.png';
    } else {
      imagePath =
      guestCount > 0 ? 'assets/rectangle2.png' : 'assets/rectangle1.png';
    }

    return GestureDetector(
      onTap: guestCount > 0 ? null : onTap,
      child: _buildGridItem(imagePath, name, guestCount),
    );
  }

  Widget _buildGridItem(String imagePath, String name, int guestCount) {
    final bool isOccupied = guestCount > 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            name,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isOccupied ? Colors.red : Colors.green,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.group,
                size: 16,
                color: isOccupied ? Colors.red : Colors.green,
              ),
              const SizedBox(width: 4),
              Text(
                isOccupied ? '$guestCount' : '-',
                style: TextStyle(
                  fontSize: 14,
                  color: isOccupied ? Colors.red : Colors.green,
                ),
              ),
            ],
          ),
          Image.asset(imagePath, width: 45, height: 45, fit: BoxFit.contain),
        ],
      ),
    );
  }
}

class CommonGridItem extends StatelessWidget {
  final Map<String, dynamic> tableData;
  final VoidCallback? onTap;

  const CommonGridItem({
    super.key,
    required this.tableData,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = tableData['tableName'];
    final guestCount = tableData['guestCount'] ?? 0;

    return GestureDetector(
      onTap: guestCount > 0 ? null : onTap,
      child: _buildGridItem1(name, guestCount),
    );
  }

  Widget _buildGridItem1(String name, int guestCount) {
    final bool isOccupied = guestCount > 0;

    final Color backgroundColor =
    isOccupied ? Colors.red[100]! : Colors.green[100]!;
    final Color textColor = isOccupied ? Colors.red : Colors.green[800]!;
    final Color iconColor = textColor;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 8),
          Text(
            name,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.group, size: 22, color: iconColor),
              const SizedBox(width: 6),
              Text(
                isOccupied ? '$guestCount' : '-',
                style: TextStyle(fontSize: 15, color: textColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
