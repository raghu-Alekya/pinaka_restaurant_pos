class ProductEntity {
  final int id;
  final String name;
  final String? price;
  final String? image;
  final bool? isVeg;
  final bool inStock;
  final String? isVariant;
  final String? isCombo;

  ProductEntity({
    required this.id,
    required this.name,
    this.price,
    this.image,
    this.isVeg,
    this.inStock = true,
    this.isVariant,
    this.isCombo,
  });
}