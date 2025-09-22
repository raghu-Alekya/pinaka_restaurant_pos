import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/Bloc Event/subcategory_event.dart';
import '../../blocs/Bloc Logic/subcategory_bloc.dart';
import '../../blocs/Bloc State/minisubcategory.dart';
import '../../blocs/Bloc State/subcategory_states.dart';
import '../../blocs/Bloc Logic/minisubcategory_bloc.dart';
import '../../blocs/Bloc Event/minisubcategory_event.dart';
import '../../models/category/subcategory_model.dart';
import '../widgets/subcategory_tab.dart';
import '../widgets/minisubcategory_widget.dart';
import '../../repositories/minisubcategory_repository.dart';
import '../../repositories/variant_repository.dart';
import '../../models/sidebar/category_model_.dart';
import '../../models/category/items_model.dart';

class SubCategoryScreen extends StatefulWidget {
  final String categoryId;
  final String token;
  final Category section;
  final MiniSubCategoryRepository miniSubRepo;
  final VariantRepository variantRepo;
  final Future<List<Product>> Function(int subCategoryId) fetchProducts;

  const SubCategoryScreen({
    super.key,
    required this.categoryId,
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
  int _selectedSubCategoryIndex = -1; // -1 = none selected

  @override
  void initState() {
    super.initState();
    _loadSubCategories();
  }

  void _loadSubCategories() {
    context.read<SubCategoryBloc>().add(
      LoadSubCategories(
          token: widget.token, categoryId: widget.categoryId),
    );
  }

  @override
  void didUpdateWidget(covariant SubCategoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categoryId != widget.categoryId) {
      // Category changed → reset subcategory selection and mini-subcategories
      setState(() {
        _selectedSubCategoryIndex = -1;
      });
      context.read<SubCategoryBloc>().add(ResetSubCategory());
      context.read<MiniSubCategoryBloc>().add(ResetMiniSubCategory());
      _loadSubCategories();
    }
  }

  void _onSubCategorySelected(int index, List<SubCategory> subCategories) {
    // Reset subcategory selection first
    setState(() {
      _selectedSubCategoryIndex = index;
    });

    // Reset mini-subcategories whenever a new subcategory is selected
    context.read<MiniSubCategoryBloc>().add(ResetMiniSubCategory());

    final selectedSubCategoryId = subCategories[index].id;

    // Fetch mini-subcategories for the newly selected subcategory
    context.read<MiniSubCategoryBloc>().add(
      FetchMiniSubCategories(subCategoryId: selectedSubCategoryId),
    );

    // Update selected subcategory in SubCategoryBloc (optional)
    context.read<SubCategoryBloc>().add(
      SelectSubCategory(subCategoryId: selectedSubCategoryId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SubCategoryBloc, SubCategoryState>(
      listener: (context, state) {
        if (state is SubCategoryLoaded) {
          // Ensure selection is reset when subcategories are loaded
          setState(() {
            _selectedSubCategoryIndex = -1;
          });
          context.read<MiniSubCategoryBloc>().add(ResetMiniSubCategory());
        }
      },
      child: BlocBuilder<SubCategoryBloc, SubCategoryState>(
        builder: (context, subState) {
          if (subState is SubCategoryLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (subState is SubCategoryLoaded) {
            final subCategories = subState.subcategories;
            if (subCategories.isEmpty) return const SizedBox();

            return Column(
              children: [
                SubCategoryTabWidget(
                  subCategories: subCategories,
                  selectedIndex: _selectedSubCategoryIndex,
                  onTap: (index) =>
                      _onSubCategorySelected(index, subCategories),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _selectedSubCategoryIndex >= 0
                      ? BlocBuilder<MiniSubCategoryBloc, MiniSubCategoryState>(
                    builder: (context, miniState) {
                      if (miniState is MiniSubCategoryLoading) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }
                      if (miniState is MiniSubCategoryLoaded) {
                        final miniSubCategories =
                            miniState.miniSubCategories;
                        return MiniSubCategoryWidget(
                          subCategories: miniSubCategories,
                          section: widget.section,
                          repository: widget.miniSubRepo,
                          variantRepository: widget.variantRepo,
                          tappedSubCategoryId: subCategories[
                          _selectedSubCategoryIndex]
                              .id,
                          fetchProducts: widget.fetchProducts,
                        );
                      }
                      if (miniState is MiniSubCategoryError) {
                        return Center(
                            child:
                            Text("Error: ${miniState.message}"));
                      }
                      return const SizedBox();
                    },
                  )
                      : const SizedBox(),
                ),
              ],
            );
          }

          if (subState is SubCategoryError) {
            return Center(child: Text("Error: ${subState.message}"));
          }

          return const SizedBox();
        },
      ),
    );
  }
}
