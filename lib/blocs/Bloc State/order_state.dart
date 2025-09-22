import '../../models/order/KOT_model.dart' show KotModel;
import '../../models/order/guest_details.dart' show Guestcount;
import 'package:pinaka_restaurant_pos/models/order/order_items.dart';

class OrderState {
  final List<OrderItems> orderItems;
  final List<KotModel> kotList;
  final bool showKOTDropdown;
  final List<Guestcount> guests;
  final Map<String, double> addonPrices;

  // Order metadata
  final int orderId;
  final int tableId;
  final int zoneId;
  final String tableName;
  final String zoneName;
  final String restaurantId;

  OrderState({
    required this.orderItems,
    required this.kotList,
    required this.showKOTDropdown,
    this.guests = const [],
    this.addonPrices = const {},
    required this.orderId,
    required this.tableId,
    required this.zoneId,
    required this.tableName,
    required this.zoneName,
    required this.restaurantId,
  });

  OrderState copyWith({
    List<OrderItems>? orderItems,
    List<KotModel>? kotList,
    bool? showKOTDropdown,
    List<Guestcount>? guests,
    Map<String, double>? addonPrices,
    int? orderId,
    int? tableId,
    int? zoneId,
    String? tableName,
    String? zoneName,
    String? restaurantId,
  }) {
    return OrderState(
      orderItems: orderItems ?? this.orderItems,
      kotList: kotList ?? this.kotList,
      showKOTDropdown: showKOTDropdown ?? this.showKOTDropdown,
      guests: guests ?? this.guests,
      addonPrices: addonPrices ?? this.addonPrices,
      orderId: orderId ?? this.orderId,
      tableId: tableId ?? this.tableId,
      zoneId: zoneId ?? this.zoneId,
      tableName: tableName ?? this.tableName,
      zoneName: zoneName ?? this.zoneName,
      restaurantId: restaurantId ?? this.restaurantId,
    );
  }
}
