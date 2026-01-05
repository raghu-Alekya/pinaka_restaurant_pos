import '../../models/payment/payment_response_model.dart';

abstract class PaymentState {}

class PaymentInitial extends PaymentState {}

class PaymentLoading extends PaymentState {}

class PaymentSuccess extends PaymentState {
  final PaymentResponse response;
  final double orderTotal;

  PaymentSuccess(this.response)
      : orderTotal = response.orderTotal;
}


class PaymentFailure extends PaymentState {
  final String error;

  PaymentFailure(this.error);
}
