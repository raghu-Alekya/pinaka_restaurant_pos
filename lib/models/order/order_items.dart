import '../sidebar/category_model_.dart';

class OrderItems {
  final int productId;        // ✅ always required
  final int? variationId;     // ✅ optional (null if not applicable)
  final String name;
  final double price;
  final Category section;
  final int quantity;
  final List<String> modifiers;
  final Map<String, Map<String, dynamic>> addOns; // {'Cheese': {'quantity': 2, 'price': 20.0}}
  final String note;

  OrderItems({
    required this.productId,
    this.variationId, // ✅ optional
    required this.name,
    required this.quantity,
    required this.price,
    this.modifiers = const [],
    this.addOns = const {},
    this.note = '',
    required this.section,
  });

  /// ✅ Total including add-ons (multiplies add-ons per item quantity)
  double get totalWithAddons {
    double addonsTotal = 0.0;
    addOns.forEach((_, data) {
      final qty = (data['quantity'] as int?) ?? 0;
      final addonPrice = (data['price'] as num?)?.toDouble() ?? 0.0;
      addonsTotal += qty * addonPrice;
    });

    // each addon applies per item quantity
    return (price * quantity) + (addonsTotal * quantity);
  }

  factory OrderItems.fromJson(Map<String, dynamic> json) {
    final rawAddOns = Map<String, dynamic>.from(json['addOns'] ?? {});
    final structuredAddOns = rawAddOns.map((key, value) => MapEntry(
      key,
      {
        'quantity': value['quantity'] ?? 0,
        'price': (value['price'] as num?)?.toDouble() ?? 0.0,
      },
    ));

    return OrderItems(
      productId: json['productId'],
      variationId: json['variationId'], // ✅ parse if exists
      name: json['name'],
      quantity: json['quantity'],
      price: (json['price'] as num).toDouble(),
      modifiers: List<String>.from(json['modifiers'] ?? []),
      addOns: structuredAddOns,
      note: json['note'] ?? '',
      section: Category.fromJson(json['section']),
    );
  }

  Map<String, dynamic> toJson() {
    final serializedAddOns = addOns.map((key, value) => MapEntry(key, {
      'quantity': value['quantity'],
      'price': value['price'],
    }));

    return {
      'productId': productId,
      if (variationId != null) 'variationId': variationId, // ✅ only if exists
      'name': name,
      'quantity': quantity,
      'price': price,
      'modifiers': modifiers,
      'addOns': serializedAddOns,
      'note': note,
      'section': section.toJson(),
    };
  }

  OrderItems copyWith({
    int? productId,
    int? variationId,
    String? name,
    int? quantity,
    double? price,
    List<String>? modifiers,
    Map<String, Map<String, dynamic>>? addOns,
    String? note,
    Category? section,
  }) {
    return OrderItems(
      productId: productId ?? this.productId,
      variationId: variationId ?? this.variationId, // ✅ include here
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      modifiers: modifiers ?? List<String>.from(this.modifiers),
      addOns: addOns ?? Map<String, Map<String, dynamic>>.from(this.addOns),
      note: note ?? this.note,
      section: section ?? this.section,
    );
  }
}
