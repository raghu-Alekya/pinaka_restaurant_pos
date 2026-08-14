class CreateOrderRequestEntity {
  final String flagType;
  final int tableId;
  final String tableName;
  final int zoneId;
  final String zoneName;
  final int restaurantId;
  final String restaurantName;
  final int guestCount;
  final List<GuestDetailEntity> guestDetails;
  final String? reservationId;
  final String orderDatetime;

  CreateOrderRequestEntity({
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
}

class GuestDetailEntity {
  final int guestCount;

  GuestDetailEntity({required this.guestCount});
}

class CreateOrderResponseEntity {
  final int restaurantId;
  final int zoneId;
  final int orderId;
  final int couponAmount;
  final String status;
  final String tableName;
  final String zoneName;
  final String tableStatus;
  final String orderType;

  CreateOrderResponseEntity({
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
}