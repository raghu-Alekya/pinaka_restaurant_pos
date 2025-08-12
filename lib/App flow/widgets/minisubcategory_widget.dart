import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
<<<<<<<< HEAD:lib/App flow/widgets/subcategories_widget.dart
// import '../../bloc/order_bloc.dart';
import '../../blocs/order_bloc.dart';
import '../../models/category/subcategory_model.dart';
import '../../models/order/order_model.dart';
import '../../models/sidebar/menu_selection.dart';
// import '../models/category/subcategory_model.dart';
// import '../models/order/order_model.dart';
// import '../bloc/order_bloc.dart';
// import '../models/sidebar/menu_selection.dart';
========
import 'package:pinkapos_restar/widgets/variant_popup.dart';
import '../models/category/minisubcategory_model.dart';
import '../models/category/subcategory_model.dart';
import '../models/order/order_model.dart';
import '../bloc/order_bloc.dart';
import '../models/sidebar/category_model_.dart';
>>>>>>>> origin/branch2:lib/App flow/widgets/minisubcategory_widget.dart

class miniSubCategoryWidget extends StatefulWidget {
  final List<MiniSubCategory> subCategories;
  final Category section;

  final void Function(MiniSubCategory folder)? onFolderSelected;
  final void Function(MiniSubCategory item)? onItemSelected;

  const miniSubCategoryWidget({
    super.key,
    required this.subCategories,
    required this.section,
    this.onFolderSelected,
    this.onItemSelected,
  });

  @override
  State<miniSubCategoryWidget> createState() => _miniSubCategoryWidgetState();
}

class _miniSubCategoryWidgetState extends State<miniSubCategoryWidget> {
  MiniSubCategory? selectedFolder;
  List<MiniSubCategory> selectedItems = [];

  final List<Color> tileColors = [
    const Color(0xFFF0FBFF),
    const Color(0xFFFFD8D0),
    const Color(0xFFFFFFFF),
  ];

  void _onFolderTap(MiniSubCategory folder) {
    widget.onFolderSelected?.call(folder);
    setState(() {
      selectedFolder = selectedFolder == folder ? null : folder;
    });
  }

  @override
  Widget build(BuildContext context) {
    final folders = widget.subCategories.where((e) => e.isFolder).toList();
    final directItems = widget.subCategories.where((e) => !e.isFolder).toList();
    final selectedItems = selectedFolder?.items ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (folders.isNotEmpty) ...[
          _buildFolderGrid(folders),
          const SizedBox(height: 4), // 🔻 Reduced spacing between folder and items
          if (selectedItems.isNotEmpty) _buildItemsGrid(context, selectedItems.cast<MiniSubCategory>()),
        ] else
          _buildItemsGrid(context, directItems),
      ],
    );
  }

  Widget _buildFolderGrid(List<MiniSubCategory> folders) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: folders.length,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4), // 🔻 Smaller padding
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.8,
      ),
      itemBuilder: (context, index) {
        final folder = folders[index];
        final isSelected = selectedFolder == folder;

        return GestureDetector(
          onTap: () => _onFolderTap(folder),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFFCDFDC) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white, width: 1),
            ),
            child: Row(
              children: [
                folder.imagePath.isNotEmpty
                    ? Image.asset(folder.imagePath, width: 30, height: 30)
                    : const Icon(Icons.folder, size: 20, color: Colors.black),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    folder.name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildItemsGrid(BuildContext context, List<MiniSubCategory> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // 🔻 Reduced padding
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.6,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        final backgroundColor = tileColors[index % tileColors.length];

        return GestureDetector(
          onTap: () {
            if (item.variants != null && item.variants!.isNotEmpty) {
              showDialog(
                context: context,
                builder: (context) => VariantPopupContent(
                  itemName: item.name,
                  variants: item.variants!,
                  onSelected: (variantName, price, quantity) {
                    final orderItem = OrderItems(
                      name: '${item.name} - $variantName',
                      price: price,
                      quantity: quantity,
                      modifiers: [],
                      section: widget.section,
                    );

                    context.read<OrderBloc>().add(AddOrderItem(orderItem));
                  },
                  // item: item,
                ),
              );
            } else {
              // No variants → add directly
              context.read<OrderBloc>().add(
                AddOrderItem(OrderItems(
                  name: item.name,
                  price: item.price ?? 0.0,
                  quantity: 1,
                  modifiers: [],
                  section: widget.section,
                )),
              );
            }
            // Notify parent widget if needed:
            widget.onItemSelected?.call(item);
          },


          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 1),
                ),
                child: Row(
                  children: [
                    item.imagePath.isNotEmpty
                        ? Image.asset(item.imagePath, width: 50, height: 50)
                        : const Icon(Icons.fastfood, size: 30, color: Colors.black),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(item.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text('₹${item.price?.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: Image.asset(
                  item.isVeg ? 'assets/icon/veg_icon.png' : 'assets/icon/nonveg_icon.png',
                  width: 15,
                  height: 15,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
