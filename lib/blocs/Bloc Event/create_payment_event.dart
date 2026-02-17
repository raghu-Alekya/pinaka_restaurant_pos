import '../../models/payment/create_payment_model.dart';

abstract class CreatePaymentEvent {}

class CreatePaymentRequested extends CreatePaymentEvent {
  final String token;
  final CreatePaymentRequest request;

  CreatePaymentRequested({
    required this.token,
    required this.request,
  });
}
