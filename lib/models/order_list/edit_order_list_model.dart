class OrderListLineItems {
  final int id;       // Woo order LINE ITEM ID
  final int quantity;

  OrderListLineItems({required this.id, required this.quantity});

  Map<String, dynamic> toJson() => {
    'id': id,
    'quantity': quantity,
  };
}

class OrderListMetaData {
  final String key;
  final String value;

  OrderListMetaData({required this.key, required this.value});

  Map<String, dynamic> toJson() => {
    'key': key,
    'value': value,
  };
}

class EditOrderRequest {
  final List<OrderListLineItems> lineItems;
  final List<OrderListMetaData> metaData;

  EditOrderRequest({
    required this.lineItems,
    required this.metaData,
  });

  Map<String, dynamic> toJson() => {
    'line_items': lineItems.map((e) => e.toJson()).toList(),
    'meta_data': metaData.map((e) => e.toJson()).toList(),
  };
}
class CancelOrderResponse {
  final bool success;
  final String message;
  final dynamic data;

  CancelOrderResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory CancelOrderResponse.fromJson(Map<String, dynamic> json) {
    return CancelOrderResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'],
    );
  }
}
// kot_edit_reason_model.dart
class KotEditReasonModel {
  final List<String> reasons;

  KotEditReasonModel({required this.reasons});

  factory KotEditReasonModel.fromJson(Map<String, dynamic> json) {
    return KotEditReasonModel(
      reasons: List<String>.from(json['reasons'] ?? []),
    );
  }
}
class VoidedItemsResponse {
  final int kotId;
  final int count;
  final List<VoidedItem> items;

  VoidedItemsResponse({
    required this.kotId,
    required this.count,
    required this.items,
  });

  factory VoidedItemsResponse.fromJson(Map<String, dynamic> json) {
    return VoidedItemsResponse(
      kotId: json['kot_id'] ?? 0,
      count: json['count'] ?? 0,
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => VoidedItem.fromJson(e))
          .toList(),
    );
  }
}
class VoidedItem {
  final int itemId;
  final String product;
  final int origQty;
  final int newQty;
  final double itemTotal;
  final String remarks;
  final int voidedBy;
  final DateTime voidedAt;

  VoidedItem({
    required this.itemId,
    required this.product,
    required this.origQty,
    required this.newQty,
    required this.itemTotal,
    required this.remarks,
    required this.voidedBy,
    required this.voidedAt,
  });

  factory VoidedItem.fromJson(Map<String, dynamic> json) {
    return VoidedItem(
      itemId: json['item_id'] ?? 0,
      product: json['product'] ?? '',
      origQty: json['orig_qty'] ?? 0,
      newQty: json['new_qty'] ?? 0,
      itemTotal: double.tryParse(json['item_total']?.toString() ?? '0') ?? 0.0,
      remarks: json['remarks'] ?? '',
      voidedBy: json['voided_by'] ?? 0,
      voidedAt: DateTime.parse(json['voided_at']),
    );
  }
}