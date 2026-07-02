class TakeAwayOrderModel {
  final int orderId;
  final int restaurantId;
  final String status;
  final String orderType;

  TakeAwayOrderModel({
    required this.orderId,
    required this.restaurantId,
    required this.status,
    required this.orderType,
  });

  factory TakeAwayOrderModel.fromJson(Map<String, dynamic> json) {
    return TakeAwayOrderModel(
      orderId: json['order_id'] ?? 0,
      restaurantId: json['restaurant_id'] ?? 0,
      status: json['status'] ?? '',
      orderType: json['order_type'] ?? '',
    );
  }
}