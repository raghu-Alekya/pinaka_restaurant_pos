class VariationEntity {
  final int productId;
  final int variationId;
  final String name;
  final String price;
  final String? image;
  final String inStock;

  VariationEntity({
    required this.productId,
    required this.variationId,
    required this.name,
    required this.price,
    this.image,
    required this.inStock,
  });
}