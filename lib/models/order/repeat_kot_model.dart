// class RepeatKotModel {
//   final String flagType;
//   final int parentOrderId;
//   final int restaurantId;
//   final int zoneId;
//   final int captainId;
//   final List<KotLineItem> lineItems;
//
//   RepeatKotModel({
//     required this.flagType,
//     required this.parentOrderId,
//     required this.restaurantId,
//     required this.zoneId,
//     required this.captainId,
//     required this.lineItems,
//   });
//
//   factory RepeatKotModel.fromJson(Map<String, dynamic> json) {
//     return RepeatKotModel(
//       flagType: json['flag_type'] ?? 'REPEAT',
//       parentOrderId: json['parent_order_id'] ?? 0,
//       restaurantId: json['restaurant_id'] ?? 0,
//       zoneId: json['zone_id'] ?? 0,
//       captainId: json['captain_id'] ?? 0,
//       lineItems: (json['line_items'] as List? ?? [])
//           .map((e) => KotLineItem.fromJson(e))
//           .toList(),
//     );
//   }
//
// }
//
// class KotLineItem {
//   final int productId;
//   final String name;
//   final double price;
//   final int quantity;
//
//   KotLineItem({
//     required this.productId,
//     required this.name,
//     required this.price,
//     required this.quantity,
//   });
//
//   factory KotLineItem.fromJson(Map<String, dynamic> json) {
//     return KotLineItem(
//       productId: json['product_id'] ?? 0,
//       name: json['product_name'] ?? 'Unknown',
//       price: _parseDouble(json['product_price']),
//       quantity: _parseInt(json['quantity']),
//     );
//   }
//
//   // ✅ MUST be static
//   static double _parseDouble(dynamic value) {
//     if (value == null) return 0.0;
//     if (value is num) return value.toDouble();
//     if (value is String) return double.tryParse(value) ?? 0.0;
//     return 0.0;
//   }
//
//   static int _parseInt(dynamic value) {
//     if (value == null) return 0;
//     if (value is int) return value;
//     if (value is String) return int.tryParse(value) ?? 0;
//     return 0;
//   }
// }
//
//
//


class RepeatKotModel {
  final String flagType;
  final int parentOrderId;
  final int restaurantId;
  final int zoneId;
  final int captainId;
  final List<KotLineItem> lineItems;

  RepeatKotModel({
    required this.flagType,
    required this.parentOrderId,
    required this.restaurantId,
    required this.zoneId,
    required this.captainId,
    required this.lineItems,
  });

  factory RepeatKotModel.fromJson(Map<String, dynamic> json) {
    return RepeatKotModel(
      flagType: json['flag_type'] ?? 'REPEAT',
      parentOrderId: json['parent_order_id'] ?? 0,
      restaurantId: json['restaurant_id'] ?? 0,
      zoneId: json['zone_id'] ?? 0,
      captainId: json['captain_id'] ?? 0,
      lineItems: (json['line_items'] as List? ?? [])
          .map((e) => KotLineItem.fromJson(e))
          .toList(),
    );
  }
}

class KotLineItem {
  final int productId;
  final String name;
  final double price;
  final int quantity;
  final List<String> modifiers;
  final Map<String, Map<String, dynamic>> addOns;
  final String note;
  final bool hasOptions;
  final String isCancelled; // ✅ NEW: Added this field
  final Map<String, dynamic> rawJson;

  KotLineItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    this.modifiers = const [],
    this.addOns = const {},
    this.note = '',
    this.hasOptions = false,
    this.isCancelled = 'no', // ✅ Added with default value
    this.rawJson = const {},
  });

  factory KotLineItem.fromJson(Map<String, dynamic> json) {
    // MODIFIERS
    List<String> parsedModifiers = [];
    final directModifiers =
        json['modifiers'] ?? json['item_modifiers'] ?? json['selected_modifiers'];
    if (directModifiers is List) {
      parsedModifiers = directModifiers
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

    if (parsedModifiers.isEmpty) {
      final metaData = json['meta_data'];
      if (metaData is List) {
        for (final meta in metaData) {
          if (meta is Map && meta['key']?.toString() == '_modifiers') {
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

    // ADD-ONS
    final addOns = <String, Map<String, dynamic>>{};
    final directAddOns = json['addOns'] ?? json['addons'] ?? json['add_ons'];
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

    // NOTE
    String parsedNote =
        json['note']?.toString() ?? json['notes']?.toString() ?? '';

    // HAS OPTIONS
    final dynamic rawHasOptions =
        json['hasOptions'] ?? json['has_options'] ?? json['has_modifiers'];
    final bool parsedHasOptions = rawHasOptions == true ||
        rawHasOptions == 1 ||
        rawHasOptions?.toString().toLowerCase() == 'yes' ||
        rawHasOptions?.toString().toLowerCase() == 'true' ||
        parsedModifiers.isNotEmpty ||
        addOns.isNotEmpty;

    return KotLineItem(
      productId: json['product_id'] ?? json['productId'] ?? 0,
      name: json['product_name'] ?? json['name'] ?? json['item_name'] ?? 'Unknown',
      price: _parseDouble(json['product_price'] ?? json['price']),
      quantity: _parseInt(json['quantity'] ?? json['qty']),
      modifiers: parsedModifiers,
      addOns: addOns,
      note: parsedNote,
      hasOptions: parsedHasOptions,
      isCancelled: json['is_cancelled']?.toString() ?? 'no',
      rawJson: json,
    );
  }

  // ✅ MUST be static
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}