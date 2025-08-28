import '../../models/category/items_model.dart';
// import '../models/category/items_model.dart';

abstract class VariantState {}

class VariantInitial extends VariantState {}

class VariantLoading extends VariantState {}

class VariantLoaded extends VariantState {
  final Product product;
  final int selectedVariantId;
  final int selectedQuantity;

  VariantLoaded({
    required this.product,
    this.selectedVariantId = -1,
    this.selectedQuantity = 1,
  });

  VariantLoaded copyWith({
    int? selectedVariantId,
    int? selectedQuantity,
  }) {
    return VariantLoaded(
      product: product,
      selectedVariantId: selectedVariantId ?? this.selectedVariantId,
      selectedQuantity: selectedQuantity ?? this.selectedQuantity,
    );
  }
}

class VariantError extends VariantState {
  final String message;
  VariantError(this.message);
}
