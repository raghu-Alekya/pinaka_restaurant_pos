class PaymentResponse {
  final bool success;
  final String message;
  final int paymentId;
  final int orderId;
  final double paidAmount;
  final double totalPaid;
  final double remainingAmount;
  final double change;
  final double orderTotal;
  final String orderStatus;
  final bool isVoid;

  PaymentResponse({
    required this.success,
    required this.message,
    required this.paymentId,
    required this.orderId,
    required this.paidAmount,
    required this.totalPaid,
    required this.remainingAmount,
    required this.change,
    required this.orderTotal,
    required this.orderStatus,
    required this.isVoid,
  });

  factory PaymentResponse.fromJson(Map<String, dynamic> json) {
    return PaymentResponse(
      success: json['success'],
      message: json['message'],
      paymentId: json['payment_id'],
      orderId: json['order_id'],
      paidAmount: (json['paid_amount'] ?? 0).toDouble(),
      totalPaid: (json['total_paid'] ?? 0).toDouble(),
      remainingAmount: (json['remaining_amount'] ?? 0).toDouble(),
      change: (json['change'] ?? 0).toDouble(),
      orderTotal: (json['order_total'] ?? 0).toDouble(),
      orderStatus: json['order_status'],
      isVoid: json['void'],
    );
  }
}
