import '../sidebar/category_model_.dart';

class OrderItems {
  final String name;
  final double price;
  final Category section;
  int quantity;
  List<String> modifiers;

  OrderItems({
    required this.name,
    required this.quantity,
    required this.price,
    this.modifiers = const [],
    required this.section,
  });

  factory OrderItems.fromJson(Map<String, dynamic> json) {
    return OrderItems(
      name: json['name'],
      quantity: json['quantity'],
      price: (json['price'] as num).toDouble(),
      modifiers: List<String>.from(json['modifiers'] ?? []),
      section: Category.fromJson(json['section']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'price': price,
      'modifiers': modifiers,
      'section': section.toJson(),
    };
  }

  /// ✅ Add this copyWith method:
  OrderItems copyWith({
    String? name,
    int? quantity,
    double? price,
    List<String>? modifiers,
    Category? section,
  }) {
    return OrderItems(
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      modifiers: modifiers ?? this.modifiers,
      section: section ?? this.section,
    );
  }
}
