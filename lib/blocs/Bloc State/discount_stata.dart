import '../../models/payment/discount_model.dart';
import 'package:equatable/equatable.dart';

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
abstract class RemoveDiscountState extends Equatable {
  const RemoveDiscountState();

  @override
  List<Object?> get props => [];
}

class RemoveDiscountInitial extends RemoveDiscountState {}

class RemoveDiscountLoading extends RemoveDiscountState {}

class RemoveDiscountSuccess extends RemoveDiscountState {
  final RemoveDiscountResponseModel response;

  const RemoveDiscountSuccess(this.response);

  @override
  List<Object?> get props => [response];
}

class RemoveDiscountFailure extends RemoveDiscountState {
  final String error;

  const RemoveDiscountFailure(this.error);

  @override
  List<Object?> get props => [error];
}
