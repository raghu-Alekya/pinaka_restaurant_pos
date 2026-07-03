import 'package:intl/intl.dart';

class CompletedOrderModel {
  final int orderId;
  final String orderType;
  final int tableId;
  final int zoneId;
  final String tableName;
  final int kotOrderId;
  final String kotNumber;
  final String finishedTime;
  final String prepTime;
  final String status;
  final int restaurantId;
  final bool canRecall;
  final DateTime? finishedDateTime;

  CompletedOrderModel({
    required this.orderId,
    required this.orderType,
    required this.tableId,
    required this.zoneId,
    required this.tableName,
    required this.kotOrderId,
    required this.kotNumber,
    required this.finishedTime,
    required this.prepTime,
    required this.status,
    required this.restaurantId,
    required this.canRecall,
    this.finishedDateTime,
  });

  factory CompletedOrderModel.fromJson(
      Map<String, dynamic> json,
      ) {
    DateTime? parsedDate;

    try {
      final finishedTime =
          json['finished_time']?.toString() ?? '';

      if (finishedTime.isNotEmpty) {
        parsedDate = DateFormat(
          'yyyy-MM-dd hh:mm a',
        ).parse(finishedTime);
      }
    } catch (e) {
      print('Date Parse Error: $e');
    }

    return CompletedOrderModel(
      orderId: json['order_id'] ?? 0,
      orderType: json['order_type'] ?? '',
      tableId: json['table_id'] ?? 0,
      tableName: json['table_name'] ?? '',
      zoneId: json['zone_id'] ?? 0,
      kotOrderId: json['kot_order_id'] ?? 0,
      kotNumber: json['kot_number'] ?? '',
      finishedTime: json['finished_time'] ?? '',
      prepTime: json['prep_time'] ?? '',
      status: json['status'] ?? '',
      restaurantId: json['restaurant_id'] ?? 0,
      canRecall: json['can_recall'] ?? false,
      finishedDateTime: parsedDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'order_type': orderType,
      'table_id': tableId,
      'zone_id': zoneId,
      'table_name': tableName,
      'kot_order_id': kotOrderId,
      'kot_number': kotNumber,
      'finished_time': finishedTime,
      'prep_time': prepTime,
      'status': status,
      'restaurant_id': restaurantId,
      'can_recall': canRecall,
    };
  }
}
class CompletedOrdersResponse {
  final List<CompletedOrderModel> orders;
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int completedCount;
  final int cancelledCount;

  CompletedOrdersResponse({
    required this.orders,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.completedCount,
    required this.cancelledCount,
  });

  factory CompletedOrdersResponse.fromJson(Map<String, dynamic> json) {
    return CompletedOrdersResponse(
      orders: (json["data"] as List)
          .map((e) => CompletedOrderModel.fromJson(e))
          .toList(),

      currentPage: json["current_page"] ?? 1,
      totalPages: json["total_pages"] ?? 1,
      totalItems: int.parse(json["total_items"].toString()),
      completedCount: json["completed_count"] ?? 0,
      cancelledCount: json["cancelled_count"] ?? 0,
    );
  }
}