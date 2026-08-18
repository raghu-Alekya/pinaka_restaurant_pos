import 'package:flutter/material.dart';
import '../../../../constants/color_constants.dart';
import '../entities/category_entity.dart';

class CategoryTabs extends StatelessWidget {
  final List<CategoryEntity> categories;
  final int selectedId;
  final ValueChanged<int> onTabSelected;

  const CategoryTabs({
    Key? key,
    required this.categories,
    required this.selectedId,
    required this.onTabSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final scale = (screenWidth / 375).clamp(0.85, 1.25);

        final horizontalPadding = 16 * scale;
        final itemSpacing = 10 * scale;

        // Card size (unchanged)
        final cardWidth = 68 * scale;
        final cardHeight = 76 * scale;
        final borderRadius = 12 * scale;
        final textSize = 11 * scale;
        final iconSize = 22 * scale;
        final labelBarHeight = 24 * scale;

        // 👇 Image size (smaller than the card)
        final imageSize = 38 * scale;

        return SizedBox(
          height: cardHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            itemCount: categories.length,
            separatorBuilder: (_, __) => SizedBox(width: itemSpacing),
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = category.id == selectedId;

              return GestureDetector(
                onTap: () => onTabSelected(category.id),
                child: Container(
                  width: cardWidth,
                  height: cardHeight,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(borderRadius),
                    border: Border.all(
                      color: isSelected
                          ? ColorConstants.primaryColor
                          : Colors.grey.shade300,
                      width: isSelected ? 1.6 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(borderRadius - 1),
                    child: Column(
                      children: [
                        // ── Image area (smaller image, centered) ──
                        Expanded(
                          child: Container(
                            color: isSelected
                                ? ColorConstants.primaryColor.withOpacity(0.12)
                                : Colors.grey.shade50,
                            child: Center(
                              child: category.imagePath != null
                                  ? Image.network(
                                category.imagePath!,
                                width: imageSize,
                                height: imageSize,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.restaurant_menu,
                                  color: Colors.grey.shade500,
                                  size: iconSize,
                                ),
                              )
                                  : Icon(
                                Icons.restaurant_menu,
                                color: Colors.grey.shade500,
                                size: iconSize,
                              ),
                            ),
                          ),
                        ),

                        // ── Bottom label bar ──
                        Container(
                          width: double.infinity,
                          height: labelBarHeight,
                          alignment: Alignment.center,
                          padding: EdgeInsets.symmetric(horizontal: 4 * scale),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? ColorConstants.primaryColor
                                : Colors.white,
                          ),
                          child: Text(
                            category.name,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: textSize,
                              height: 1.2,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}