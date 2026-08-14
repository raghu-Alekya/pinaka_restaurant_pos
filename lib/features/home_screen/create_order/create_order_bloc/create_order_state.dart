import 'package:equatable/equatable.dart';

import '../create_order_domain/create_order_entity.dart';

abstract class CreateOrderState extends Equatable {
  const CreateOrderState();

  @override
  List<Object> get props => [];
}

class CreateOrderInitial extends CreateOrderState {}

class CreateOrderLoading extends CreateOrderState {}

class CreateOrderSuccess extends CreateOrderState {
  final CreateOrderResponseEntity response;

  const CreateOrderSuccess({required this.response});

  @override
  List<Object> get props => [response];
}

class CreateOrderError extends CreateOrderState {
  final String message;

  const CreateOrderError({required this.message});

  @override
  List<Object> get props => [message];
}