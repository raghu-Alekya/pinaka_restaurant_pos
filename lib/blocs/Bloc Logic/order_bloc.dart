import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/order/KOT_model.dart';
import '../../models/order/guest_details.dart';
import '../../models/order/order_model.dart';
// import '../models/order/order_model.dart';
// import '../models/order/KOT_model.dart';

/// -------- EVENTS -------- ///
abstract class OrderEvent {}

class AddOrderItem extends OrderEvent {
  final OrderItems item;
  AddOrderItem(this.item);
}

class RemoveOrderItem extends OrderEvent {
  final int index;
  RemoveOrderItem(this.index);
}

class ClearOrder extends OrderEvent {}

class ToggleKOTDropdown extends OrderEvent {}

class UpdateOrderItemQuantity extends OrderEvent {
  final int index;
  final int quantity;
  UpdateOrderItemQuantity(this.index, this.quantity);
}

class UpdateOrderItemModifiers extends OrderEvent {
  final int index;
  final List<String> modifiers;
  UpdateOrderItemModifiers(this.index, this.modifiers);
}

/// -------- STATE -------- ///
class OrderState {
  final List<OrderItems> orderItems;
  final List<KotModel> kotList;
  final bool showKOTDropdown;
  final Guestcount? guest; // 👈 add guest field (nullable)

  OrderState({
    required this.orderItems,
    required this.kotList,
    required this.showKOTDropdown,
    this.guest, // 👈 optional
  });

  OrderState copyWith({
    List<OrderItems>? orderItems,
    List<KotModel>? kotList,
    bool? showKOTDropdown,
    Guestcount? guest,
  }) {
    return OrderState(
      orderItems: orderItems ?? this.orderItems,
      kotList: kotList ?? this.kotList,
      showKOTDropdown: showKOTDropdown ?? this.showKOTDropdown,
      guest: guest ?? this.guest, // 👈 ensure guest is copied
    );
  }
}


/// -------- BLOC -------- ///
class OrderBloc extends Bloc<OrderEvent, OrderState> {
  OrderBloc()
      : super(OrderState(orderItems: [], kotList: [], showKOTDropdown: true)) {

    on<AddOrderItem>((event, emit) {
      final existingItems = List<OrderItems>.from(state.orderItems);

      // Check if item with same name exists
      final index = existingItems.indexWhere((item) => item.name == event.item.name);

      if (index != -1) {
        // Increment quantity if exists
        final updatedItem = existingItems[index].copyWith(
          quantity: existingItems[index].quantity + event.item.quantity,
        );
        existingItems[index] = updatedItem;
      } else {
        // Add new item
        existingItems.add(event.item);
      }

      emit(state.copyWith(orderItems: existingItems));
    });

    on<RemoveOrderItem>((event, emit) {
      final updatedItems = List<OrderItems>.from(state.orderItems)..removeAt(event.index);
      emit(state.copyWith(orderItems: updatedItems));
    });

    on<ClearOrder>((event, emit) {
      emit(state.copyWith(orderItems: []));
    });

    on<ToggleKOTDropdown>((event, emit) {
      emit(state.copyWith(showKOTDropdown: !state.showKOTDropdown));
    });

    on<UpdateOrderItemQuantity>((event, emit) {
      final updatedItems = List<OrderItems>.from(state.orderItems);
      final item = updatedItems[event.index];
      updatedItems[event.index] = item.copyWith(quantity: event.quantity);
      emit(state.copyWith(orderItems: updatedItems));
    });

    on<UpdateOrderItemModifiers>((event, emit) {
      final updatedItems = List<OrderItems>.from(state.orderItems);
      final item = updatedItems[event.index];
      updatedItems[event.index] = item.copyWith(modifiers: event.modifiers);
      emit(state.copyWith(orderItems: updatedItems));
    });
  }
}
