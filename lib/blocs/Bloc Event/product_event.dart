import 'package:equatable/equatable.dart';

abstract class ProductEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Fetch products for a given subcategory
class FetchProductsBySubCategory extends ProductEvent {
  final int subCategoryId;

  FetchProductsBySubCategory({required this.subCategoryId});

  @override
  List<Object?> get props => [subCategoryId];
}
class FetchProductsByMiniSubCategory extends ProductEvent {
  final int miniSubCategoryId;
  FetchProductsByMiniSubCategory({required this.miniSubCategoryId});
}
class ClearProducts extends ProductEvent {}


/// Update quantity of a variant inside a product
class UpdateVariantQuantity extends ProductEvent {
  final int productId;
  final int variantId;
  final int quantity;

  UpdateVariantQuantity({
    required this.productId,
    required this.variantId,
    required this.quantity,
  });

  @override
  List<Object?> get props => [productId, variantId, quantity];
}
