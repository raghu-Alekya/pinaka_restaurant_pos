class Modifier {
  final int id;
  final int restaurantId;
  final int? productId; // nullable since not all APIs may send it
  final String name;
  final double price;
  final String type; // "modifier" or "add-on"

  Modifier({
    required this.id,
    required this.restaurantId,
    this.productId,
    required this.name,
    required this.price,
    required this.type,
  });

  factory Modifier.fromJson(Map<String, dynamic> json) {
    return Modifier(
      id: json['id'] ?? 0,
      restaurantId: json['restaurant_id'] ?? 0,
      productId: json['product_id'], // nullable
      name: json['name'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      type: json['type'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'restaurant_id': restaurantId,
      'product_id': productId,
      'name': name,
      'price': price,
      'type': type,
    };
  }
  bool get isAddon => type.toLowerCase() == "add-on";
  bool get isModifier => type.toLowerCase() == "modifier";
}
