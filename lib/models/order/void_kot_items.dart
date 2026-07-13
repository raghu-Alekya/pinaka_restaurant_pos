class KotLineItemsResponse {
  final int restaurantId;
  final int zoneId;
  final int kotId;
  final double kotTotal;
  final String kotNumber;
  final List<KotItem> items;

  KotLineItemsResponse({
    required this.restaurantId,
    required this.zoneId,
    required this.kotId,
    required this.kotTotal,
    required this.kotNumber,
    required this.items,
  });

  factory KotLineItemsResponse.fromJson(Map<String, dynamic> json) {
    return KotLineItemsResponse(
      restaurantId: json["restaurant_id"] ?? 0,
      zoneId: json["zone_id"] ?? 0,
      kotId: json["kot_id"] ?? 0,
      kotTotal: (json["kot_total"] ?? 0).toDouble(),
      kotNumber: json["kot_number"] ?? "",
      items: (json["items"] as List? ?? [])
          .map((e) => KotItem.fromJson(e))
          .toList(),
    );
  }
}

class KotItem {
  final int id;
  final int productId;
  final String productName;
  final List<dynamic> attributes;
  int quantity;
  final double price;
  double amount;
  final List<String> modifiers;
  final String isCancelled; // ✅ ADDED: 'yes' or 'no'

  KotItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.attributes,
    required this.quantity,
    required this.price,
    required this.amount,
    required this.modifiers,
    this.isCancelled = 'no', // ✅ ADDED with default
  });

  factory KotItem.fromJson(Map<String, dynamic> json) {
    return KotItem(
      id: json["id"] ?? 0,
      productId: json["product_id"] ?? 0,
      productName: json["product_name"] ?? "",
      attributes: json["attributes"] ?? [],
      quantity: json["quantity"] ?? 0,
      price: (json["price"] ?? 0).toDouble(),
      amount: (json["amount"] ?? 0).toDouble(),
      modifiers: (json["modifiers"] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      isCancelled: json["is_cancelled"]?.toString() ?? 'no', // ✅ PARSE
    );
  }

  KotItem copyWith({
    int? id,
    int? productId,
    String? productName,
    List<dynamic>? attributes,
    int? quantity,
    double? price,
    double? amount,
    List<String>? modifiers,
    String? isCancelled, // ✅ ADDED
  }) {
    return KotItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      attributes: attributes ?? List<dynamic>.from(this.attributes),
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      amount: amount ?? this.amount,
      modifiers: modifiers ?? List<String>.from(this.modifiers),
      isCancelled: isCancelled ?? this.isCancelled, // ✅ ADDED
    );
  }
}

// ─── Other classes remain unchanged ───

class UpdatekotRequest {
  final List<LineItemUpdate> lineItems;
  final List<MetaDataItem> metaData;

  UpdatekotRequest({
    required this.lineItems,
    required this.metaData,
  });

  Map<String, dynamic> toJson() {
    return {
      "line_items": lineItems.map((e) => e.toJson()).toList(),
      "meta_data": metaData.map((e) => e.toJson()).toList(),
    };
  }
}

class LineItemUpdate {
  final int id;
  final int productId;
  final int quantity;

  LineItemUpdate({
    required this.id,
    required this.productId,
    required this.quantity,
  });

  Map<String, dynamic> toJson() => {
    "id": id,
    "product_id": productId,
    "quantity": quantity,
  };
}

class MetaDataItem {
  final String key;
  final dynamic value;

  MetaDataItem({
    required this.key,
    required this.value,
  });

  Map<String, dynamic> toJson() => {
    "key": key,
    "value": value,
  };
}

class UpdatekotResponse {
  final int id;
  final String status;
  final List<dynamic> lineItems;

  UpdatekotResponse({
    required this.id,
    required this.status,
    required this.lineItems,
  });

  factory UpdatekotResponse.fromJson(Map<String, dynamic> json) {
    return UpdatekotResponse(
      id: json["id"] ?? 0,
      status: json["status"] ?? "",
      lineItems: json["line_items"] ?? [],
    );
  }
}