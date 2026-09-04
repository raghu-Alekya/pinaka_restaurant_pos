
import 'package:flutter/cupertino.dart';
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
  final RepeatOrderRepository repeatRepository;
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
    lastRepeatedKotIndex: -1,
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
        kotList: isDifferentOrder ? [] : state.kotList,
        // ✅ IMPORTANT: reset repeat order lock for new order/table
        // isKotRepeated: false,
        // repeatedOrderId: 0,
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
        kotList: state.kotList,

        // ✅ IMPORTANT: reset repeat flag when table changes
        // isKotRepeated: false,
        // repeatedOrderId: 0,
      ));

      try {
        final existingOrder = await repository.getOrderByTable(
          tableId: event.tableId,
          zoneId: event.zoneId,
          restaurantId: int.parse(event.restaurantId),
          token: token,
        );

        if (existingOrder != null) {
          final orderItems = existingOrder.items.map((item) => OrderItems(
            productId: item.productId,
            name: item.name,
            quantity: item.quantity,
            price: item.price,
            variationId: item.variationId,
            section: item.section,
            modifiers: item.modifiers,
            addOns: item.addOns,
            amount: item.amount,
            hasOptions: item.hasOptions,
          )).toList();

          final guestDetails = Guestcount(guestCount: existingOrder.guestCount);

          emit(state.copyWith(
            orderId: existingOrder.orderId,
            orderItems: orderItems,
            kotList: state.kotList,
            guestDetails: guestDetails,

            // ✅ also reset here (safe)
            // isKotRepeated: false,
            // repeatedOrderId: 0, //
          ));

          AppLogger.info(
            "✅ Loaded existing order for Table '${event.tableName}' → Items=${orderItems.length}, Guests=${guestDetails.guestCount}",
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
            item.variationId == event.item.variationId,
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

    // ✅ Register this event
    on<SetTakeAwayOrder>((event, emit) {
      debugPrint("========== SET TAKEAWAY ORDER ==========");
      debugPrint("Received orderId: ${event.orderId}");
      debugPrint("Received restaurantId: ${event.restaurantId}");

      emit(
        state.copyWith(
          orderId: event.orderId,
          restaurantId: event.restaurantId,
        ),
      );

      debugPrint("State Updated -> orderId: ${event.orderId}");
    });
    on<SetTakeAwayKotId>((event, emit) {
      emit(
        state.copyWith(
          takeAwayKotId: event.kotId,
        ),
      );
    });
    /// Clear order
    on<ClearOrder>((event, emit) {
      AppLogger.info("🗑 Clearing all order items");
      emit(state.copyWith(orderItems: []));
    });
    on<ResetOrder>((event, emit) {
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
        lastRepeatedKotIndex: -1,

      ));
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
        // ✅ IMPORTANT
        lastRepeatedKotIndex: -1,
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
    on<SetKotList>((event, emit) {
      emit(
        state.copyWith(
          kotList: event.kots,
        ),
      );
    });

    on<RefreshKotList>((event, emit) {
      if (_areKotListsEqual(state.kotList, event.kots)) {
        return;
      }
      debugPrint("RefreshKotList updated: ${event.kots.length}");
      emit(
        state.copyWith(
          kotList: event.kots,
        ),
      );
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

          emit(state.copyWith(
            kotList: updatedKOTs,

            // 🔓 UNLOCK repeat after new KOT
            // isKotRepeated: false,
            // repeatedOrderId: 0,
            lastRepeatedKotIndex: -1,
          ));

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

    on<UpdateKotStatusInOrder>((event, emit) {
      final updatedKots = state.kotList.map((kot) {
        if (kot.kotNumber == event.kotNumber) {
          return kot.copyWith(
            status: event.status,
            items: event.remainingItems != null
                ? event.remainingItems!
                .map((e) => OrderItems.fromJson(e))
                .toList()
                : kot.items,
          );
        }
        return kot;
      }).toList();

      emit(state.copyWith(kotList: updatedKots));

      AppLogger.info(
        'KOT ${event.kotNumber} updated to ${event.status}',
      );
    });
  }


  Future<void> _onRepeatKotOrder(
      RepeatKotOrder event,
      Emitter<OrderState> emit,
      ) async {
    // ⛔ block multiple clicks
    if (state.isLoading) return;

    // ⛔ block repeat for SAME KOT
    if (state.lastRepeatedKotIndex == state.kotList.length) {
      AppLogger.debug("🚨 Repeat blocked → emitting error");

      emit(state.copyWith(
        error: "Repeat order can be applied only once for this KOT",
      ));
      return;
    }


    // 🔒 LOCK immediately
    emit(state.copyWith(
      isLoading: true,
      lastRepeatedKotIndex: state.kotList.length,
    ));

    try {
      final result = await repeatRepository.repeatKotOrder(
        orderId: event.orderId,
        restaurantId: event.restaurantId,
        zoneId: event.zoneId,
        token: token,
      );

      final kot = result.toKotModel();

      final updatedItems = kot.items.map((newItem) {
        bool hasOpt = newItem.hasOptions;
        if (!hasOpt) {
          final existingMatch = state.orderItems.firstWhere(
            (existing) =>
                (existing.productId == newItem.productId ||
                 existing.name.toLowerCase() == newItem.name.toLowerCase()) &&
                existing.hasOptions,
            orElse: () => newItem,
          );
          if (existingMatch.hasOptions) {
            hasOpt = true;
          }
        }
        return newItem.copyWith(
          modifiers: const [],
          addOns: const {},
          note: '',
          hasOptions: hasOpt,
          amount: newItem.price * newItem.quantity,
        );
      }).toList();

      emit(state.copyWith(
        isLoading: false,

        // ✅ ONLY add items
        orderItems: [...state.orderItems, ...updatedItems],
      ));

      AppLogger.info("✅ Repeat applied once for this KOT");
    } catch (e) {
      // 🔓 unlock if API fails
      emit(state.copyWith(
        isLoading: false,
        lastRepeatedKotIndex: -1,
      ));
    }
  }

  bool _areKotListsEqual(List<KotModel> a, List<KotModel> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].kotId != b[i].kotId ||
          a[i].kotNumber != b[i].kotNumber ||
          a[i].status != b[i].status ||
          a[i].items.length != b[i].items.length) {
        return false;
      }
    }
    return true;
  }
}

