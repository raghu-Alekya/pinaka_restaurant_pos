import '../../models/payment/payment_summary_model.dart';

abstract class PaymentState {}

class PaymentInitial extends PaymentState {}

class PaymentLoading extends PaymentState {}

class PaymentSummaryLoaded extends PaymentState {
  final PaymentSummary summary;
  final String? selectedMethod;

  // ✅ ADD THIS FIELD
  final double merchantDiscount;
  final bool isNoCharge;

  PaymentSummaryLoaded({
    required this.summary,
    this.selectedMethod,
    this.merchantDiscount = 0.0,
    this.isNoCharge = false,// ✅ default
  });

  // ✅ copyWith helper (recommended)
  PaymentSummaryLoaded copyWith({
    PaymentSummary? summary,
    String? selectedMethod,
    double? merchantDiscount,
    bool? isNoCharge,
  }) {
    return PaymentSummaryLoaded(
      summary: summary ?? this.summary,
      selectedMethod: selectedMethod ?? this.selectedMethod,
      merchantDiscount: merchantDiscount ?? this.merchantDiscount,
        isNoCharge: isNoCharge ?? this.isNoCharge,
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
