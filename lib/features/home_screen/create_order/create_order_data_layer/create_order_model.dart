import '../create_order_domain/create_order_entity.dart';

class CreateOrderRequest {
  final String flagType;
  final int tableId;
  final String tableName;
  final int zoneId;
  final String zoneName;
  final int restaurantId;
  final String restaurantName;
  final int guestCount;
  final List<GuestDetail> guestDetails;
  final String? reservationId;
  final String orderDatetime;

  CreateOrderRequest({
    required this.flagType,
    required this.tableId,
    required this.tableName,
    required this.zoneId,
    required this.zoneName,
    required this.restaurantId,
    required this.restaurantName,
    required this.guestCount,
    required this.guestDetails,
    this.reservationId,
    required this.orderDatetime,
  });

  Map<String, dynamic> toJson() => {
    'flag_type': flagType,
    'table_id': tableId,
    'table_name': tableName,
    'zone_id': zoneId,
    'zone_name': zoneName,
    'restaurant_id': restaurantId,
    'restaurant_name': restaurantName,
    'guest_count': guestCount,
    'guest_details': guestDetails.map((e) => e.toJson()).toList(),
    'reservation_id': reservationId,
    'order_datetime': orderDatetime,
  };

  CreateOrderRequestEntity toEntity() => CreateOrderRequestEntity(
    flagType: flagType,
    tableId: tableId,
    tableName: tableName,
    zoneId: zoneId,
    zoneName: zoneName,
    restaurantId: restaurantId,
    restaurantName: restaurantName,
    guestCount: guestCount,
    guestDetails: guestDetails.map((e) => e.toEntity()).toList(),
    reservationId: reservationId,
    orderDatetime: orderDatetime,
  );
}

class GuestDetail {
  final int guestCount;

  GuestDetail({required this.guestCount});

  Map<String, dynamic> toJson() => {'guest_count': guestCount};

  GuestDetailEntity toEntity() => GuestDetailEntity(guestCount: guestCount);
}

class CreateOrderResponse {
  final int restaurantId;
  final int zoneId;
  final int orderId;
  final int couponAmount;
  final String status;
  final String tableName;
  final String zoneName;
  final String tableStatus;
  final String orderType;

  CreateOrderResponse({
    required this.restaurantId,
    required this.zoneId,
    required this.orderId,
    required this.couponAmount,
    required this.status,
    required this.tableName,
    required this.zoneName,
    required this.tableStatus,
    required this.orderType,
  });

  factory CreateOrderResponse.fromJson(Map<String, dynamic> json) {
    return CreateOrderResponse(
      restaurantId: json['restaurant_id'] ?? 0,
      zoneId: json['zone_id'] ?? 0,
      orderId: json['order_id'] ?? 0,
      couponAmount: json['coupon_amount'] ?? 0,
      status: json['status'] ?? '',
      tableName: json['table_name'] ?? '',
      zoneName: json['zone_name'] ?? '',
      tableStatus: json['table_status'] ?? '',
      orderType: json['order_type'] ?? '',
    );
  }

  CreateOrderResponseEntity toEntity() => CreateOrderResponseEntity(
    restaurantId: restaurantId,
    zoneId: zoneId,
    orderId: orderId,
    couponAmount: couponAmount,
    status: status,
    tableName: tableName,
    zoneName: zoneName,
    tableStatus: tableStatus,
    orderType: orderType,
  );
}