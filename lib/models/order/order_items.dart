import '../sidebar/category_model_.dart';

class OrderItems {
  final int productId;        // ✅ always required
  final int? variationId;     // ✅ optional (null if not applicable)
  final String name;
  final double price;
  final Category ?section;
  final int quantity;
  final List<String> modifiers;
  final Map<String, Map<String, dynamic>> addOns; // {'Cheese': {'quantity': 2, 'price': 20.0}}
  final String note;
  final double amount;

  // ✅ New field
  final bool hasOptions;
  // ✅ NEW – tax class from backend (food / beverages)
  final String? taxClass;

  OrderItems({
    required this.productId,
    this.variationId, // ✅ optional
    required this.name,
    required this.quantity,
    required this.price,
    this.modifiers = const [],
    this.addOns = const {},
    this.note = '',
     this.section,
    this.taxClass,
    this.hasOptions = false,
    required this.amount,// default false
  });
  String get itemName => name;

  /// ✅ Total including add-ons (multiplies add-ons per item quantity)
  /// ✅ Total including add-ons (add-ons fixed, only item price multiplies)
  double get totalWithAddons {
    double addonsTotal = 0.0;

    addOns.forEach((_, data) {
      final qty = (data['quantity'] as int?) ?? 0;
      final addonPrice = (data['price'] as num?)?.toDouble() ?? 0.0;
      addonsTotal += qty * addonPrice;
    });

    // ✅ Only item price multiplies by quantity
    return (price * quantity) + addonsTotal;
  }

  factory OrderItems.fromJson(Map<String, dynamic> json) {
    // Safe parsing of addOns
    final addOnsData = json['addOns'];
    final addOns = <String, Map<String, dynamic>>{};
    if (addOnsData != null && addOnsData is Map) {
      addOnsData.forEach((key, value) {
        addOns[key] = {
          'quantity': value?['quantity'] ?? 0,
          'price': (value?['price'] as num?)?.toDouble() ?? 0.0,
        };
      });
    }

    // Safe parsing of modifiers
    final modifiers = (json['modifiers'] as List?)?.map((e) => e.toString()).toList() ?? [];

    // Safe parsing of section
    final section = (json['section'] != null && json['section'] is Map<String, dynamic>)
        ? Category.fromJson(json['section'])
        : Category(
      id: '0', // ✅ fallback as String
      name: 'Unknown',
      imagepath: '',
      subCategories: [],
    );
    /// 🔹 tax class from WooCommerce Tax API
    final taxClass = (json['class'] as String?)?.trim();

// fallback

    return OrderItems(
      productId: json['productId'] ?? 0,
      variationId: json['variationId'],  // ✅ FIXED
      name: json['name']?.toString() ??
          json['item_name']?.toString() ??
          'Unknown',
      quantity: json['quantity'] ?? 1,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
        //  ✅ amount includes modifier price
    amount: (json['amount'] as num?)?.toDouble() ??
        (((json['price'] as num?)?.toDouble() ?? 0.0) * (json['quantity'] ?? 1)),

    addOns: addOns,
      modifiers: modifiers,
      note: json['note']?.toString() ?? '',
      section: section,
      taxClass: taxClass,
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
      'tax_class': taxClass,
      // 'section': section.toJson(),
      // ✅ SAFE: only include section if not null
      if (section != null) 'section': section!.toJson(),
    };
  }

  OrderItems copyWith({
    int? productId,
    int? variationId,
    String? name,
    int? quantity,
    double? price,
    double? amount,
    List<String>? modifiers,
    Map<String, Map<String, dynamic>>? addOns,
    String? note,
    Category? section,
    String? taxClass,

  }) {
    return OrderItems(
      productId: productId ?? this.productId,
      variationId: variationId ?? this.variationId, // ✅ include here
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      amount: amount ?? this.amount,
      price: price ?? this.price,
      modifiers: modifiers ?? List<String>.from(this.modifiers),
      addOns: addOns ?? Map<String, Map<String, dynamic>>.from(this.addOns),
      note: note ?? this.note,
      section: section ?? this.section,
        taxClass: taxClass ?? this.taxClass,
    );
  }
}
