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
        // Responsive values based on screen width
        final screenWidth = constraints.maxWidth;

        // Base scale: 375 is a typical mobile width.
        final scale = (screenWidth / 375).clamp(0.85, 1.25);

        final horizontalPadding = 16 * scale;
        final itemSpacing = 8 * scale;

        final imageSize = 46 * scale;
        final textWidth = 60 * scale;
        final textSize = 10.5 * scale;
        final iconSize = 20 * scale;
        final borderRadius = 10 * scale;
        final textSpacing = 3 * scale;

        final tabHeight =
            imageSize +
                textSpacing +
                (textSize * 1.3);

        return SizedBox(
          height: tabHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
            ),
            itemCount: categories.length,
            separatorBuilder: (_, __) => SizedBox(
              width: itemSpacing,
            ),
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = category.id == selectedId;

              return GestureDetector(
                onTap: () => onTabSelected(category.id),
                child: SizedBox(
                  width: textWidth,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: imageSize,
                        height: imageSize,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? ColorConstants.primaryColor
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(
                            borderRadius,
                          ),
                          image: category.imagePath != null
                              ? DecorationImage(
                            image: NetworkImage(
                              category.imagePath!,
                            ),
                            fit: BoxFit.cover,
                          )
                              : null,
                        ),
                        child: category.imagePath == null
                            ? Icon(
                          Icons.restaurant_menu,
                          color: isSelected
                              ? Colors.white
                              : Colors.grey.shade600,
                          size: iconSize,
                        )
                            : null,
                      ),

                      SizedBox(height: textSpacing),

                      Text(
                        category.name,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: textSize,
                          height: 1.2,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? ColorConstants.primaryColor
                              : Colors.black54,
                        ),
                      ),
                    ],
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
