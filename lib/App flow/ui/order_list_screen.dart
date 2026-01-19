import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/Bloc Event/order_list_event.dart';
// import '../../blocs/Bloc Logic/orders_list_bloc.dart' show OrderstatusBloc;
import '../../blocs/Bloc Logic/order_list_bloc.dart';
import '../../blocs/Bloc State/order_list_state.dart';
// import '../../blocs/Bloc State/orders_list_state.dart';
import '../../models/order_list/order_list_model.dart';
// import '../../models/orderslist/orders_list_model.dart';
import 'orderstatus_screen.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  @override
  void initState() {
    super.initState();
    // Trigger fetch on screen load using Bloc
    context.read<OrderstatusBloc>().add(FetchOrders(token: ''));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Orders")),
      body: BlocBuilder<OrderstatusBloc, OrderstatusState>(
        builder: (context, state) {
          if (state is OrderLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is OrderLoaded) {
            final List<OrderlistModel> orders = state.orders;
            if (orders.isEmpty) {
              return const Center(child: Text('No orders found'));
            }
            return OrdersListTable(orders: orders, token: '', pin: '', restaurantId: '', restaurantName: '',);
          } else if (state is OrderError) {
            return Center(
              child: Text(
                'Error: ${state.message}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          return const Center(child: Text('Press refresh to load orders'));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.read<OrderstatusBloc>().add(FetchOrders(token: ''));
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }
}