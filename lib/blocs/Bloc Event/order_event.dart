import '../../models/order/order_items.dart';
import '../../models/order/KOT_model.dart';
import '../../models/order/guest_details.dart';

abstract class OrderEvent {}

/// 1️⃣ Create a new order when table is clicked
/// 1️⃣ Create a new order when table is clicked
class CreateOrder extends OrderEvent {
  final String restaurantId;
  final int tableId;
  final int zoneId;
  final List<Guestcount> guests;
  final int orderId;
  final Map<String, double> addonPrices;
  final String zoneName;      // ✅ added
  final String tableName;     // ✅ added
  final String restaurantName;
  final int? guestCount;

  CreateOrder({
    required this.restaurantId,
    required this.tableId,
    required this.zoneId,
    this.guests = const [],
    this.guestCount,
    this.orderId = 0,
    this.addonPrices = const {},
    this.zoneName = '',
    this.tableName = '',       // ✅ added
    this.restaurantName = '',
  });
}

/// Event when a table is selected
class SelectTable extends OrderEvent {
  final int tableId;
  final int zoneId;
  final String tableName;     // ✅ added
  final String zoneName;      // ✅ added

  SelectTable({
    required this.tableId,
    required this.zoneId,
    this.tableName = '',
    this.zoneName = '',
  });
}

/// Event after API returns order successfully
class CreateOrderSuccess extends OrderEvent {
  final int orderId;

  CreateOrderSuccess(this.orderId);
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
class CancelOrder extends OrderEvent {}

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
  final Map<String, int> addOns;
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
