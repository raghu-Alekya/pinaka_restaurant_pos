class KotStatusCountModel {
  final String message;
  final int restaurantId;
  final int statusCount;
  final int customerCount;

  KotStatusCountModel({
    required this.message,
    required this.restaurantId,
    required this.statusCount,
    required this.customerCount,
  });

  factory KotStatusCountModel.fromJson(Map<String, dynamic> json) {
    return KotStatusCountModel(
      message: json["message"] ?? "",
      restaurantId: json["restaurant_id"] ?? 0,
      statusCount: json["status_count"] ?? 0,
      customerCount: json["customer_count"] ?? 0,
    );
  }
}
class KotOrderCountModel {
  final bool success;
  final int totalOrderCount;

  KotOrderCountModel({
    required this.success,
    required this.totalOrderCount,
  });

  factory KotOrderCountModel.fromJson(Map<String, dynamic> json) {
    return KotOrderCountModel(
      success: json['success'] ?? false,
      totalOrderCount: json['total_order_count'] ?? 0,
    );
  }
}