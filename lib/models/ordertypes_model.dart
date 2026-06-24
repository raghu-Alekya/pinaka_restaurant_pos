class OrderTypesInPaymentScreenModel {
  final bool success;
  final List<String> orderTypes;

  OrderTypesInPaymentScreenModel({
    required this.success,
    required this.orderTypes,
  });

  factory OrderTypesInPaymentScreenModel.fromJson(Map<String, dynamic> json) {
    return OrderTypesInPaymentScreenModel(
      success: json['success'] ?? false,
      orderTypes: List<String>.from(json['order_types'] ?? []),
    );
  }
}

class OrderTypesInPaymentScreenUpdateModel {
  final bool success;
  final String message;
  final int orderId;
  final String orderType;

  OrderTypesInPaymentScreenUpdateModel({
    required this.success,
    required this.message,
    required this.orderId,
    required this.orderType,
  });

  factory OrderTypesInPaymentScreenUpdateModel.fromJson(
      Map<String, dynamic> json,
      ) {
    return OrderTypesInPaymentScreenUpdateModel(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      orderId: json['order_id'] ?? 0,
      orderType: json['order_type'] ?? '',
    );
  }
}