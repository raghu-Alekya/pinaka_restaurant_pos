import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/Bloc Event/category_event.dart';
import '../../blocs/Bloc Event/product_event.dart';
import '../../blocs/Bloc Event/subcategory_event.dart';
import '../../blocs/Bloc Event/minisubcategory_event.dart';
import '../../blocs/Bloc Logic/category_bloc.dart';
import '../../blocs/Bloc Logic/product_bloc.dart';
import '../../blocs/Bloc Logic/subcategory_bloc.dart';
import '../../blocs/Bloc Logic/minisubcategory_bloc.dart';
import '../../blocs/Bloc State/category_states.dart';
import '../../blocs/Bloc State/minisubcategory.dart';
import '../../blocs/Bloc State/subcategory_states.dart';
import '../../models/sidebar/category_model_.dart';

class SideBarWidgets extends StatefulWidget {
  final String token;
  final String restaurantId;

  const SideBarWidgets({
    super.key,
    required this.token,
    required this.restaurantId,
  });

  @override
  State<SideBarWidgets> createState() => _SideBarWidgetsState();
}

class _SideBarWidgetsState extends State<SideBarWidgets> {
  final ScrollController _scrollController = ScrollController();
  int _selectedSubCategoryIndex = -1;

  @override
  void initState() {
    super.initState();

    // Load categories on init
    context.read<CategoryBloc>().add(
      LoadCategories(
        token: widget.token,
        restaurantId: widget.restaurantId,
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildSidebarItem({
    required Category category,
    required bool isSelected,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          final categoryBloc = context.read<CategoryBloc>();
          categoryBloc.add(SelectCategory(category.id));

          // Reset subcategories, mini-subcategories, and products
          context.read<SubCategoryBloc>().add(ResetSubCategory());
          context.read<MiniSubCategoryBloc>().add(ResetMiniSubCategory());
          context.read<ProductBloc>().add(ClearProducts());
          _selectedSubCategoryIndex = -1; // reset local index
        },
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: 70,
          height: 72,
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFCBEEF9) : const Color(0xFF574CB0),
            borderRadius: BorderRadius.circular(4),
            boxShadow: const [
              BoxShadow(
                color: Color(0x19000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              category.imagepath.isNotEmpty
                  ? Image.network(
                category.imagepath,
                width: 26,
                height: 26,
                errorBuilder: (_, __, ___) =>
                const Icon(Icons.image_not_supported, size: 24),
              )
                  : const Icon(Icons.fastfood, size: 24, color: Colors.white),
              const SizedBox(height: 6),
              Text(
                category.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF493F9C) : const Color(0xFFF3FCFF),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final sidebarWidth = screenWidth * 0.15;

    return MultiBlocListener(
      listeners: [
        // Load subcategories when a category is selected
        BlocListener<CategoryBloc, CategoryState>(
          listener: (context, state) {
            if (state is CategoryLoaded && state.selectedCategory != null) {
              context.read<SubCategoryBloc>().add(
                LoadSubCategories(
                  token: widget.token,
                  categoryId: state.selectedCategory!.id,
                ),
              );
            }
          },
        ),

        // Load mini-subcategories or products when subcategory is loaded
        BlocListener<SubCategoryBloc, SubCategoryState>(
          listener: (context, state) {
            if (state is SubCategoryLoaded && state.subcategories.isNotEmpty) {
              // Only proceed if a subcategory is actually selected
              if (state.selectedSubCategory != null) {
                final selectedSub = state.subcategories
                    .firstWhere((sub) => sub.id == state.selectedSubCategory);

                if (selectedSub.subCategories != null &&
                    selectedSub.subCategories!.isNotEmpty) {
                  // Fetch mini-subcategories
                  context.read<MiniSubCategoryBloc>().add(
                    FetchMiniSubCategories(subCategoryId: selectedSub.id),
                  );
                } else {
                  // Fetch products directly if no mini-subcategories
                  context.read<ProductBloc>().add(
                    FetchProductsBySubCategory(subCategoryId: selectedSub.id),
                  );
                }
              }
              // ❌ Do NOT auto-select the first subcategory
            }
          },
        ),


        // Load products for first mini-subcategory automatically
        BlocListener<MiniSubCategoryBloc, MiniSubCategoryState>(
          listener: (context, state) {
            if (state is MiniSubCategoryLoaded && state.miniSubCategories.isNotEmpty) {
              final firstMiniSub = state.miniSubCategories.first;
              context.read<ProductBloc>().add(
                FetchProductsByMiniSubCategory(miniSubCategoryId: firstMiniSub.id),
              );
            }
          },
        ),
      ],
      child: BlocBuilder<CategoryBloc, CategoryState>(
        builder: (context, state) {
          if (state is CategoryLoading) {
            return SizedBox(
              width: sidebarWidth,
              child: const Center(child: CircularProgressIndicator()),
            );
          } else if (state is CategoryLoaded) {
            return Container(
              margin: const EdgeInsets.only(left: 12, top: 12, bottom: 16),
              width: sidebarWidth,
              height: MediaQuery.of(context).size.height * 0.9,
              decoration: BoxDecoration(
                color: const Color(0xFF493F9C),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: List.generate(
                      state.categories.length,
                          (index) {
                        final category = state.categories[index];
                        final isSelected =
                            state.selectedCategory?.id == category.id;
                        return _buildSidebarItem(
                          category: category,
                          isSelected: isSelected,
                        );
                      },
                    ),
                  ),
                ),
              ),
            );
          } else if (state is CategoryError) {
            return SizedBox(
              width: sidebarWidth,
              child: Center(
                child: Text(
                  state.message,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            );
          } else {
            return SizedBox(width: sidebarWidth);
          }
        },
      ),
    );
  }
}
