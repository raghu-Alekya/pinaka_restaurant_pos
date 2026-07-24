// order_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
// import '../../repositories/orders_list_repository.dart';
import '../../repositories/order_list_repository.dart';
import '../Bloc Event/order_list_event.dart';
import '../Bloc State/order_list_state.dart';
// import '../Bloc State/orders_list_state.dart';


class OrderstatusBloc extends Bloc<OrderstatusEvent, OrderstatusState> {
  final OrderstatusRepository orderRepository;

  OrderstatusBloc(this.orderRepository) : super(OrderInitial()) {
    on<FetchOrders>(_onFetchOrders);
  }

  Future<void> _onFetchOrders(
      FetchOrders event,
      Emitter<OrderstatusState> emit,
      ) async {
    final cacheKey = "${event.restaurantId ?? ''}_${event.date ?? ''}";
    final cachedOrders = orderRepository.getCachedOrders(cacheKey);

    if (cachedOrders != null && cachedOrders.isNotEmpty) {
      emit(OrderLoaded(cachedOrders));
    } else {
      emit(OrderLoading());
    }

    try {
      final orders = await orderRepository.fetchOrders(
        event.token,
        date: event.date,
        restaurantId: event.restaurantId,
      );
      emit(OrderLoaded(orders));
    } catch (e) {
      if (cachedOrders == null || cachedOrders.isEmpty) {
        emit(OrderError('Failed to load orders: ${e.toString()}'));
      }
    }
  }

}