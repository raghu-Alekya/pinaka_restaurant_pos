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
  final String amount; // ✅ CHANGED to String
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
  final double discountAmt; // ✅ ADDED

  AddDiscountResponse({
    required this.success,
    required this.message,
    required this.discountAmt,
  });

  factory AddDiscountResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    final rawDiscountAmt = data != null ? data['discount_amt'] : 0.0;
    final double parsedAmt = double.tryParse(rawDiscountAmt.toString())?.abs() ?? 0.0;

    return AddDiscountResponse(
      success: (json['status'] ?? json['status_code'] ?? '').toString().toLowerCase() == 'success' || (json['success'] ?? false) == true,
      message: json['message'] ?? 'Discount applied successfully',
      discountAmt: parsedAmt,
    );
  }
}
class RemoveDiscountResponseModel {
  final String status;
  final String message;
  final RemoveDiscountData? data;

  RemoveDiscountResponseModel({
    required this.status,
    required this.message,
    this.data,
  });

  factory RemoveDiscountResponseModel.fromJson(Map<String, dynamic> json) {
    return RemoveDiscountResponseModel(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      data: json['data'] != null
          ? RemoveDiscountData.fromJson(json['data'])
          : null,
    );
  }
}

class RemoveDiscountData {
  final int orderId;
  final String isNoCharge;

  RemoveDiscountData({
    required this.orderId,
    required this.isNoCharge,
  });

  factory RemoveDiscountData.fromJson(Map<String, dynamic> json) {
    return RemoveDiscountData(
      orderId: json['order_id'] ?? 0,
      isNoCharge: json['is_nocharge'] ?? '',
    );
  }
}
