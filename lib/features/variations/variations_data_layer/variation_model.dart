
import '../variations_domain/variation_entity.dart';

class VariationModel {
  final int productId;
  final int variationId;
  final String name;
  final String price;
  final String? image;
  final String inStock;

  VariationModel({
    required this.productId,
    required this.variationId,
    required this.name,
    required this.price,
    this.image,
    required this.inStock,
  });

  factory VariationModel.fromJson(Map<String, dynamic> json) {
    return VariationModel(
      productId: json['product_id'] ?? 0,
      variationId: json['variation_id'] ?? 0,
      name: json['name'] ?? '',
      price: json['price'] ?? '0',
      image: json['image'],
      inStock: json['in_stock'] ?? 'No',
    );
  }

  VariationEntity toEntity() => VariationEntity(
    productId: productId,
    variationId: variationId,
    name: name,
    price: price,
    image: image,
    inStock: inStock,
  );
}

class VariationsResponse {
  final List<VariationModel> variations;

  VariationsResponse({required this.variations});

  factory VariationsResponse.fromJson(List<dynamic> json) {
    return VariationsResponse(
      variations: json.map((e) => VariationModel.fromJson(e)).toList(),
    );
  }
}