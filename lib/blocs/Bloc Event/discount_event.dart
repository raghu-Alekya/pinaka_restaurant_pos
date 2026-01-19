import '../../models/payment/discount_model.dart';
import 'package:equatable/equatable.dart';

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

abstract class RemoveDiscountEvent extends Equatable {
  const RemoveDiscountEvent();

  @override
  List<Object?> get props => [];
}

class RemoveDiscountRequested extends RemoveDiscountEvent {
  final String token;
  final int orderId;
  final String isNc;

  const RemoveDiscountRequested({
    required this.token,
    required this.orderId,
    required this.isNc,
  });

  @override
  List<Object?> get props => [token, orderId, isNc];
}


