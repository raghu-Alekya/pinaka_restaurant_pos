import '../../models/order_list/order_list_model.dart';
// import '../../models/orderslist/orders_list_model.dart';

abstract class OrderstatusState {}

class OrderInitial extends OrderstatusState {}

class OrderLoading extends OrderstatusState {}

class OrderLoaded extends OrderstatusState {
  final List< OrderlistModel> orders;
  OrderLoaded(this.orders);
}

class OrderError extends OrderstatusState {
  final String message;
  OrderError(this.message);
}