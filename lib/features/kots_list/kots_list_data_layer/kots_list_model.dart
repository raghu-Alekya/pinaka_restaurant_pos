import '../../home_screen/All_tables_list/All_tables_list_data_layer/order_by_table_model.dart';

class KotsListResponse {
  final int parentOrderId;
  final String status;
  final String orderType;
  final double total;
  final int zoneId;
  final String zoneName;
  final int restaurantId;
  final int tableId;
  final String tableName;
  final List<KotOrder> kotOrders;

  KotsListResponse({
    required this.parentOrderId,
    required this.status,
    required this.orderType,
    required this.total,
    required this.zoneId,
    required this.zoneName,
    required this.restaurantId,
    required this.tableId,
    required this.tableName,
    required this.kotOrders,
  });

  factory KotsListResponse.fromJson(Map<String, dynamic> json) {
    final parent = json['parent_order'] as Map<String, dynamic>;
    return KotsListResponse(
      parentOrderId: parent['id'] ?? 0,
      status: parent['status'] ?? '',
      orderType: parent['order_type'] ?? '',
      total: (parent['total'] ?? 0).toDouble(),
      zoneId: parent['zone_id'] ?? 0,
      zoneName: parent['zone_name'] ?? '',
      restaurantId: parent['restaurant_id'] ?? 0,
      tableId: parent['table_id'] ?? 0,
      tableName: parent['table_name'] ?? '',
      kotOrders: (parent['kot_orders'] as List?)
          ?.map((e) => KotOrderFromJson.fromJson(e))
          .toList() ??
          [],
    );
  }
}

extension KotOrderFromJson on KotOrder {
  static KotOrder fromJson(Map<String, dynamic> json) {
    return KotOrder(
      id: json['id'] ?? 0,
      time: json['time'] ?? '',
      status: json['status'] ?? '',
      total: (json['total'] ?? 0).toDouble(),
      kotNumber: json['kot_number'] ?? '',
      // orderBy: json['order_by'],
      lineItems: (json['line_items'] as List?)
          ?.map((e) => LineItemFromJson.fromJson(e))
          .toList() ??
          [],
    );
  }
}

extension LineItemFromJson on LineItem {
  static LineItem fromJson(Map<String, dynamic> json) {
    return LineItem(
      id: json['id'] ?? 0,
      productId: json['product_id'] ?? 0,
      itemName: json['item_name'] ?? '',
      quantity: json['quantity'] ?? 0,
      price: (json['price'] ?? 0).toDouble(),
      amount: (json['amount'] ?? 0).toDouble(),
      originalPrice: (json['original_price'] ?? 0).toDouble(),
      modifiers: json['modifiers'] ?? [],
      combos: json['combos'] ?? [],
      isCancelled: (json['is_cancelled'] ?? 'no').toString(),
    );
  }
}