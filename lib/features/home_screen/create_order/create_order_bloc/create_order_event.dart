import 'package:equatable/equatable.dart';
import '../create_order_domain/create_order_entity.dart';

abstract class CreateOrderEvent extends Equatable {
  const CreateOrderEvent();

  @override
  List<Object> get props => [];
}

class CreateOrder extends CreateOrderEvent {
  final CreateOrderRequestEntity request;

  const CreateOrder({required this.request});

  @override
  List<Object> get props => [request];
}