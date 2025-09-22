import 'order_items.dart';

class KotModel {
  final int kotId;            // server kot_id (numeric)
  final String kotNumber;     // server kot_number (e.g., "KOT#0042")
  final DateTime time;
  final String status;        // e.g., 'Pending', 'Served', 'Cancelled'
  final List<OrderItems> items;

  KotModel({
    required this.kotId,
    required this.kotNumber,
    required this.time,
    required this.status,
    required this.items,
  });

  factory KotModel.fromJson(Map<String, dynamic> json) {
    return KotModel(
      kotId: json['kot_id'] ?? 0,
      kotNumber: json['kot_number'] ?? '',          // ✅ pull kot_number from API
      time: DateTime.now(),                         // API doesn’t give time, so fallback
      status: json['status'] ?? 'Pending',
      items: (json['items'] as List<dynamic>? ?? [])
          .map((item) => OrderItems.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'kot_id': kotId,
      'kot_number': kotNumber,
      'time': time.toIso8601String(),
      'status': status,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}
