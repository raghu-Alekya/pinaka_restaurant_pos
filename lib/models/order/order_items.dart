import '../sidebar/category_model_.dart';

class OrderItems {
  final String name;
  final double price;
  final Category section;
  int quantity;
  List<String> modifiers;
  Map<String, int> addOns; // addon name -> quantity
  String note;

  OrderItems({
    required this.name,
    required this.quantity,
    required this.price,
    this.modifiers = const [],
    this.addOns = const {},
    this.note = '',
    required this.section,
  });

  /// ✅ fromJson
  factory OrderItems.fromJson(Map<String, dynamic> json) {
    return OrderItems(
      name: json['name'],
      quantity: json['quantity'],
      price: (json['price'] as num).toDouble(),
      modifiers: List<String>.from(json['modifiers'] ?? []),
      addOns: Map<String, int>.from(json['addOns'] ?? {}),
      note: json['note'] ?? '',
      section: Category.fromJson(json['section']),
    );
  }

  /// ✅ toJson
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'price': price,
      'modifiers': modifiers,
      'addOns': addOns,
      'note': note,
      'section': section.toJson(),
    };
  }

  /// ✅ copyWith
  OrderItems copyWith({
    String? name,
    int? quantity,
    double? price,
    List<String>? modifiers,
    Map<String, int>? addOns,
    String? note,
    Category? section,
  }) {
    return OrderItems(
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      modifiers: modifiers ?? this.modifiers,
      addOns: addOns ?? this.addOns,
      note: note ?? this.note,
      section: section ?? this.section,
    );
  }

  /// ✅ Total including add-ons
  double totalWithAddons(Map<String, double> addonPrices) {
    double addonsTotal = 0.0;
    addOns.forEach((addon, qty) {
      addonsTotal += (addonPrices[addon] ?? 0) * qty;
    });
    return (price * quantity) + addonsTotal;
  }

  /// ✅ Format add-ons for display (name x qty ₹price)
  String formatAddOns(Map<String, double> addonPrices, {int limit = 2}) {
    final entries = addOns.entries.toList();
    if (entries.isEmpty) return '';
    if (entries.length <= limit) {
      return entries
          .map((e) => '${e.key} x${e.value} ₹${(addonPrices[e.key] ?? 0) * e.value}')
          .join(', ');
    }
    final visible = entries
        .take(limit)
        .map((e) => '${e.key} x${e.value} ₹${(addonPrices[e.key] ?? 0) * e.value}')
        .join(', ');
    return '$visible +${entries.length - limit} More';
  }
}
