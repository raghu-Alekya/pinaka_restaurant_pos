import 'package:equatable/equatable.dart';

import '../../models/order/void_kot_items.dart';
// import '../models/kot_line_items_model.dart';

abstract class KotLineItemsState extends Equatable {
  const KotLineItemsState();

  @override
  List<Object?> get props => [];
}

class KotLineItemsInitial extends KotLineItemsState {}

class KotLineItemsLoading extends KotLineItemsState {}

class KotLineItemsLoaded extends KotLineItemsState {
  final KotLineItemsResponse response;

  const KotLineItemsLoaded(this.response);

  @override
  List<Object?> get props => [response];
}

class KotLineItemsError extends KotLineItemsState {
  final String message;

  const KotLineItemsError(this.message);

  @override
  List<Object?> get props => [message];
}
// import 'package:equatable/equatable.dart';
// import '../models/updatekot_response.dart';

abstract class UpdatekotState extends Equatable {
  const UpdatekotState();

  @override
  List<Object?> get props => [];
}

class UpdatekotInitial extends UpdatekotState {}

class UpdatekotLoading extends UpdatekotState {}

class UpdatekotSuccess extends UpdatekotState {
  final UpdatekotResponse response;

  const UpdatekotSuccess(this.response);

  @override
  List<Object?> get props => [response];
}

class UpdatekotFailure extends UpdatekotState {
  final String message;

  const UpdatekotFailure(this.message);

  @override
  List<Object?> get props => [message];
}