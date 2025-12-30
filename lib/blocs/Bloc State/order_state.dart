import '../../models/order/KOT_model.dart' show KotModel;
import '../../models/order/guest_details.dart' show Guestcount;
import 'package:pinaka_restaurant_pos/models/order/order_items.dart';

import '../../models/order/repeat_kot_model.dart';

class OrderState {
  final List<OrderItems> orderItems;
  final List<KotModel> kotList;
  final bool showKOTDropdown;
  final Guestcount guestDetails; // ✅ Single guest
  final Map<String, double> addonPrices;
  final int guestCount;

  // Order metadata
  final int orderId;
  final int tableId;
  final int zoneId;
  final String tableName;
  final String zoneName;
  final String restaurantId;
  final bool isLoading;
  final RepeatKotModel? repeatKot;
  final String? error;


  OrderState({
    required this.orderItems,
    required this.kotList,
    required this.showKOTDropdown,
    required this.guestDetails, // ✅ required
    this.addonPrices = const {},
    this.guestCount = 0,
    required this.orderId,
    required this.tableId,
    required this.zoneId,
    required this.tableName,
    required this.zoneName,
    required this.restaurantId,
    this.isLoading = false,
    this.repeatKot,
    this.error,
  });

  OrderState copyWith({
    List<OrderItems>? orderItems,
    List<KotModel>? kotList,
    bool? showKOTDropdown,
    Guestcount? guestDetails, // ✅ single guest
    Map<String, double>? addonPrices,
    int? orderId,
    int? tableId,
    int? zoneId,
    String? tableName,
    String? zoneName,
    String? restaurantId,
    bool? isLoading,
    RepeatKotModel? repeatKot,
    String? error,
  }) {
    return OrderState(
      orderItems: orderItems ?? this.orderItems,
      kotList: kotList ?? this.kotList,
      showKOTDropdown: showKOTDropdown ?? this.showKOTDropdown,
      guestDetails: guestDetails ?? this.guestDetails,
      guestCount: guestCount ?? this.guestCount,
      addonPrices: addonPrices ?? this.addonPrices,
      orderId: orderId ?? this.orderId,
      tableId: tableId ?? this.tableId,
      zoneId: zoneId ?? this.zoneId,
      tableName: tableName ?? this.tableName,
      zoneName: zoneName ?? this.zoneName,
      restaurantId: restaurantId ?? this.restaurantId,
      isLoading: isLoading ?? this.isLoading,
      repeatKot: repeatKot ?? this.repeatKot,
      error: error,
    );
  }
  /// ✅ Subtotal (price × quantity)
  double get subTotal {
    return orderItems.fold(
      0.0,
          (sum, item) => sum + (item.price * item.quantity),
    );
  }

  /// ✅ Grand total (includes addons)
  double get grossTotal {
    return orderItems.fold(
      0.0,
          (sum, item) => sum + item.totalWithAddons,
    );
  }

  /// ✅ Optional alias if some screens expect this name
  // double get grossTotal => grandTotal;

}
