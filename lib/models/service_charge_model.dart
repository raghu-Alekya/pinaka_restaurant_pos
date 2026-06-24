class ServiceChargeResponse {
  final bool success;
  final int orderId;
  final int serviceChargePercentage;

  ServiceChargeResponse({
    required this.success,
    required this.orderId,
    required this.serviceChargePercentage,
  });

  factory ServiceChargeResponse.fromJson(Map<String, dynamic> json) {
    return ServiceChargeResponse(
      success: json['success'] ?? false,
      orderId: json['order_id'] ?? 0,
      serviceChargePercentage:
      json['service_charge_percentage'] ?? 0,
    );
  }
}