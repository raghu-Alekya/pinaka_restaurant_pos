class Product {
  final int id;
  final String name;
  final double price;
  final List<String> images;
  final String image; // first image or fallback
  final bool isVeg;
  final List<Variant> variants;

  // Constructor
  Product({
    required this.id,
    required this.name,
    required this.price,
    List<String>? images,
    required this.isVeg,
    required this.variants,
    String? image,
  })  : images = images ?? [],
        image = image ?? (images != null && images.isNotEmpty ? images.first : '');

  // ✅ copyWith for immutability
  Product copyWith({
    int? id,
    String? name,
    double? price,
    List<String>? images,
    String? image,
    bool? isVeg,
    List<Variant>? variants,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      images: images ?? this.images,
      image: image ?? (images != null && images.isNotEmpty ? images.first : this.image),
      isVeg: isVeg ?? this.isVeg,
      variants: variants ?? this.variants,
    );
  }

  // fromJson
  factory Product.fromJson(Map<String, dynamic> json) {
    final images = (json['images'] as List<dynamic>?)
        ?.map((e) => e.toString())
        .toList() ??
        [];

    return Product(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name'] ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0.0') ?? 0.0,
      images: images,
      isVeg: (json['isVeg']?.toString().toLowerCase() == 'true') ||
          (json['type']?.toString().toLowerCase() == 'veg'),
      variants: (json['variants'] as List<dynamic>?)
          ?.map((v) => Variant.fromJson(v))
          .toList() ??
          [],
      image: json['image'], // fallback handled in constructor
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "price": price,
      "images": images,
      "image": image,
      "isVeg": isVeg,
      "variants": variants.map((v) => v.toJson()).toList(),
    };
  }
}

class Variant {
  final int productId;
  final int variationId;
  final String name;
  final String image;
  final double price;
  final int quantity;

  Variant({
    required this.productId,
    required this.variationId,
    required this.name,
    required this.image,
    required this.price,
    this.quantity = 1,
  });

  // ✅ copyWith for immutability
  Variant copyWith({
    int? productId,
    int? variationId,
    String? name,
    String? image,
    double? price,
    int? quantity,
  }) {
    return Variant(
      productId: productId ?? this.productId,
      variationId: variationId ?? this.variationId,
      name: name ?? this.name,
      image: image ?? this.image,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
    );
  }

  factory Variant.fromJson(Map<String, dynamic> json) {
    return Variant(
      productId: json['product_id'] ?? 0,
      variationId: json['variation_id'] ?? 0,
      name: json['name'] ?? '',
      image: json['image'] ?? '',
      price: (json['price'] != null)
          ? double.tryParse(json['price'].toString()) ?? 0.0
          : 0.0,
      quantity: json['quantity'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'product_id': productId,
    'variation_id': variationId,
    'name': name,
    'image': image,
    'price': price,
    'quantity': quantity,
  };
}
