import '../../models/payment/payment_summary_model.dart';

abstract class PaymentState {}

class PaymentInitial extends PaymentState {}

class PaymentLoading extends PaymentState {}

class PaymentSummaryLoaded extends PaymentState {
  final PaymentSummary summary;
  final String? selectedMethod;

  // ✅ ADD THIS FIELD
  final double merchantDiscount;

  PaymentSummaryLoaded({
    required this.summary,
    this.selectedMethod,
    this.merchantDiscount = 0.0, // ✅ default
  });

  // ✅ copyWith helper (recommended)
  PaymentSummaryLoaded copyWith({
    PaymentSummary? summary,
    String? selectedMethod,
    double? merchantDiscount,
  }) {
    return PaymentSummaryLoaded(
      summary: summary ?? this.summary,
      selectedMethod: selectedMethod ?? this.selectedMethod,
      merchantDiscount: merchantDiscount ?? this.merchantDiscount,
    );
  }
}

class PaymentSuccess extends PaymentState {
  final String receiptId;
  PaymentSuccess(this.receiptId);
}

class PaymentFailure extends PaymentState {
  final String message;
  PaymentFailure(this.message);
}
