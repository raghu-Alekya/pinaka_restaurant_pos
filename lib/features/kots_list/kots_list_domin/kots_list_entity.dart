class KotOrder {
  final int id;
  final String time;
  final String status;
  final double total;
  final String kotNumber;
  final String? orderBy;
  final List<LineItem> lineItems;

  KotOrder({
    required this.id,
    required this.time,
    required this.status,
    required this.total,
    required this.kotNumber,
    this.orderBy,
    this.lineItems = const [],
  });

  // ─── Serialization (needed by KdsMqttPublisher) ───────────────────
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'time': time,
      'status': status,
      'total': total,
      'kot_number': kotNumber,
      'order_by': orderBy,
      'line_items': lineItems.map((e) => e.toJson()).toList(),
    };
  }

  factory KotOrder.fromJson(Map<String, dynamic> json) {
    return KotOrder(
      id: json['id'] as int? ?? 0,
      time: json['time']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      kotNumber: json['kot_number']?.toString() ?? '',
      orderBy: json['order_by']?.toString(),
      lineItems: (json['line_items'] as List<dynamic>?)
          ?.map((e) => LineItem.fromJson(Map<String, dynamic>.from(e)))
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

  LineItem({
    required this.id,
    required this.productId,
    required this.itemName,
    required this.quantity,
    required this.price,
    required this.amount,
    required this.modifiers,
    required this.combos,
    this.isCancelled = 'no',
  });

  // ─── Serialization ────────────────────────────────────────────────
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'item_name': itemName,
      'quantity': quantity,
      'price': price,
      'amount': amount,
      'modifiers': modifiers,
      'combos': combos,
      'is_cancelled': isCancelled,
    };
  }

  factory LineItem.fromJson(Map<String, dynamic> json) {
    return LineItem(
      id: json['id'] as int? ?? 0,
      productId: json['product_id'] as int? ?? 0,
      itemName: json['item_name']?.toString() ?? '',
      quantity: json['quantity'] as int? ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      modifiers: json['modifiers'] as List<dynamic>? ?? [],
      combos: json['combos'] as List<dynamic>? ?? [],
      isCancelled: json['is_cancelled']?.toString() ?? 'no',
    );
  }
}