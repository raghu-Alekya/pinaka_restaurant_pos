import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../utils/TableStatusColors.dart';

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
    final status = tableData['status'] ?? 'available';

    String imagePath;
    if (shape == 'circle') {
      imagePath = 'assets/circle1.png';
    } else if (shape == 'square') {
      imagePath = 'assets/square1.png';
    } else {
      imagePath = 'assets/rectangle1.png';
    }

    final tableColor = TableStatusColors.getTableColor(status);
    final iconColor = TableStatusColors.getChairColor(status);

    return GestureDetector(
      onTap: onTap,
      child: _buildGridItem(imagePath, name, tableColor, iconColor),
    );
  }

  Widget _buildGridItem(String imagePath, String name, Color bgColor, Color iconColor) {
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
              color: iconColor,
            ),
          ),
          Icon(
            Icons.group,
            size: 16,
            color: iconColor,
          ),
          Image.asset(
            imagePath,
            width: 45,
            height: 45,
            fit: BoxFit.contain,
            color: iconColor,
            colorBlendMode: BlendMode.srcIn,
          ),
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
    final status = tableData['status'] ?? 'available';

    final bgColor = TableStatusColors.getTableColor(status);
    final iconColor = TableStatusColors.getChairColor(status);

    return GestureDetector(
      onTap: onTap,
      child: _buildGridItem1(name, bgColor, iconColor),
    );
  }

  Widget _buildGridItem1(String name, Color bgColor, Color iconColor) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
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
              color: iconColor,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.group, size: 22, color: iconColor),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}