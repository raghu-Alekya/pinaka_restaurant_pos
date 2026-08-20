class KotLineItemsResponse {
  final int restaurantId;
  final int zoneId;
  final int kotId;
  final double kotTotal;
  final String kotNumber;
  final String placedByName;

  // Current/editable items
  final List<KotItem> items;
  final List<VoidedKotItem> voidedItems;
  // Original KOT items
  final List<InitialKotItem> initialKotItems;

  KotLineItemsResponse({
    required this.restaurantId,
    required this.zoneId,
    required this.kotId,
    required this.kotTotal,
    required this.kotNumber,
    required this.items,
    required this.initialKotItems,
    required this.placedByName,
    required this.voidedItems,
  });

  factory KotLineItemsResponse.fromJson(Map<String, dynamic> json) {
    return KotLineItemsResponse(
      restaurantId: json["restaurant_id"] ?? 0,
      zoneId: json["zone_id"] ?? 0,
      kotId: json["kot_id"] ?? 0,
      kotTotal: (json["kot_total"] ?? 0).toDouble(),
      kotNumber: json["kot_number"] ?? "",
      // ⭐ Add this
      placedByName: json["placed_by_name"]?.toString() ?? "",
      // Editable/current items
      items: (json["items"] as List? ?? [])
          .map((e) => KotItem.fromJson(e))
          .toList(),
      voidedItems: (json['voided_items'] as List? ?? [])
          .map((e) => VoidedKotItem.fromJson(e))
          .toList(),
      // Original KOT items
      initialKotItems: (json["initial_kot_items"] as List? ?? [])
          .map((e) => InitialKotItem.fromJson(e))
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
  final int originalQuantity;

  final double price;
  double amount;

  final List<String> modifiers;
  final String isCancelled;

  KotItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.attributes,
    required this.quantity,
    required this.originalQuantity,
    required this.price,
    required this.amount,
    required this.modifiers,
    this.isCancelled = 'no',
  });

  factory KotItem.fromJson(Map<String, dynamic> json) {
    return KotItem(
      id: json["id"] ?? 0,
      productId: json["product_id"] ?? 0,
      productName: json["product_name"] ?? "",
      attributes: json["attributes"] ?? [],

      quantity: json["quantity"] ?? 0,

      // ⭐ Original quantity from API
      originalQuantity: json["original_quantity"] ??
          json["quantity"] ??
          0,

      price: (json["price"] ?? 0).toDouble(),
      amount: (json["amount"] ?? 0).toDouble(),

      modifiers: (json["modifiers"] as List? ?? [])
          .map((e) => e.toString())
          .toList(),

      isCancelled: json["is_cancelled"]?.toString() ?? 'no',
    );
  }

  KotItem copyWith({
    int? id,
    int? productId,
    String? productName,
    List<dynamic>? attributes,
    int? quantity,
    int? originalQuantity,
    double? price,
    double? amount,
    List<String>? modifiers,
    String? isCancelled,
  }) {
    return KotItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      attributes: attributes ?? List<dynamic>.from(this.attributes),

      quantity: quantity ?? this.quantity,

      originalQuantity:
      originalQuantity ?? this.originalQuantity,

      price: price ?? this.price,
      amount: amount ?? this.amount,

      modifiers: modifiers ??
          List<String>.from(this.modifiers),

      isCancelled:
      isCancelled ?? this.isCancelled,
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
class InitialKotItem {
  final int kotOrderId;
  final int lineItemId;
  final int productId;
  final String name;
  final int quantity;
  final double modifierAmount;
  final List<String> modifiers;
  final List<dynamic> comboItems;
  final double totalWoTax;
  final double taxTotal;
  final double totalWithTax;

  InitialKotItem({
    required this.kotOrderId,
    required this.lineItemId,
    required this.productId,
    required this.name,
    required this.quantity,
    required this.modifierAmount,
    required this.modifiers,
    required this.comboItems,
    required this.totalWoTax,
    required this.taxTotal,
    required this.totalWithTax,
  });

  factory InitialKotItem.fromJson(Map<String, dynamic> json) {
    return InitialKotItem(
      kotOrderId: json["kot_order_id"] ?? 0,
      lineItemId: json["line_item_id"] ?? 0,
      productId: json["product_id"] ?? 0,
      name: json["name"] ?? "",
      quantity: json["quantity"] ?? 0,
      modifierAmount: (json["modifier_amount"] ?? 0).toDouble(),
      modifiers: (json["modifiers"] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      comboItems: json["combo_items"] as List? ?? [],
      totalWoTax: (json["total_wo_tax"] ?? 0).toDouble(),
      taxTotal: (json["tax_total"] ?? 0).toDouble(),
      totalWithTax: (json["total_with_tax"] ?? 0).toDouble(),
    );
  }

  // ADD THIS
  InitialKotItem copyWith({
    int? kotOrderId,
    int? lineItemId,
    int? productId,
    String? name,
    int? quantity,
    double? modifierAmount,
    List<String>? modifiers,
    List<dynamic>? comboItems,
    double? totalWoTax,
    double? taxTotal,
    double? totalWithTax,
  }) {
    return InitialKotItem(
      kotOrderId: kotOrderId ?? this.kotOrderId,
      lineItemId: lineItemId ?? this.lineItemId,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      modifierAmount: modifierAmount ?? this.modifierAmount,
      modifiers: modifiers ?? List<String>.from(this.modifiers),
      comboItems: comboItems ?? List<dynamic>.from(this.comboItems),
      totalWoTax: totalWoTax ?? this.totalWoTax,
      taxTotal: taxTotal ?? this.taxTotal,
      totalWithTax: totalWithTax ?? this.totalWithTax,
    );
  }
  KotItem toKotItem() {
    return KotItem(
      id: lineItemId,
      productId: productId,
      productName: name,
      attributes: List<dynamic>.from(comboItems),
      quantity: quantity,
      originalQuantity: quantity,
      price: quantity > 0 ? totalWithTax / quantity : 0.0,
      amount: totalWithTax,
      modifiers: List<String>.from(modifiers),
    );
  }
}

class VoidedKotItem {
  final int itemId;
  final String product;
  final int newQty;
  final String remarks;
  final int voidedBy;
  final String voidedAt;

  VoidedKotItem({
    required this.itemId,
    required this.product,
    required this.newQty,
    required this.remarks,
    required this.voidedBy,
    required this.voidedAt,
  });

  factory VoidedKotItem.fromJson(Map<String, dynamic> json) {
    return VoidedKotItem(
      itemId: json['item_id'] ?? 0,
      product: json['product'] ?? '',
      newQty: json['new_qty'] ?? 0,
      remarks: json['remarks'] ?? '',
      voidedBy: json['voided_by'] ?? 0,
      voidedAt: json['voided_at'] ?? '',
    );
  }
}