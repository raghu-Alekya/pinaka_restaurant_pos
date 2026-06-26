class CouponModel {
  final int id;
  final String code;
  final String description;
  final String discountType;
  final double amount;

  CouponModel({
    required this.id,
    required this.code,
    required this.description,
    required this.discountType,
    required this.amount,
  });

  factory CouponModel.fromJson(Map<String, dynamic> json) {
    return CouponModel(
      id: json['id'] ?? 0,
      code: json['code'] ?? '',
      description: json['description'] ?? '',
      discountType: json['discount_type'] ?? '',
      amount: double.tryParse(
        json['amount']?.toString() ?? '0',
      ) ??
          0.0,
    );
  }
}
class CouponResponse {
  final bool success;
  final String message;

  CouponResponse({
    required this.success,
    required this.message,
  });
}