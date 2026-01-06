// import '../../models/payment/payment_summary.dart';
import '../../models/payment/payment_summary_model.dart';

abstract class PaymentState {}

class PaymentInitial extends PaymentState {}

class PaymentLoading extends PaymentState {}

class PaymentSummaryLoaded extends PaymentState {
  final PaymentSummary summary;
  final String? selectedMethod;

  PaymentSummaryLoaded({
    required this.summary,
    this.selectedMethod,
  });
}

class PaymentSuccess extends PaymentState {
  final String receiptId;
  PaymentSuccess(this.receiptId);
}

class PaymentFailure extends PaymentState {
  final String message;
  PaymentFailure(this.message);
}
