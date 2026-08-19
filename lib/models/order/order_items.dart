import '../sidebar/category_model_.dart';

class OrderItems {
  final int? id;
  final bool isVeg;
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

  // ✅ NEW - isCancelled field
  final String isCancelled; // 'yes' or 'no'

  OrderItems({
    this.id,

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
    required this.amount,
    this.isVeg = false,
    this.isCancelled = 'no', // ✅ Added with default value
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

    // ==========================================================
    // ADD-ONS
    // ==========================================================

    final addOns = <String, Map<String, dynamic>>{};

    // First try direct addOns
    final directAddOns =
        json['addOns'] ?? json['addons'] ?? json['add_ons'];

    if (directAddOns is Map) {
      directAddOns.forEach((key, value) {
        if (value is Map) {
          addOns[key.toString()] = {
            'quantity': value['quantity'] ?? value['qty'] ?? 1,
            'price': (value['price'] as num?)?.toDouble() ?? 0.0,
          };
        }
      });
    }

    // If direct addOns are empty, check meta_data
    if (addOns.isEmpty) {
      final metaData = json['meta_data'];

      if (metaData is List) {
        for (final meta in metaData) {
          if (meta is Map &&
              meta['key']?.toString() == '_addons') {

            final value = meta['value'];

            if (value is List) {
              for (final addon in value) {
                if (addon is Map) {
                  final name =
                      addon['name']?.toString() ?? '';

                  if (name.isNotEmpty) {
                    addOns[name] = {
                      'quantity':
                      addon['quantity'] ?? 1,
                      'price':
                      (addon['price'] as num?)
                          ?.toDouble() ??
                          0.0,
                    };
                  }
                }
              }
            }

            break;
          }
        }
      }
    }

    // ==========================================================
    // MODIFIERS
    // ==========================================================

    List<String> parsedModifiers = [];

    // Direct modifiers
    if (json['modifiers'] is List) {
      parsedModifiers = (json['modifiers'] as List)
          .map((e) {
        if (e is Map) {
          return e['name']?.toString() ??
              e['modifier_name']?.toString() ??
              '';
        }

        return e.toString();
      })
          .where((e) => e.isNotEmpty)
          .toList();
    }

    // Meta-data modifiers
    if (parsedModifiers.isEmpty) {
      final metaData = json['meta_data'];

      if (metaData is List) {
        for (final meta in metaData) {
          if (meta is Map &&
              meta['key']?.toString() == '_modifiers') {

            final value = meta['value'];

            if (value is List) {
              parsedModifiers = value
                  .map((e) {
                if (e is Map) {
                  return e['name']?.toString() ??
                      e['modifier_name']?.toString() ??
                      '';
                }

                return e.toString();
              })
                  .where((e) => e.isNotEmpty)
                  .toList();
            }

            break;
          }
        }
      }
    }

    // ==========================================================
    // NOTE
    // ==========================================================

    String parsedNote =
        json['note']?.toString() ??
            json['notes']?.toString() ??
            '';

    if (parsedNote.trim().isEmpty) {
      final metaData = json['meta_data'];

      if (metaData is List) {
        for (final meta in metaData) {
          if (meta is Map &&
              meta['key']?.toString() == '_modifier_notes') {

            parsedNote =
                meta['value']?.toString() ?? '';

            break;
          }
        }
      }
    }

    // ==========================================================
    // VEG / NON-VEG
    // ==========================================================

    final dynamic vegValue =
        json['is_veg'] ??
            json['isVeg'] ??
            json['is_vegetarian'] ??
            json['veg'];

    final bool parsedIsVeg =
        vegValue == true ||
            vegValue == 1 ||
            vegValue
                ?.toString()
                .trim()
                .toLowerCase() ==
                'true' ||
            vegValue?.toString().trim() == '1';

    // ==========================================================
    // SECTION
    // ==========================================================

    final section =
    (json['section'] != null &&
        json['section'] is Map<String, dynamic>)
        ? Category.fromJson(json['section'])
        : Category(
      id: '0',
      name: 'Unknown',
      imagepath: '',
      subCategories: [],
    );

    // ==========================================================
    // TAX
    // ==========================================================

    final taxClass =
    (json['class'] as String?)?.trim();

    // ==========================================================
    // CANCELLED
    // ==========================================================

    final isCancelled =
        json['is_cancelled']?.toString() ?? 'no';

    // ==========================================================
    // RETURN
    // ==========================================================

    return OrderItems(
      id: (json['id'] as num?)?.toInt(),

      productId:
      (json['productId'] ??
          json['product_id'] ??
          0) as int,

      variationId:
      json['variationId'] ??
          json['variation_id'],

      name:
      json['name']?.toString() ??
          json['item_name']?.toString() ??
          json['product_name']?.toString() ??
          'Unknown',

      isVeg: parsedIsVeg,

      quantity:
      (json['quantity'] as num?)?.toInt() ??
          1,

      price:
      (json['price'] as num?)?.toDouble() ??
          0,

      amount:
      (json['amount'] as num?)?.toDouble() ??
          (((json['price'] as num?)?.toDouble() ?? 0) *
              ((json['quantity'] as num?)?.toInt() ?? 1)),

      modifiers: parsedModifiers,

      addOns: addOns,

      note: parsedNote,

      section: section,

      taxClass: taxClass,

      hasOptions:
      json['hasOptions'] ??
          json['has_options'] ??
          false,

      isCancelled: isCancelled,
    );
  }

  Map<String, dynamic> toJson() {
    final serializedAddOns = addOns.map((key, value) => MapEntry(key, {
      'quantity': value['quantity'],
      'price': value['price'],
    }));

    return {
      'id': id,
      'productId': productId,
      if (variationId != null) 'variationId': variationId, // ✅ only if exists
      'name': name,
      'quantity': quantity,
      'is_veg': isVeg,
      'price': price,
      'modifiers': modifiers,
      'addOns': serializedAddOns,
      'note': note,
      'tax_class': taxClass,
      'hasOptions': hasOptions,
      'is_cancelled': isCancelled, // ✅ Added to JSON
      // ✅ SAFE: only include section if not null
      if (section != null) 'section': section!.toJson(),
    };
  }

  OrderItems copyWith({
    int? id,
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
    bool? hasOptions,
    bool? isVeg,             // ✅ ADD THIS
    String? isCancelled,
  }) {
    return OrderItems(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      variationId: variationId ?? this.variationId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      amount: amount ?? this.amount,
      price: price ?? this.price,
      modifiers: modifiers ?? List<String>.from(this.modifiers),
      addOns: addOns ??
          Map<String, Map<String, dynamic>>.from(this.addOns),
      note: note ?? this.note,
      section: section ?? this.section,
      taxClass: taxClass ?? this.taxClass,
      hasOptions: hasOptions ?? this.hasOptions,

      // ✅ Preserve Veg / Non-Veg value
      isVeg: isVeg ?? this.isVeg,

      isCancelled: isCancelled ?? this.isCancelled,
    );
  }
}