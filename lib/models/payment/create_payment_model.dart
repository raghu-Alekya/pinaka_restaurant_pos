class CreatePaymentRequest {
  final int orderId;
  final String title;
  final double amount;
  final String paymentMethod;
  final int shiftId;
  final int userId;
  final String ?transactionId;
  final String restaurantId;
  final Map<String, dynamic> notes;

  CreatePaymentRequest({
    required this.orderId,
    required this.title,
    required this.amount,
    required this.paymentMethod,
    required this.shiftId,
    required this.userId,
    this.transactionId,
    required this.restaurantId,
    required this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      "order_id": orderId,
      "title": title,
      "amount": amount,
      "payment_method": paymentMethod,
      "shift_id": shiftId,
      "user_id": userId,
      "transaction_id": transactionId,
      "restaurant_id": restaurantId,
      "notes": notes,
    };
  }
}
