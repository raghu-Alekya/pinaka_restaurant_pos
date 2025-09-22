class OrderModel {
  final int orderId;
  final int tableId; // int instead of String
  final String tableName;
  final int zone_Id;  // int instead of String
  final String zoneName;
  final String status;

  OrderModel({
    required this.orderId,
    required this.tableId,
    required this.tableName,
    required this.zone_Id,
    required this.zoneName,
    required this.status,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    return OrderModel(
      orderId: json['order_id'] ?? 0,
      tableId: json['table_id'] ?? 0,
      tableName: json['table_name'] ?? '',
      zone_Id: json['zone_id'] ?? 0,
      zoneName: json['zone_name'] ?? '',
      status: json['status'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "order_id": orderId,
      "table_id": tableId,
      "table_name": tableName,
      "zone_id": zone_Id,
      "zone_name": zoneName,
      "status": status,
    };
  }
}
