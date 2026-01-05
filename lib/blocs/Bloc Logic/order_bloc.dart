
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pinaka_restaurant_pos/models/mappers/repeat_kot_mapper.dart';
import '../../models/order/KOT_model.dart';
import '../../models/order/guest_details.dart';
import '../../models/order/order_items.dart';
import '../../models/order/repeat_kot_model.dart';
import '../../models/sidebar/category_model_.dart';
import '../../repositories/order_repository.dart';
import '../../repositories/repeat_kot_repository.dart';
import '../../repositories/repeat_kot_repository.dart';
import '../Bloc Event/order_event.dart';
import '../Bloc State/checkin_state.dart';
import '../Bloc State/order_state.dart';
import '../../utils/logger.dart';
import 'checkin_bloc.dart';

class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final OrderRepository repository;
  final repeatOrderRepository repeatRepository;
  final String token;


  OrderBloc(this.repository, this.repeatRepository, this.token)
      : super(OrderState(
    orderItems: [],
    kotList: [],
    showKOTDropdown: true,
    guestDetails: Guestcount(guestCount: 0),
    orderId: 0,
    tableId: 0,
    zoneId: 0,
    tableName: '',
    zoneName: '',
    restaurantId: '',
  )) {
    {
      // ✅ REGISTER EVENT HERE
      on<RepeatKotOrder>(_onRepeatKotOrder);

      // other event handlers...
    }

    /// Create new order
    on<CreateOrder>((event, emit) {
      final isDifferentOrder =
          event.orderId != 0 && event.orderId != state.orderId;
      AppLogger.info(
          "Creating order: Table=${event.tableId}, Zone=${event.zoneId}");
      emit(state.copyWith(
        orderId: event.orderId != 0 ? event.orderId : state.orderId,
        tableId: event.tableId != 0 ? event.tableId : state.tableId,
        zoneId: event.zoneId != 0 ? event.zoneId : state.zoneId,
        tableName: event.tableName.isNotEmpty ? event.tableName : state
            .tableName,
        zoneName: event.zoneName.isNotEmpty ? event.zoneName : state.zoneName,
        restaurantId: event.restaurantId.isNotEmpty ? event.restaurantId : state
            .restaurantId,
        guestDetails: event.guestDetails ?? state.guestDetails,
        // ✅ Clear order items only if it's a different order
        orderItems: isDifferentOrder ? [] : state.orderItems,
        // ❌ Don’t clear KOTs
        kotList: state.kotList,
      ));
    });



    /// Select table
    on<SelectTable>((event, emit) async {
      final isDifferentTable = event.tableId != state.tableId;

      AppLogger.info(
          "🔹 Selected Table: ${event.tableName} (Table ID: ${event.tableId})");

      // Step 1: Update table info immediately
      emit(state.copyWith(
        tableId: event.tableId,
        zoneId: event.zoneId,
        tableName: event.tableName,
        zoneName: event.zoneName,
        restaurantId: event.restaurantId,
        // ✅ Clear items only if different table
        orderItems: isDifferentTable ? [] : state.orderItems,
        kotList: state.kotList, // keep existing KOTs
      ));

      try {
        // Step 2: Fetch existing order for this table
        final existingOrder = await repository.getOrderByTable(
          tableId: event.tableId,
          zoneId: event.zoneId,
          restaurantId: int.parse(event.restaurantId),
          token: token,
        );

        if (existingOrder != null) {
          // Convert fetched items to model list
          final orderItems = existingOrder.items.map((item) =>
              OrderItems(
                productId: item.productId,
                name: item.name,
                quantity: item.quantity,
                price: item.price,
                variantId: item.variationId,
                section: item.section,
                modifiers: item.modifiers,
                addOns: item.addOns,
              )).toList();

          final guestDetails = Guestcount(guestCount: existingOrder.guestCount);

          emit(state.copyWith(
            orderId: existingOrder.orderId,
            orderItems: orderItems,
            // ✅ restore items when returning to same table
            kotList: state.kotList,
            // keep old KOTs intact
            guestDetails: guestDetails,
          ));

          AppLogger.info(
            "✅ Loaded existing order for Table '${event
                .tableName}' → Items=${orderItems.length}, Guests=${guestDetails
                .guestCount}",
          );
        } else {
          AppLogger.info("ℹ️ No existing order for table '${event.tableName}'");
        }
      } catch (e, st) {
        AppLogger.error("❌ Failed to fetch existing order: $e\n$st");
      }
    });


    /// Order created successfully
    on<CreateOrderSuccess>((event, emit) {
      AppLogger.info("✅ Order created successfully with ID: ${event.orderId}");
      emit(state.copyWith(orderId: event.orderId));
    });

    /// Add order item
    on<AddOrderItem>((event, emit) {
      final updatedItems = List<OrderItems>.from(state.orderItems);

      final index = updatedItems.indexWhere(
            (item) =>
        item.productId == event.item.productId &&
            item.name == event.item.name, // ✅ name-based match
      );

      if (index != -1) {
        final updatedItem = updatedItems[index].copyWith(
          quantity:
          updatedItems[index].quantity + event.item.quantity, // ✅ popup qty
        );
        updatedItems[index] = updatedItem;

        AppLogger.info(
          "Incremented '${event.item.name}' → +${event.item
              .quantity}, total=${updatedItem.quantity}",
        );
      } else {
        updatedItems.add(event.item); // ✅ KEEP popup quantity

        AppLogger.info(
          "Added new item '${event.item.name}' qty=${event.item.quantity}",
        );
      }

      emit(state.copyWith(
        orderItems: updatedItems,
        showKOTDropdown: false,
      ));
    });


    /// Remove order item
    on<RemoveOrderItem>((event, emit) {
      final removedItem = state.orderItems[event.index];
      final updatedItems = List<OrderItems>.from(state.orderItems)
        ..removeAt(event.index);
      AppLogger.info("➖ Removed item '${removedItem.name}'");
      emit(state.copyWith(orderItems: updatedItems));
    });

    /// Clear order
    on<ClearOrder>((event, emit) {
      AppLogger.info("🗑 Clearing all order items");
      emit(state.copyWith(orderItems: []));
    });

    /// Cancel order
    on<CancelOrder>((event, emit) {
      final cancelledOrderId = state.orderId;
      AppLogger.info(
          "🛑 Cancelling order with ID=$cancelledOrderId and resetting state");

      emit(OrderState(
        orderItems: [],
        kotList: [],
        showKOTDropdown: true,
        guestDetails: Guestcount(guestCount: 0),
        orderId: 0,
        tableId: 0,
        zoneId: 0,
        tableName: '',
        zoneName: '',
        restaurantId: '',
      ));
    });

    /// Toggle KOT dropdown
    on<ToggleKOTDropdown>((event, emit) {
      emit(state.copyWith(showKOTDropdown: !state.showKOTDropdown));
    });

    /// Update order item quantity
    on<UpdateOrderItemQuantity>((event, emit) {
      final updatedItems = List<OrderItems>.from(state.orderItems);
      final item = updatedItems[event.index];
      updatedItems[event.index] = item.copyWith(quantity: event.quantity);
      AppLogger.info("✏️ Updated '${item.name}' → qty: ${event.quantity}");
      emit(state.copyWith(orderItems: updatedItems));
    });

    /// Update modifiers only
    on<UpdateOrderItemModifiers>((event, emit) {
      final updatedItems = List<OrderItems>.from(state.orderItems);
      final item = updatedItems[event.index];
      updatedItems[event.index] = item.copyWith(modifiers: event.modifiers);
      AppLogger.info(
          "🛠 Updated modifiers for '${item.name}': ${event.modifiers}");
      emit(state.copyWith(orderItems: updatedItems));
    });

    /// Update full item details
    on<UpdateOrderItemDetails>((event, emit) {
      final updatedItems = List<OrderItems>.from(state.orderItems);
      final item = updatedItems[event.index];
      updatedItems[event.index] = item.copyWith(
        modifiers: event.modifiers,
        addOns: event.addOns,
        note: event.note,
      );
      AppLogger.info(
          "Updated '${item.name}' → modifiers=${event.modifiers}, addOns=${event
              .addOns}, note='${event.note}'");
      emit(state.copyWith(orderItems: updatedItems));
    });

    /// Add KOT
    on<AddKOT>((event, emit) {
      final updatedKOTs = List<KotModel>.from(state.kotList)
        ..add(event.kot);
      AppLogger.info("Added KOT: ${event.kot.kotId}");
      emit(state.copyWith(kotList: updatedKOTs));
    });

    /// Create KOT via API
    on<CreateKOT>((event, emit) async {
      AppLogger.info(
          "Creating KOT: ${event.kotId} for Order ID: ${event.parentOrderId}");

      try {
        if (event.zoneId == 0 || event.parentOrderId == 0) {
          AppLogger.error("❌ Missing order context");
          return;
        }
        final kot = await repository.createKOT(
          parentOrderId: event.parentOrderId,
          kotId: event.kotId,
          items: event.items,
          token: event.token,
          restaurantId: event.restaurantId,
          zoneId: event.zoneId,
          captainId: event.captainId,
        );

        if (kot != null) {
          final updatedKOTs = List<KotModel>.from(state.kotList)
            ..add(kot);
          emit(state.copyWith(kotList: updatedKOTs));
          AppLogger.info("✅ KOT created successfully: ${kot.kotId}");
        }
      } catch (e) {
        AppLogger.error("❌ Failed to create KOT: $e");
      }
    });

    /// Load existing order (used when table already has active order)
    on<LoadExistingOrder>((event, emit) {
      final isDifferentOrder = event.orderId != state.orderId;
      AppLogger.info(
          "Loading existing order ID=${event.orderId}, Table=${event
              .tableName}, Zone=${event.zoneName}");

      emit(state.copyWith(
        orderId: event.orderId,
        tableId: event.tableId,
        zoneId: event.zoneId,
        tableName: event.tableName,
        zoneName: event.zoneName,
        restaurantId: event.restaurantId,
        kotList: event.kotList,
        guestDetails: event.guestDetails,
        orderItems: isDifferentOrder ? [] : event.orderItems,
      ));
    });

    on<CollapseKOT>((event, emit) {
      emit(state.copyWith(showKOTDropdown: false));
    });
  }


  Future<void> _onRepeatKotOrder(
      RepeatKotOrder event,
      Emitter<OrderState> emit,
      ) async {
    try {
      emit(state.copyWith(isLoading: true));

      final result = await repeatRepository.repeatKotOrder(
        orderId: event.orderId,
        restaurantId: event.restaurantId,
        zoneId: event.zoneId,
        token: token,
      );

      // ✅ Convert API response → KotModel
      final kot = result.toKotModel();

      // ✅ Merge items into existing order items
      final updatedOrderItems = [
        ...state.orderItems,
        ...kot.items,
      ];

      // ✅ Update both order items & KOT list
      emit(state.copyWith(
        isLoading: false,
        orderItems: updatedOrderItems,
        kotList: [...state.kotList, kot],
      ));

      AppLogger.info("✅ Repeat order applied to UI");

    } catch (e, st) {
      AppLogger.error("❌ Repeat order failed: $e");
      emit(state.copyWith(isLoading: false));
    }
  }



}
