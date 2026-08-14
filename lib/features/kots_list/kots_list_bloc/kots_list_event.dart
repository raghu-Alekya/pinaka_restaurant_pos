import 'package:equatable/equatable.dart';

abstract class KotsListEvent extends Equatable {
  const KotsListEvent();

  @override
  List<Object> get props => [];
}

class FetchKotsList extends KotsListEvent {
  final int parentOrderId;
  final int restaurantId;
  final int zoneId;

  const FetchKotsList({
    required this.parentOrderId,
    required this.restaurantId,
    required this.zoneId,
  });

  @override
  List<Object> get props => [parentOrderId, restaurantId, zoneId];
}