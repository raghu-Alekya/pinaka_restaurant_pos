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
    emit(OrderLoading());
    try {
      final orders = await orderRepository.fetchOrders(event.token, date: event.date);

      // Debug print each order
      for (var order in orders) {
        print('==============================');
        print('Order ID    : ${order.orderId}');
        print('Type        : ${order.orderType}');
        print('Date        : ${order.date}');
        print('Customer    : ${order.customerName}');
        print('Phone       : ${order.customerPhone}');
        print('Amount      : ${order.amount}');
        print('Discount    : ${order.discount}');
        print('Total       : ${order.total}');
        print('Status      : ${order.status}');
        print('Is Parent   : ${order.isParent}');
        print('--- KOT ORDERS ---');

        if (order.kotOrders != null && order.kotOrders!.isNotEmpty) {
          for (var kot in order.kotOrders!) {
            print('  KOT Order ID : ${kot.kotOrderId}');
            print('  Status       : ${kot.status}');
            print('  Total        : ${kot.total}');
            print('  Created At   : ${kot.createdAt}');
            print('  Is Parent    : ${kot.isParent}');
            print('  --- LINE ITEMS ---');
            if (kot.lineItems != null && kot.lineItems!.isNotEmpty) {
              for (var item in kot.lineItems!) {
                print('    Item ID   : ${item.itemId}');
                print('    Name      : ${item.name}');
                print('    Qty       : ${item.quantity}');
                print('    Amount    : ${item.amount}');
                print('    Total     : ${item.total}');
              }
            } else {
              print('    No line items found.');
            }
          }
        } else {
          print('No KOT Orders found.');
        }
      }

      emit(OrderLoaded(orders));
    } catch (e) {
      print("Error fetching orders: $e");
      emit(OrderError('Failed to load orders: ${e.toString()}'));
    }
  }

}