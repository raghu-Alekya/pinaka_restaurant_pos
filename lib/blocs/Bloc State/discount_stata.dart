import '../../models/payment/discount_model.dart';

abstract class DiscountReasonState {}

class DiscountReasonInitial extends DiscountReasonState {}

class DiscountReasonLoading extends DiscountReasonState {}

class DiscountReasonLoaded extends DiscountReasonState {
  final List<String> reasons;

  DiscountReasonLoaded(this.reasons);
}

class DiscountReasonError extends DiscountReasonState {
  final String message;

  DiscountReasonError(this.message);
}
abstract class DiscountState {}

class DiscountInitial extends DiscountState {}

class DiscountLoading extends DiscountState {}

class DiscountSuccess extends DiscountState {
  final AddDiscountResponse response;

  DiscountSuccess(this.response);
}

class DiscountFailure extends DiscountState {
  final String error;

  DiscountFailure(this.error);
}
