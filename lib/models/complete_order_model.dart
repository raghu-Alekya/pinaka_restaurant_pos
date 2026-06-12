import 'package:intl/intl.dart';

class CompletedOrderModel {
  final int orderId;
  final String orderType;
  final String tableName;
  final String finishedTime;
  final String prepTime;
  final String status;
  final bool canRecall;
  final DateTime? finishedDateTime;

  CompletedOrderModel({
    required this.orderId,
    required this.orderType,
    required this.tableName,
    required this.finishedTime,
    required this.prepTime,
    required this.status,
    required this.canRecall,
    this.finishedDateTime,
  });

  factory CompletedOrderModel.fromJson(Map<String, dynamic> json) {
    return CompletedOrderModel(
      orderId: json['order_id'] ?? 0,
      orderType: json['order_type'] ?? '',
      tableName: json['table_name'] ?? '-',
      finishedTime: json['finished_time'] ?? '',
      prepTime: json['prep_time'] ?? '',
      status: json['status'] ?? '',
      canRecall: json['can_recall'] ?? false,
      finishedDateTime: json['finished_time'] != null
          ? DateFormat('yyyy-MM-dd hh:mm a')
          .parse(json['finished_time'])
          : null,
    );
  }
}