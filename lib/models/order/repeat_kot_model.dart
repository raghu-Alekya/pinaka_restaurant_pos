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

  KotLineItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
  });

  factory KotLineItem.fromJson(Map<String, dynamic> json) {
    return KotLineItem(
      productId: json['product_id'] ?? 0,
      name: json['product_name'] ?? 'Unknown',
      price: _parseDouble(json['product_price']),
      quantity: _parseInt(json['quantity']),
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



