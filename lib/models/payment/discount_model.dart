class DiscountReasonResponse {
  final String status;
  final String message;
  final List<String> reasons;

  DiscountReasonResponse({
    required this.status,
    required this.message,
    required this.reasons,
  });

  factory DiscountReasonResponse.fromJson(Map<String, dynamic> json) {
    return DiscountReasonResponse(
      status: json['status'],
      message: json['message'],
      reasons: List<String>.from(json['reason_list'] ?? []),
    );
  }
}
// models/discount/add_discount_request.dart
class AddDiscountRequest {
  final int orderId;
  final double amount;
  final String isNc;
  final String reason;

  AddDiscountRequest({
    required this.orderId,
    required this.amount,
    required this.isNc,
    required this.reason,
  });

  Map<String, dynamic> toJson() {
    return {
      "order_id": orderId,
      "amount": amount,
      "is_nc": isNc,
      "reason": reason,
    };
  }
}
// models/discount/add_discount_response.dart
class AddDiscountResponse {
  final bool success;
  final String message;

  AddDiscountResponse({
    required this.success,
    required this.message,
  });

  factory AddDiscountResponse.fromJson(Map<String, dynamic> json) {
    return AddDiscountResponse(
      success: json['success'] ?? true,
      message: json['message'] ?? 'Discount applied successfully',
    );
  }
}
