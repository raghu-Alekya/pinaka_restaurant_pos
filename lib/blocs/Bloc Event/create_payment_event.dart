import '../../models/payment/create_payment_model.dart';

abstract class PaymentEvent {}

class CreatePaymentEvent extends PaymentEvent {
  final CreatePaymentRequest request;
  final String token;

  CreatePaymentEvent({
    required this.request,
    required this.token,
  });
}
