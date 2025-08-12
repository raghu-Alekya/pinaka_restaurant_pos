import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/category_bloc.dart';
import '../events/category_event.dart';
import '../models/category/subcategory_model.dart';
import '../models/category/minisubcategory_model.dart'; // MiniSubCategory model
import '../models/sidebar/category_model_.dart';
import '../states/category_states.dart';
import '../widgets/subcategory_tab.dart';
import '../widgets/minisubcategory_widget.dart';
import '../widgets/variant_popup.dart';

class SubCategoryScreen extends StatefulWidget {
  const SubCategoryScreen({super.key});

  @override
  State<SubCategoryScreen> createState() => _SubCategoryScreenState();
}

class _SubCategoryScreenState extends State<SubCategoryScreen> {
  List<SubCategory> currentSubCategories = [];
  String? selectedFolderName;

  // Helper to convert SubCategory list to MiniSubCategory list
  List<MiniSubCategory> convertSubCategories(List<SubCategory> subCategories) {
    return subCategories.map((subCat) {
      return MiniSubCategory(
        id: subCat.id,
        name: subCat.name,
        imagePath: subCat.imagePath,
        isVeg: subCat.isVeg ?? false,
        price: subCat.items?.isNotEmpty == true ? subCat.items!.first.price : 0,
        isFolder: subCat.isFolder,
        items: subCat.items?.map((item) => MiniSubCategory(
          id: item.id,
          name: item.name,
          imagePath: item.imagePath,
          isVeg: item.isVeg,
          price: item.price,
          isFolder: false,
        )).toList(),
        variants: null,
      );
    }).toList();
  }

  void openFolder(MiniSubCategory folder) {
    if (folder.items != null) {
      setState(() {
        currentSubCategories = folder.items!.map((mini) => SubCategory(
          id: mini.id,
          name: mini.name,
          categoryId: 'someCategoryId', // provide this appropriately
          imagePath: mini.imagePath,
          isFolder: false,
          // items: null or map further if needed
        )).toList();
        selectedFolderName = folder.name;
      });
    }
  }


  void loadRootSubCategories(List<SubCategory> root) {
    setState(() {
      currentSubCategories = root;
      selectedFolderName = null;
    });
  }

  void onItemSelected(MiniSubCategory item) {
    if (item.variants != null && item.variants!.isNotEmpty) {
      showDialog(
        context: context,
        builder: (_) => VariantPopupContent(
          itemName: item.name,
          variants: item.variants!,
          onSelected: (variantName, price, quantity) {
            // Add to order logic here
          },
          // item: item, // uncomment if needed and supported by VariantPopupContent
        ),
      );
    } else {
      debugPrint("Adding ${item.name} to order directly");
      // Add to order logic here
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CategoryBloc, CategoryState>(
      builder: (context, state) {
        if (state is CategoryLoaded) {
          final selectedCategory = state.selectedCategory;
          final selectedIndex = selectedCategory != null
              ? state.categories.indexOf(selectedCategory)
              : 0;

          if (currentSubCategories.isEmpty && selectedCategory != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              loadRootSubCategories(selectedCategory.subCategories);
            });
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              subCategoryTabWidget(
                categories: state.categories,
                selectedIndex: selectedIndex,
                onTap: (index) {
                  final categoryId = state.categories[index].id;
                  context.read<CategoryBloc>().add(SelectCategory(categoryId));
                  loadRootSubCategories(state.categories[index].subCategories);
                },
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      selectedCategory?.name ?? "No Category",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: selectedFolderName == null
                            ? Colors.red
                            : const Color(0xFF4C5F7D),
                      ),
                    ),
                    if (selectedFolderName != null) ...[
                      const SizedBox(width: 4),
                      const Text('>', style: TextStyle(color: Colors.grey)),
                      const SizedBox(width: 4),
                      Text(
                        selectedFolderName!,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFDEE8FF),
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(6),
                  margin: const EdgeInsets.all(6),
                  child: miniSubCategoryWidget(
                    subCategories: convertSubCategories(currentSubCategories),
                    onFolderSelected: openFolder,
                    section: selectedCategory ?? Category(id: '0', name: 'Default', imagePath: '', subCategories: []),
                    onItemSelected: onItemSelected,
                  ),
                ),
              ),
            ],
          );
        }

        if (state is CategoryLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is CategoryError) {
          return Center(child: Text(state.message));
        }

        return const Center(child: Text("Select a section from sidebar"));
      },
    );
  }
}
