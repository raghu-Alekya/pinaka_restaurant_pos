import '../../models/category/items_model.dart';
// import '../models/category/items_model.dart';

abstract class VariantEvent {}

class LoadProductVariants extends VariantEvent {
  final Product product;

  LoadProductVariants(this.product);
}

class SelectVariant extends VariantEvent {
  final int variantId;
  final int quantity;

  SelectVariant({required this.variantId, this.quantity = 1});
}

class ResetVariantSelection extends VariantEvent {}
