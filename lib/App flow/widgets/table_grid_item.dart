import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../utils/TableStatusColors.dart';

class ShapeBasedGridItem extends StatelessWidget {
  final Map<String, dynamic> tableData;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const ShapeBasedGridItem({
    super.key,
    required this.tableData,
    this.onTap,
    this.onLongPress,
  });

  @override
  @override
  Widget build(BuildContext context) {
    final shape = tableData['shape'];

    final status =
        tableData['status']?.toString().toLowerCase() ?? 'available';

    final bool isChildTable =
        tableData['is_child'] == true ||
            tableData['is_child']?.toString().toLowerCase() == 'true' ||
            status == 'disabled';

    final isMerged = tableData['is_merged'] == true;

    final tableName =
        tableData['merged_tables'] ??
            tableData['tableName'] ??
            '';

    String imagePath;

    if (shape == 'circle') {
      imagePath = 'assets/circle1.png';
    } else if (shape == 'square') {
      imagePath = 'assets/square1.png';
    } else {
      imagePath = 'assets/rectangle1.png';
    }

    final tableColor = isChildTable
        ? const Color(0xFFBDBDBD)
        : TableStatusColors.getTableColor(status);
    final iconColor = isChildTable
        ? const Color(0xFF757575)
        : TableStatusColors.getChairColor(status);

// Make text/icons clearly visible on yellow cards.
    final visibleColor =
    status == 'available'
        ? const Color(0xFF344054)
        : iconColor;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: isChildTable ? null : onTap,
      onLongPress: isChildTable ? null : onLongPress,
      child: _buildGridItem(
        context,
        tableData,
        imagePath,
        tableColor,
        iconColor,
        tableName,
        isMerged,
      ),
    );
  }

  Widget _buildGridItem(
      BuildContext context,
      Map<String, dynamic> tableData,
      String imagePath,
      Color bgColor,
      Color iconColor,
      String tableName,
      bool isMerged,
      ) {
    final capacityStr = tableData['capacity']?.toString() ?? '';
    final capacity = int.tryParse(capacityStr) ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.2),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              tableName,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.group, size: 20, color: iconColor),
                const SizedBox(width: 5),
                Text(
                  capacityStr,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  imagePath,
                  width: 45,
                  height: 45,
                  fit: BoxFit.contain,
                  color: iconColor,
                  colorBlendMode: BlendMode.srcIn,
                ),
                if (isMerged) ...[
                  const SizedBox(width: 6),
                  Icon(
                    Icons.link,
                    color: capacity == 0 ? Colors.blue : Colors.black,
                    size: 20,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CommonGridItem extends StatelessWidget {
  final Map<String, dynamic> tableData;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const CommonGridItem({
    super.key,
    required this.tableData,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isMerged = tableData['is_merged'] == true;
    final name = tableData['merged_tables'] ?? tableData['tableName'] ?? '';
    final status = tableData['status'] ?? 'available';

    final bgColor = TableStatusColors.getTableColor(status);
    final iconColor = TableStatusColors.getChairColor(status);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onLongPress: onLongPress,
      child: _buildGridItem(name, bgColor, iconColor, isMerged),
    );
  }

  Widget _buildGridItem(
      String name,
      Color bgColor,
      Color iconColor,
      bool isMerged,
      ) {
    final capacityStr = tableData['capacity']?.toString() ?? '';
    final capacity = int.tryParse(capacityStr) ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.group, size: 20, color: iconColor),
                const SizedBox(width: 4),
                Text(
                  capacityStr,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                    fontSize: 14,
                  ),
                ),
                if (isMerged) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.link,
                    size: 18,
                    color: capacity == 0 ? Colors.blue : Colors.black,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}