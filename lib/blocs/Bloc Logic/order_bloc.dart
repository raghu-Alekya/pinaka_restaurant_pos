import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/order/KOT_model.dart';
import '../../models/order/guest_details.dart';
import '../../models/order/order_items.dart';
import '../Bloc Event/order_event.dart';
import '../Bloc State/order_state.dart';
import '../../utils/logger.dart';

class OrderBloc extends Bloc<OrderEvent, OrderState> {
  OrderBloc()
      : super(OrderState(
    orderItems: [],
    kotList: [],
    showKOTDropdown: true,
    orderId: 0,
    tableId: 0,
    zoneId: 0,
    tableName: '',
    zoneName: '',
    restaurantId: '',
    guests: [],
  )) {
    /// 1️⃣ Create new order
    on<CreateOrder>((event, emit) {
      AppLogger.info(
          "🆕 Creating order: Table=${event.tableId}, Zone=${event.zoneId}, TableName=${event.tableName}, ZoneName=${event.zoneName}");
      emit(state.copyWith(
        orderId: event.orderId,
        tableId: event.tableId != 0 ? event.tableId : state.tableId,
        zoneId: event.zoneId != 0 ? event.zoneId : state.zoneId,
        tableName: event.tableName.isNotEmpty ? event.tableName : state.tableName,
        zoneName: event.zoneName.isNotEmpty ? event.zoneName : state.zoneName,
        restaurantId: event.restaurantId.isNotEmpty ? event.restaurantId : state.restaurantId,
        guests: event.guests.isNotEmpty ? event.guests : state.guests,
      ));
    });

    /// 2️⃣ Select table
    on<SelectTable>((event, emit) {
      AppLogger.info(
          "🔹 Selected Table: ${event.tableId}, Zone: ${event.zoneId}, TableName=${event.tableName}, ZoneName=${event.zoneName}");
      emit(state.copyWith(
        tableId: event.tableId,
        zoneId: event.zoneId,
        tableName: event.tableName,
        zoneName: event.zoneName ,
      ));
    });

    /// 3️⃣ Order created successfully (API response)
    on<CreateOrderSuccess>((event, emit) {
      AppLogger.info("✅ Order created successfully with ID: ${event.orderId}");
      emit(state.copyWith(orderId: event.orderId));
    });

    /// 4️⃣ Add order item
    on<AddOrderItem>((event, emit) {
      final updatedItems = List<OrderItems>.from(state.orderItems);
      final index = updatedItems.indexWhere((item) => item.name == event.item.name);

      if (index != -1) {
        final updatedItem = updatedItems[index].copyWith(
          quantity: updatedItems[index].quantity + event.item.quantity,
        );
        updatedItems[index] = updatedItem;
        AppLogger.info("➕ Updated quantity of '${event.item.name}' to ${updatedItem.quantity}");
      } else {
        updatedItems.add(event.item);
        AppLogger.info("➕ Added new item '${event.item.name}' with qty ${event.item.quantity}");
      }

      emit(state.copyWith(orderItems: updatedItems));
    });

    /// 5️⃣ Remove order item
    on<RemoveOrderItem>((event, emit) {
      final removedItem = state.orderItems[event.index];
      final updatedItems = List<OrderItems>.from(state.orderItems)..removeAt(event.index);
      AppLogger.info("➖ Removed item '${removedItem.name}' at index ${event.index}");
      emit(state.copyWith(orderItems: updatedItems));
    });

    /// 6️⃣ Clear order
    on<ClearOrder>((event, emit) {
      AppLogger.info("🧹 Clearing all order items");
      emit(state.copyWith(orderItems: []));
    });

    /// 7️⃣ Cancel order
    on<CancelOrder>((event, emit) {
      AppLogger.info("❌ Canceling order and resetting state");
      emit(OrderState(
        orderItems: [],
        kotList: [],
        showKOTDropdown: true,
        orderId: 0,
        tableId: 0,
        zoneId: 0,
        tableName: '',
        zoneName: '',
        restaurantId: '',
        guests: [],
      ));
    });

    /// 8️⃣ Toggle KOT dropdown
    on<ToggleKOTDropdown>((event, emit) {
      emit(state.copyWith(showKOTDropdown: !state.showKOTDropdown));
    });

    /// 9️⃣ Update order item quantity
    on<UpdateOrderItemQuantity>((event, emit) {
      final updatedItems = List<OrderItems>.from(state.orderItems);
      final item = updatedItems[event.index];
      updatedItems[event.index] = item.copyWith(quantity: event.quantity);
      AppLogger.info("🔄 Updated quantity of '${item.name}' to ${event.quantity}");
      emit(state.copyWith(orderItems: updatedItems));
    });

    /// 🔟 Update modifiers only
    on<UpdateOrderItemModifiers>((event, emit) {
      final updatedItems = List<OrderItems>.from(state.orderItems);
      final item = updatedItems[event.index];
      updatedItems[event.index] = item.copyWith(modifiers: event.modifiers);
      AppLogger.info("🛠 Updated modifiers of '${item.name}': ${event.modifiers}");
      emit(state.copyWith(orderItems: updatedItems));
    });

    /// 1️⃣1️⃣ Update full details (modifiers + add-ons + note)
    on<UpdateOrderItemDetails>((event, emit) {
      final updatedItems = List<OrderItems>.from(state.orderItems);
      final item = updatedItems[event.index];
      updatedItems[event.index] = item.copyWith(
        modifiers: event.modifiers,
        addOns: event.addOns,
        note: event.note,
      );
      AppLogger.info(
          "📋 Updated item '${item.name}': modifiers=${event.modifiers}, addOns=${event.addOns}, note='${event.note}'");
      emit(state.copyWith(orderItems: updatedItems));
    });

    /// 1️⃣2️⃣ Add KOT entry
    on<AddKOT>((event, emit) {
      final updatedKOTs = List<KotModel>.from(state.kotList)..add(event.kot);
      AppLogger.info("🧾 Added KOT: ${event.kot.kotId}");
      emit(state.copyWith(kotList: updatedKOTs));
    });
  }
}
