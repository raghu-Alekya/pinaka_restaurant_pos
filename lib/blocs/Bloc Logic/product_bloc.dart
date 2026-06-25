import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/category/items_model.dart';
import '../../repositories/product_repository.dart';
import '../Bloc Event/product_event.dart';
import '../Bloc State/product_states.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductRepository repository;

  final Map<int, List<Product>> _cache = {};

  ProductBloc(this.repository) : super(ProductInitial()) {
    on<FetchProductsBySubCategory>(_onFetchProducts);
    on<UpdateVariantQuantity>(_onUpdateVariantQuantity);
    on<ClearProducts>((event, emit) => emit(ProductInitial()));
  }

  Future<void> _onFetchProducts(
      FetchProductsBySubCategory event,
      Emitter<ProductState> emit,
      ) async {

    // Return cached products immediately
    if (_cache.containsKey(event.subCategoryId)) {
      emit(ProductLoaded(_cache[event.subCategoryId]!));
      return;
    }

    emit(ProductLoading());

    try {
      final products =
      await repository.fetchProductsBySubCategory(event.subCategoryId);

      _cache[event.subCategoryId] = products;

      emit(ProductLoaded(products));
    } catch (e) {
      emit(ProductError(e.toString().replaceFirst("Exception: ", "")));
    }
  }
  // Future<void> _onFetchProductsByMiniSubCategory(
  //     FetchProductsByMiniSubCategory event, Emitter<ProductState> emit) async {
  //   emit(ProductLoading());
  //   try {
  //     final products =
  //     await repository.fetchProductsByMiniSubCategory(event.miniSubCategoryId);
  //     emit(ProductLoaded(products));
  //   } catch (e) {
  //     emit(ProductError(e.toString()));
  //   }
  // }


  // Update variant quantity for a product
  void _onUpdateVariantQuantity(
      UpdateVariantQuantity event, Emitter<ProductState> emit) {
    if (state is ProductLoaded) {
      final currentProducts = (state as ProductLoaded).products;

      final updatedProducts = currentProducts.map((product) {
        if (product.id == event.productId) {
          final updatedVariants = product.variants.map((variant) {
            if (variant.variationId == event.variantId) {
              return Variant(
                productId: variant.productId,
                variationId: variant.variationId,
                name: variant.name,
                image: variant.image,
                price: variant.price,
                quantity: event.quantity, // Update quantity
              );
            }
            return variant;
          }).toList();

          return Product(
            id: product.id,
            name: product.name,
            price: product.price,
            image: product.image,
            isVeg: product.isVeg,
            variants: updatedVariants,
            isCombo: product.isCombo,

          );
        }
        return product;
      }).toList();

      emit(ProductLoaded(updatedProducts));
    }
  }
}
