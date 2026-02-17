import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/Bloc Event/subcategory_event.dart';
import '../../blocs/Bloc Logic/category_bloc.dart';
import '../../blocs/Bloc Logic/subcategory_bloc.dart';
import '../../blocs/Bloc State/category_states.dart';
import '../../blocs/Bloc State/subcategory_states.dart';
import '../../blocs/Bloc Event/minisubcategory_event.dart';
import '../../blocs/Bloc Logic/minisubcategory_bloc.dart';
import '../../blocs/Bloc State/minisubcategory.dart';
import '../../models/category/subcategory_model.dart';
import '../../models/sidebar/category_model_.dart';
import '../../models/category/items_model.dart';
import '../../repositories/minisubcategory_repository.dart';
import '../../repositories/variant_repository.dart';
import '../widgets/minisubcategory_widget.dart';
import '../widgets/subcategory_tab.dart';

class SubCategoryScreen extends StatefulWidget {
  final String token;
  final Category section;
  final MiniSubCategoryRepository miniSubRepo;
  final VariantRepository variantRepo;
  final Future<List<Product>> Function(int subCategoryId) fetchProducts;

  const SubCategoryScreen({
    super.key,
    required this.token,
    required this.section,
    required this.miniSubRepo,
    required this.variantRepo,
    required this.fetchProducts,
  });

  @override
  State<SubCategoryScreen> createState() => _SubCategoryScreenState();
}

class _SubCategoryScreenState extends State<SubCategoryScreen> {
  @override
  void initState() {
    super.initState();

    // Ensure CategoryBloc has loaded before loading SubCategories
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSubCategories();
    });
  }

  void _loadSubCategories() {
    final categoryState = context.read<CategoryBloc>().state;
    if (categoryState is CategoryLoaded && categoryState.selectedCategory != null) {
      context.read<SubCategoryBloc>().add(
        LoadSubCategories(
          token: widget.token,
          categoryId: categoryState.selectedCategory!.id,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SubCategoryBloc, SubCategoryState>(
      builder: (context, subState) {
        if (subState is SubCategoryLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (subState is SubCategoryError) {
          return Center(child: Text("Error: ${subState.message}"));
        }

        if (subState is SubCategoryLoaded) {
          final subCategories = subState.subcategories;
          if (subCategories.isEmpty) return const SizedBox();

          final selectedIndex = subCategories.indexWhere(
                  (s) => s.id == subState.selectedSubCategory);

          return Column(
            children: [
              // Subcategory Tabs
              SubCategoryTabWidget(
                subCategories: subCategories,
                selectedIndex: selectedIndex >= 0 ? selectedIndex : 0,
                onTap: (index) {
                  final selectedSub = subCategories[index];
                  context.read<SubCategoryBloc>().add(
                    SelectSubCategory(subCategory: selectedSub),
                  );
                },
              ),
              const SizedBox(height: 8),

              // MiniSubCategory / Product Area
              Expanded(
                child: BlocBuilder<MiniSubCategoryBloc, MiniSubCategoryState>(
                  builder: (context, miniState) {
                    if (miniState is MiniSubCategoryLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (miniState is MiniSubCategoryError) {
                      return Center(child: Text("Error: ${miniState.message}"));
                    }

                    if (miniState is MiniSubCategoryLoaded) {
                      return MiniSubCategoryWidget(
                        subCategories: miniState.miniSubCategories,
                        section: widget.section,
                        repository: widget.miniSubRepo,
                        variantRepository: widget.variantRepo,
                        tappedSubCategoryId: subCategories[
                        selectedIndex >= 0 ? selectedIndex : 0]
                            .id,
                        fetchProducts: widget.fetchProducts,
                      );
                    }

                    return const SizedBox();
                  },
                ),
              ),
            ],
          );
        }

        return const SizedBox();
      },
    );
  }
}
