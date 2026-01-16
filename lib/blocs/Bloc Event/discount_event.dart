import '../../models/payment/discount_model.dart';

abstract class DiscountReasonEvent {}

class LoadDiscountReasons extends DiscountReasonEvent {
  // final String token;

  // LoadDiscountReasons(this.token);
}
// blocs/discount/discount_event.dart


abstract class DiscountEvent {}

class ApplyDiscountEvent extends DiscountEvent {
  // final String token;
  final AddDiscountRequest request;

  ApplyDiscountEvent({
    // required this.token,
    required this.request,
  });
}

