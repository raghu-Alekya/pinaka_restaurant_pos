class Item {
  final String id;
  final String name;
  final String imagePath;
  final double price;
  final bool isVeg;  // <--- Add this property
  final bool hasVariants;

  Item({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.price,
    required this.isVeg,       // <--- Initialize in constructor
    required this.hasVariants,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      imagePath: json['imagePath'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      isVeg: json['isVeg'] ?? false,   // <--- from JSON
      hasVariants: json['hasVariants'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'imagePath': imagePath,
    'price': price,
    'isVeg': isVeg,            // <--- to JSON
    'hasVariants': hasVariants,
  };
}
