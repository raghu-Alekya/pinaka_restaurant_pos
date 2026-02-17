abstract class PaymentEvent {}

class LoadPaymentSummary extends PaymentEvent {
  final String restaurantId;
  final int orderId;
  final int? zoneId;
  final String orderType;

  LoadPaymentSummary({
    required this.restaurantId,
    required this.orderId,
    this.zoneId,
    required this.orderType,
    required String token,
  });
}

class SelectPaymentMethod extends PaymentEvent {
  final String method; // Cash / Card / UPI
  SelectPaymentMethod(this.method);
}

class ConfirmPayment extends PaymentEvent {
  final double paidAmount;
  ConfirmPayment(this.paidAmount);
}

class ResetPayment extends PaymentEvent {}
/// ✅ ADD THIS EVENT
class UpdateMerchantDiscount extends PaymentEvent {
  final double value;
  UpdateMerchantDiscount(this.value);
}


