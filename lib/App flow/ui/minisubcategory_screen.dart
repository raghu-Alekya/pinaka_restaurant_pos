import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/Bloc Event/minisubcategory_event.dart';
import '../../blocs/Bloc Logic/minisubcategory_bloc.dart';
import '../../blocs/Bloc State/minisubcategory.dart';
import '../../repositories/minisubcategory_repository.dart';
import '../../repositories/product_repository.dart';
import '../../repositories/variant_repository.dart';
// import '../../repository/minisubcategory_repository.dart';
// import '../../repository/product_repository.dart';
// import '../repository/variant_repository.dart';
import '../../models/sidebar/category_model_.dart';
// import '../bloc/minisubcategory_bloc.dart';
// import '../events/minisubcategory_event.dart';
// import '../states/minisubcategory.dart';
import '../widgets/minisubcategory_widget.dart';

class MiniSubCategoryScreen extends StatelessWidget {
  final Category section;
  final int subCategoryId;
  final ProductRepository productRepository;
  final VariantRepository variantRepository; // added

  const MiniSubCategoryScreen({
    super.key,
    required this.section,
    required this.subCategoryId,
    required this.productRepository,
    required this.variantRepository, // added
  });

  @override
  Widget build(BuildContext context) {
    final miniRepo = context.read<MiniSubCategoryRepository>();

    return BlocProvider(
      create: (context) => MiniSubCategoryBloc(repository: miniRepo)
        ..add(FetchMiniSubCategories(subCategoryId: subCategoryId)),
      child: BlocBuilder<MiniSubCategoryBloc, MiniSubCategoryState>(
        builder: (context, state) {
          if (state is MiniSubCategoryLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is MiniSubCategoryLoaded) {
            final subCategories = state.miniSubCategories;

            return MiniSubCategoryWidget(
              subCategories: subCategories,
              section: section,
              repository: miniRepo,
              tappedSubCategoryId: subCategoryId,
              fetchProducts: (int subCategoryId) async {
                try {
                  final products =
                  await productRepository.fetchProductsBySubCategory(subCategoryId);
                  return products;
                } catch (e) {
                  print("Error fetching products: $e");
                  return [];
                }
              },
              variantRepository: variantRepository, // pass it to widget
            );
          } else if (state is MiniSubCategoryError) {
            return Center(child: Text(state.message));
          } else {
            return const Center(child: Text('No items found'));
          }
        },
      ),
    );
  }
}
