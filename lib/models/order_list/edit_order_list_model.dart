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