import 'package:pinaka_restaurant_pos/models/order/order_items.dart';
import '../../models/order/KOT_model.dart';
import '../../models/order/guest_details.dart';

abstract class OrderEvent {}

/// 1️⃣ Create a new order when table is clicked
/// 1️⃣ Create a new order when table is clicked
class CreateOrder extends OrderEvent {
  final String restaurantId;
  final int tableId;
  final int zoneId;
  final Guestcount guestDetails; // ✅ single Guestcount
  final int orderId;
  final Map<String, double> addonPrices;
  final String zoneName;
  final String tableName;
  final String restaurantName;

  CreateOrder({
    required this.restaurantId,
    required this.tableId,
    required this.zoneId,
    required this.guestDetails, // ✅ require single Guestcount
    this.orderId = 0,
    this.addonPrices = const {},
    this.zoneName = '',
    this.tableName = '',
    this.restaurantName = '',
  });
}


/// Event when a table is selected
class SelectTable extends OrderEvent {
  final int tableId;
  final int zoneId;
  final String tableName;     // ✅ added
  final String zoneName;
  final  restaurantId;// ✅ added

  SelectTable({
    required this.tableId,
    required this.zoneId,
    this.tableName = '',
    this.zoneName = '',
    required this .restaurantId,
  });
}

/// Event after API returns order successfully
class CreateOrderSuccess extends OrderEvent {
  final int orderId;

  // Use only one: named parameter is preferred
  CreateOrderSuccess({required this.orderId});
}





/// 2️⃣ Add an item to the order
class AddOrderItem extends OrderEvent {
  final OrderItems item;
  AddOrderItem(this.item);
}

/// 3️⃣ Remove an item from the order
class RemoveOrderItem extends OrderEvent {
  final int index;
  RemoveOrderItem(this.index);
}

/// 4️⃣ Clear the entire order
class ClearOrder extends OrderEvent {}

/// 5️⃣ Cancel the order
/// 5️⃣ Cancel the order
class CancelOrder extends OrderEvent {
  final int parentOrderId;
  final String token;

  CancelOrder({
    required this.parentOrderId,
    required this.token,
  });
}

/// 6️⃣ Toggle KOT dropdown visibility
class ToggleKOTDropdown extends OrderEvent {}

/// 7️⃣ Update quantity of an order item
class UpdateOrderItemQuantity extends OrderEvent {
  final int index;
  final int quantity;

  UpdateOrderItemQuantity(this.index, this.quantity);
}

/// 8️⃣ Update only modifiers of an item
class UpdateOrderItemModifiers extends OrderEvent {
  final int index;
  final List<String> modifiers;
  final Map<String, int> addOns;
  final String note;

  UpdateOrderItemModifiers(
      this.index,
      this.modifiers,
      this.addOns,
      this.note,
      );
}

/// 9️⃣ Update modifiers + add-ons + note (full update)
class UpdateOrderItemDetails extends OrderEvent {
  final int index;
  final List<String> modifiers;
  final Map<String, Map<String, dynamic>> addOns; // ✅ store quantity + price
  final String note;

  UpdateOrderItemDetails({
    required this.index,
    this.modifiers = const [],
    this.addOns = const {},
    this.note = '',
  });
}

/// 🔟 Add a KOT entry
class AddKOT extends OrderEvent {
  final KotModel kot;
  AddKOT(this.kot);
}
/// 🔹 Create KOT from current order items
// Create KOT from current order items (trigger API)
/// 🔹 Create KOT from current order items (trigger API)
class CreateKOT extends OrderEvent {
  final  kotId;
  final int parentOrderId;
  final List<OrderItems> items;
  final String token;
  final int  restaurantId; // ✅ add this
  final int zoneId;
  final int captainId;


  CreateKOT(
      this.restaurantId,
      this.zoneId,
      this.captainId, {
        required this.kotId,
        required this.parentOrderId,
        required this.items,
        required this.token,
      });
}
/// Collapse the KOT dropdown
class CollapseKOT extends OrderEvent {}


/// 🔹 Load existing order and KOTs when table already has active orders
class LoadExistingOrder extends OrderEvent {
  final int orderId;
  final int tableId;
  final int zoneId;
  final String tableName;
  final String zoneName;
  final String restaurantId;
  final List<KotModel> kotList;
  final List<OrderItems> orderItems;
  final Guestcount guestDetails; // ✅ single Guestcount

  LoadExistingOrder({
    required this.orderId,
    required this.tableId,
    required this.zoneId,
    required this.tableName,
    required this.zoneName,
    required this.restaurantId,
    this.kotList = const [],
    this.orderItems = const [],
    required this.guestDetails, // ✅ must pass single Guestcount
  });

}







