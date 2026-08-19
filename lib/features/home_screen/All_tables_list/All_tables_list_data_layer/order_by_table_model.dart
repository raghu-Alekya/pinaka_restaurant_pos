// lib/features/home_screen/order_by_table/data/models/order_by_table_model.dart

class OrderByTableResponse {
  final int restaurantId;
  final int orderId;
  final String orderType;
  final String tableStatus;
  final String tableName;
  final int guestCount;
  final int zoneId;
  final String zoneName;
  final List<KotOrder> kotOrders;

  OrderByTableResponse({
    required this.restaurantId,
    required this.orderId,
    required this.orderType,
    required this.tableStatus,
    required this.tableName,
    required this.guestCount,
    required this.zoneId,
    required this.zoneName,
    required this.kotOrders,
  });

  factory OrderByTableResponse.fromJson(Map<String, dynamic> json) {
    return OrderByTableResponse(
      restaurantId: json['restaurant_id'] ?? 0,
      orderId: json['order_id'] ?? 0,
      orderType: json['order_type'] ?? '',
      tableStatus: json['tableStatus'] ?? '',
      tableName: json['table_name'] ?? '',
      guestCount: json['guest_count'] ?? 0,
      zoneId: json['zone_id'] ?? 0,
      zoneName: json['zone_name'] ?? '',
      kotOrders: (json['kot_orders'] as List?)
          ?.map((e) => KotOrder.fromJson(e))
          .toList() ??
          [],
    );
  }
}

class KotOrder {
  final int id;
  final String time;
  final String status;
  final double total;
  final String kotNumber;
  final List<LineItem> lineItems;

  KotOrder({
    required this.id,
    required this.time,
    required this.status,
    required this.total,
    required this.kotNumber,
    required this.lineItems,
  });

  factory KotOrder.fromJson(Map<String, dynamic> json) {
    return KotOrder(
      id: json['id'] ?? 0,
      time: json['time'] ?? '',
      status: json['status'] ?? '',
      total: (json['total'] ?? 0).toDouble(),
      kotNumber: json['kot_number'] ?? '',
      lineItems: (json['line_items'] as List?)
          ?.map((e) => LineItem.fromJson(e))
          .toList() ??
          [],
    );
  }
}

class LineItem {
  final int id;
  final int productId;
  final String itemName;
  final int quantity;
  final double price;
  final double amount;
  final List<dynamic> modifiers;
  final List<dynamic> combos;
  final String isCancelled;
  final double originalPrice;

  LineItem({
    required this.id,
    required this.productId,
    required this.itemName,
    required this.quantity,
    required this.price,
    required this.amount,
    required this.modifiers,
    required this.combos,
    this.isCancelled = 'no', // ✅ Default value
    this.originalPrice = 0.0,
  });

  factory LineItem.fromJson(Map<String, dynamic> json) {
    return LineItem(
      id: json['id'] ?? 0,
      productId: json['product_id'] ?? 0,
      itemName: json['item_name'] ?? '',
      quantity: json['quantity'] ?? 0,
      price: (json['price'] ?? 0).toDouble(),
      amount: (json['amount'] ?? 0).toDouble(),
      modifiers: json['modifiers'] ?? [],
      combos: json['combos'] ?? [],
      isCancelled: (json['is_cancelled'] ?? 'no').toString(),
      originalPrice: (json['original_price'] as num?)?.toDouble() ?? 0.0,
    );
  }
}