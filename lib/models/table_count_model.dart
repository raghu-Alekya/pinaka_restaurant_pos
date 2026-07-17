class TableStatusCountModel {
  final bool success;
  final int availableTables;
  final int reservedTables;
  final int dineinTables;
  final int readyToPayTables;
  final int totalTables;

  TableStatusCountModel({
    required this.success,
    required this.availableTables,
    required this.reservedTables,
    required this.dineinTables,
    required this.readyToPayTables,
    required this.totalTables,
  });

  factory TableStatusCountModel.fromJson(Map<String, dynamic> json) {
    return TableStatusCountModel(
      success: json['success'] ?? false,
      availableTables: json['available_tables'] ?? 0,
      reservedTables: json['reserved_tables'] ?? 0,
      dineinTables: json['dinein_tables'] ?? 0,
      readyToPayTables: json['ready_to_pay_tables'] ?? 0,
      totalTables: json['total_tables'] ?? 0,
    );
  }
}
class ReservationStatusCountModel {
  final int upcoming;
  final int seated;
  final int cancelled;
  final int expired;
  final int totalReservations;
  final int restaurantId;

  ReservationStatusCountModel({
    required this.upcoming,
    required this.seated,
    required this.cancelled,
    required this.expired,
    required this.totalReservations,
    required this.restaurantId,

  });

  factory ReservationStatusCountModel.fromJson(
      Map<String, dynamic> json,
      ) {
    final counts = json['reservation_status_counts'] ?? {};

    return ReservationStatusCountModel(
      upcoming: counts['upcoming'] ?? 0,
      seated: counts['seated'] ?? 0,
      cancelled: counts['cancelled'] ?? 0,
      expired: counts['expired'] ?? 0,
      totalReservations: counts['total_reservations'] ?? 0,
      restaurantId: json['restaurant_id'] ?? 0,

    );
  }
}
class ActiveOrdersCountModel {
  final bool success;
  final String message;
  final int restaurantId;
  final int activeOrdersCount;

  ActiveOrdersCountModel({
    required this.success,
    required this.message,
    required this.restaurantId,
    required this.activeOrdersCount,
  });

  factory ActiveOrdersCountModel.fromJson(Map<String, dynamic> json) {
    return ActiveOrdersCountModel(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      restaurantId: json['restaurant_id'] ?? 0,
      activeOrdersCount: json['active_orders_count'] ?? 0,
    );
  }
}