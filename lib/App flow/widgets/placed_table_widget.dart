import 'dart:math';
import 'package:flutter/material.dart';
import 'package:pinaka_restaurant_pos/App%20flow/widgets/table_helpers.dart';

class PlacedTableBuilder {
  static Widget buildPlacedTableWidget({
    required String name,
    required int capacity,
    required String area,
    required String shape,
    required Size size,
    required int guestCount,
    required double rotation,
  }) {
    const double chairSize = 20;
    const double offset = 10;
    final double extraSpace = chairSize + offset;

    final double stackWidth = size.width + extraSpace * 2;
    final double stackHeight = size.height + extraSpace * 2;

    final hasGuests = guestCount > 0;
    final tableColor = hasGuests
        ? const Color(0xFFF44336).withAlpha((0.25 * 255).round())
        : const Color(0x3F22D629);

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
                child: TableHelpers.buildTableContent(name, area, guestCount),
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
              child: TableHelpers.buildTableContent(name, area, guestCount),
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
            hasGuests ? const Color(0xFFF44336) : const Color(0xFF4CAF50),
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

    if (shape == 'circle') {
      final double centerX = (tableSize.width / 2) + margin;
      final double centerY = (tableSize.height / 2) + margin;
      final double radius = (max(tableSize.width, tableSize.height) / 2) + 12;

      for (int i = 0; i < capacity && i < 12; i++) {
        final double angle = (2 * pi / capacity) * i;
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
    } else {
      double left = margin;
      double top = margin;
      double right = margin + tableSize.width;
      double bottom = margin + tableSize.height;

      if (shape == 'rectangle') {
        double leftY = top + (tableSize.height / 2) - (chairWidth / 2);
        double chairTopOffset = -20;
        double chairLeftOffset = 17;

        if (capacity == 1) {
          chairs.add(
            Positioned(
              left: left + (tableSize.width / 2) - (chairWidth / 2),
              top: top - chairHeight,
              child: Transform.rotate(
                angle: -1.57,
                child: TableHelpers.buildChairRect(chairColor),
              ),
            ),
          );
        } else if (capacity == 2) {
          chairs.add(
            Positioned(
              left: (left - chairHeight) + chairLeftOffset,
              top: leftY + chairTopOffset,
              child: Transform.rotate(
                angle: pi,
                child: TableHelpers.buildChairRect(chairColor),
              ),
            ),
          );

          chairs.add(
            Positioned(
              left: right + 10,
              top: top + (tableSize.height / 3) - (chairWidth / 3) - 10,
              child: TableHelpers.buildChairRect(chairColor),
            ),
          );
        } else {
          int remaining = capacity - 2;
          int topChairs = remaining ~/ 2;
          int bottomChairs = remaining - topChairs;

          chairs.add(
            Positioned(
              left: (left - chairHeight) + chairLeftOffset,
              top: leftY + chairTopOffset,
              child: Transform.rotate(
                angle: pi,
                child: TableHelpers.buildChairRect(chairColor),
              ),
            ),
          );

          chairs.add(
            Positioned(
              left: right + 10,
              top: top + (tableSize.height / 3) - (chairWidth / 3) - 10,
              child: TableHelpers.buildChairRect(chairColor),
            ),
          );

          double topSpacing =
              (tableSize.width - (topChairs * chairWidth)) / (topChairs + 1);
          for (int i = 0; i < topChairs; i++) {
            double dx = left + topSpacing * (i + 1) + chairWidth * i;
            chairs.add(
              Positioned(
                left: dx,
                top: top - chairHeight,
                child: Transform.rotate(
                  angle: -1.57,
                  child: TableHelpers.buildChairRect(chairColor),
                ),
              ),
            );
          }

          double bottomSpacing =
              (tableSize.width - (bottomChairs * chairWidth)) /
                  (bottomChairs + 1);
          for (int i = 0; i < bottomChairs; i++) {
            double dx = left + bottomSpacing * (i + 1) + chairWidth * i;
            chairs.add(
              Positioned(
                left: dx,
                top: bottom,
                child: Transform.rotate(
                  angle: 1.57,
                  child: TableHelpers.buildChairRect(chairColor),
                ),
              ),
            );
          }
        }
      } else {
        int sideCount = 4;
        int chairsPerSide = capacity ~/ sideCount;
        int extraChairs = capacity % sideCount;

        // Top
        int topChairs = chairsPerSide + (extraChairs > 0 ? 1 : 0);
        double topSpacing =
            (tableSize.width - (topChairs * chairWidth)) / (topChairs + 1);
        for (int i = 0; i < topChairs; i++) {
          double dx = left + topSpacing * (i + 1) + chairWidth * i;
          chairs.add(
            Positioned(
              left: dx,
              top: top - chairHeight,
              child: Transform.rotate(
                angle: -1.57,
                child: TableHelpers.buildChairRect(chairColor),
              ),
            ),
          );
        }

        // Right
        int rightChairs = chairsPerSide + (extraChairs > 1 ? 1 : 0);
        double rightSpacing =
            (tableSize.height - (rightChairs * chairWidth)) /
                (rightChairs + 1);

        for (int i = 0; i < rightChairs; i++) {
          double dy = top + rightSpacing * (i + 1) + chairWidth * i - 15.0;
          double dx = right + 15.0;

          chairs.add(
            Positioned(
              left: dx,
              top: dy,
              child: TableHelpers.buildChairRect(chairColor),
            ),
          );
        }

        // Bottom
        int bottomChairs = chairsPerSide + (extraChairs > 2 ? 1 : 0);
        double bottomSpacing =
            (tableSize.width - (bottomChairs * chairWidth)) /
                (bottomChairs + 1);
        for (int i = 0; i < bottomChairs; i++) {
          double dx = left + bottomSpacing * (i + 1) + chairWidth * i;
          chairs.add(
            Positioned(
              left: dx,
              top: bottom,
              child: Transform.rotate(
                angle: 1.57,
                child: TableHelpers.buildChairRect(chairColor),
              ),
            ),
          );
        }

        // Left
        int leftChairs = chairsPerSide;
        double leftSpacing =
            (tableSize.height - (leftChairs * chairWidth)) /
                (leftChairs + 1);

        for (int i = 0; i < leftChairs; i++) {
          double dy = top + leftSpacing * (i + 1) + chairWidth * i;

          chairs.add(
            Positioned(
              left: left - chairHeight + 15,
              top: dy - 12,
              child: Transform.rotate(
                angle: pi,
                child: TableHelpers.buildChairRect(chairColor),
              ),
            ),
          );
        }
      }
    }

    return chairs;
  }
}
