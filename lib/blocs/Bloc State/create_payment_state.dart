import '../../models/payment/payment_response_model.dart';

abstract class CreatePaymentState{}

class CreatePaymentInitial extends  CreatePaymentState {}

class CreatePaymentLoading extends  CreatePaymentState {}

class CreatePaymentSuccess extends  CreatePaymentState {
  final PaymentResponse response;
  final double orderTotal;

  CreatePaymentSuccess(this.response)
      : orderTotal = response.orderTotal;
}


class CreatePaymentFailure extends  CreatePaymentState {
  final String error;

  CreatePaymentFailure(this.error);
}
