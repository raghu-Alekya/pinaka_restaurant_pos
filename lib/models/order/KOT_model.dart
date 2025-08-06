import 'order_model.dart';

class KotModel {
  final String kotId;
  final DateTime time;
  final String status; // e.g., 'Pending', 'Served', 'Cancelled'
  final List<OrderItems> items;

  KotModel({
    required this.kotId,
    required this.time,
    required this.status,
    required this.items,
  });

  factory KotModel.fromJson(Map<String, dynamic> json) {
    return KotModel(
      kotId: json['kotId'] ?? '',
      time: DateTime.parse(json['time']),
      status: json['status'] ?? 'Pending',
      items: (json['items'] as List<dynamic>)
          .map((item) => OrderItems.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'kotId': kotId,
      'time': time.toIso8601String(),
      'status': status,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}
