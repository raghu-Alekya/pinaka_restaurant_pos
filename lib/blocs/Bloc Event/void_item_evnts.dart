import 'package:equatable/equatable.dart';

import '../../models/order/void_kot_items.dart';

abstract class KotLineItemsEvent extends Equatable {
  const KotLineItemsEvent();

  @override
  List<Object?> get props => [];
}

class FetchKotLineItems extends KotLineItemsEvent {
  final int kotId;
  final int restaurantId;
  final int zoneId;
  final String token;

  const FetchKotLineItems({
    required this.kotId,
    required this.restaurantId,
    required this.zoneId,
    required this.token,
  });

  @override
  List<Object?> get props => [kotId, restaurantId, zoneId, token];
}

abstract class UpdatekotEvent extends Equatable {
  const UpdatekotEvent();

  @override
  List<Object?> get props => [];
}

class UpdatekotPressed extends UpdatekotEvent {
  final String token;
  final int kotId;
  final UpdatekotRequest request;

  const UpdatekotPressed({
    required this.token,
    required this.kotId,
    required this.request,
  });

  @override
  List<Object?> get props => [token, kotId, request];
}