class TipsScreenModel {
  final String date;
  final double totalTipAmt;
  final List<TipOrder> orders;

  TipsScreenModel({
    required this.date,
    required this.totalTipAmt,
    required this.orders,
  });

  factory TipsScreenModel.fromJson(Map<String, dynamic> json) {
    return TipsScreenModel(
      date: json['date'] ?? '',
      totalTipAmt: (json['total_tip_amt'] ?? 0).toDouble(),
      orders: (json['orders'] as List<dynamic>? ?? [])
          .map((e) => TipOrder.fromJson(e))
          .toList(),
    );
  }
}

class TipOrder {
  final int orderId;
  final String orderDate;
  final String orderType;
  final double orderAmt;
  final double orderTipAmt;

  TipOrder({
    required this.orderId,
    required this.orderDate,
    required this.orderType,
    required this.orderAmt,
    required this.orderTipAmt,
  });

  factory TipOrder.fromJson(Map<String, dynamic> json) {
    return TipOrder(
      orderId: json['order_id'] ?? 0,
      orderDate: json['order_date'] ?? '',
      orderType: json['order_type'] ?? '',
      orderAmt: (json['order_amt'] ?? 0).toDouble(),
      orderTipAmt: (json['order_tip_amt'] ?? 0).toDouble(),
    );
  }
}