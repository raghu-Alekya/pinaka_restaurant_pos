import 'dart:math';
import 'package:flutter/material.dart';
import 'package:pinaka_restaurant_pos/App%20flow/widgets/table_helpers.dart';

import '../../utils/TableStatusColors.dart';

class PlacedTableBuilder {
  static Widget buildPlacedTableWidget({
    required String name,
    required int capacity,
    required String area,
    required String shape,
    required Size size,
    required double rotation,
    required String status,
    bool isMerged = false,
  }) {
    const double chairSize = 20;
    const double offset = 10;
    final double extraSpace = chairSize + offset;

    final double stackWidth = size.width + extraSpace * 2;
    final double stackHeight = size.height + extraSpace * 2;

    final Color tableColor = TableStatusColors.getTableColor(status);
    final Color chairColor = TableStatusColors.getChairColor(status);


    Widget tableShape;
    if (shape == "circle") {
      tableShape = Positioned(
        left: extraSpace,
        top: extraSpace,
        child: ClipOval(
          child: Container(
            width: size.width,
            height: size.height,
            color: tableColor,
            child: Center(
              child: Transform.rotate(
                angle: -rotation * (pi / 180),
                child: TableHelpers.buildTableContent(
                  name,
                  area,
                  capacity,
                  chairColor,
                  isMerged: isMerged,
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      tableShape = Positioned(
        left: extraSpace,
        top: extraSpace,
        child: Container(
          width: size.width,
          height: size.height,
          decoration: BoxDecoration(
            color: tableColor,
            borderRadius: BorderRadius.circular(shape == "square" ? 8 : 16),
          ),
          child: Center(
            child: Transform.rotate(
              angle: -rotation * (pi / 180),
              child: TableHelpers.buildTableContent(
                name,
                area,
                capacity,
                chairColor,
                isMerged: isMerged,
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: stackWidth,
      height: stackHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          tableShape,
          ..._buildChairs(
            capacity,
            size,
            extraSpace,
            shape,
            chairColor,
          ),
        ],
      ),
    );
  }

  static List<Widget> _buildChairs(
      int capacity,
      Size tableSize,
      double margin,
      String shape,
      Color chairColor,
      ) {
    const double chairWidth = 15;
    const double chairHeight = 48;

    final List<Widget> chairs = [];

    final double left = margin;
    final double top = margin;
    final double right = margin + tableSize.width;
    final double bottom = margin + tableSize.height;

    if (shape == 'circle') {
      final double centerX = (tableSize.width / 2) + margin;
      final double centerY = (tableSize.height / 2) + margin;
      final double radius = (max(tableSize.width, tableSize.height) / 2) + 12;

      for (int i = 0; i < 4; i++) {
        final double angle = (2 * pi / 4) * i;
        final double dx = centerX + radius * cos(angle) - (chairWidth / 2);
        final double dy = centerY + radius * sin(angle) - (chairHeight / 2);

        chairs.add(
          Positioned(
            left: dx,
            top: dy,
            child: Transform.rotate(
              angle: angle,
              child: TableHelpers.buildChairRect(chairColor),
            ),
          ),
        );
      }
    } else if (shape == 'square') {
      chairs.addAll([
        Positioned(
          left: left + tableSize.width / 2 - chairWidth / 2,
          top: top - chairHeight + 10,
          child: Transform.rotate(
            angle: -pi / 2,
            child: TableHelpers.buildChairRect(chairColor),
          ),
        ),
        Positioned(
          left: right + 8,
          top: top + tableSize.height / 2 - chairWidth / 2 - 12,
          child: TableHelpers.buildChairRect(chairColor),
        ),
        Positioned(
          left: left + tableSize.width / 2 - chairWidth / 2,
          top: bottom - 5,
          child: Transform.rotate(
            angle: pi / 2,
            child: TableHelpers.buildChairRect(chairColor),
          ),
        ),
        Positioned(
          left: left - chairHeight + 27,
          top: top + tableSize.height / 2 - chairWidth / 2 - 12,
          child: Transform.rotate(
            angle: pi,
            child: TableHelpers.buildChairRect(chairColor),
          ),
        ),
      ]);
    } else if (shape == 'rectangle') {
      chairs.addAll([
        // Left (moved up)
        Positioned(
          left: left - chairHeight + 27,
          top: top + tableSize.height / 2 - chairWidth - 10,
          child: Transform.rotate(
            angle: pi,
            child: TableHelpers.buildChairRect(chairColor),
          ),
        ),
        // Right (moved up)
        Positioned(
          left: right + 6,
          top: top + tableSize.height / 2 - chairWidth - 10,
          child: TableHelpers.buildChairRect(chairColor),
        ),
        // Top left
        Positioned(
          left: left + tableSize.width * 0.30 - chairWidth / 2,
          top: top - chairHeight + 8,
          child: Transform.rotate(
            angle: -pi / 2,
            child: TableHelpers.buildChairRect(chairColor),
          ),
        ),
        // Top right
        Positioned(
          left: left + tableSize.width * 0.70 - chairWidth / 2,
          top: top - chairHeight + 8,
          child: Transform.rotate(
            angle: -pi / 2,
            child: TableHelpers.buildChairRect(chairColor),
          ),
        ),
        // Bottom left
        Positioned(
          left: left + tableSize.width * 0.30 - chairWidth / 2,
          top: bottom - 5,
          child: Transform.rotate(
            angle: pi / 2,
            child: TableHelpers.buildChairRect(chairColor),
          ),
        ),
        // Bottom right
        Positioned(
          left: left + tableSize.width * 0.70 - chairWidth / 2,
          top: bottom - 5,
          child: Transform.rotate(
            angle: pi / 2,
            child: TableHelpers.buildChairRect(chairColor),
          ),
        ),
      ]);
    }
    return chairs;
  }
}
