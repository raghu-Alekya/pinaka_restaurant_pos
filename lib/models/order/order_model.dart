class OrderModel {
  final int orderId;
  final int tableId;
  final String tableName;
  final int zoneId;
  final String zoneName;
  final String status;

  // Order item fields
  final int itemId;
  final int productId;
  final String itemName;
  final int quantity;
  final double price;
  final double amount;

  OrderModel({
    required this.orderId,
    required this.tableId,
    required this.tableName,
    required this.zoneId,
    required this.zoneName,
    required this.status,
    required this.itemId,
    required this.productId,
    required this.itemName,
    required this.quantity,
    required this.price,
    required this.amount,
  });

  /// Convenience getter
  int get id => orderId;

  /// Factory: parse JSON safely
  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;

    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return OrderModel(
      orderId: parseInt(data['order_id']),
      tableId: parseInt(data['table_id']),
      tableName: data['table_name']?.toString() ?? '',
      zoneId: parseInt(data['zone_id']),
      zoneName: data['zone_name']?.toString() ?? '',
      status: data['status']?.toString() ?? '',
      itemId: parseInt(data['id']),
      productId: parseInt(data['product_id']),
      itemName: data['item_name']?.toString() ?? '',
      quantity: parseInt(data['quantity']),
      price: parseDouble(data['price']),
      amount: parseDouble(data['amount']),
    );
  }

  /// Convert back to JSON
  Map<String, dynamic> toJson() {
    return {
      "order_id": orderId,
      "table_id": tableId,
      "table_name": tableName,
      "zone_id": zoneId,
      "zone_name": zoneName,
      "status": status,
      "id": itemId,
      "product_id": productId,
      "item_name": itemName,
      "quantity": quantity,
      "price": price,
      "amount": amount,
    };
  }

  /// Copy with optional updates
  OrderModel copyWith({
    int? orderId,
    int? tableId,
    String? tableName,
    int? zoneId,
    String? zoneName,
    String? status,
    int? itemId,
    int? productId,
    String? itemName,
    int? quantity,
    double? price,
    double? amount,
  }) {
    return OrderModel(
      orderId: orderId ?? this.orderId,
      tableId: tableId ?? this.tableId,
      tableName: tableName ?? this.tableName,
      zoneId: zoneId ?? this.zoneId,
      zoneName: zoneName ?? this.zoneName,
      status: status ?? this.status,
      itemId: itemId ?? this.itemId,
      productId: productId ?? this.productId,
      itemName: itemName ?? this.itemName,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      amount: amount ?? this.amount,
    );
  }
}
