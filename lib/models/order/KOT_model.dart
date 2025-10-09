import 'package:intl/intl.dart';
import 'order_items.dart';

class KotModel {
  final int kotId;
  final String kotNumber;
  final DateTime time;
  final String status;
  final List<OrderItems> items;
  final int parentOrderId;
  final int captainId; // ✅ Add this field

  KotModel({
    required this.kotId,
    required this.kotNumber,
    required this.time,
    required this.status,
    required this.items,
    required this.parentOrderId,
    required this.captainId, // ✅ Add to constructor
  });

  /// Safe JSON parsing
  factory KotModel.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    String parseString(dynamic value, [String fallback = '']) {
      if (value == null) return fallback;
      return value.toString();
    }

    DateTime parseTime(String? value) {
      if (value == null || value.isEmpty) return DateTime.now();
      try {
        // Parse "yyyy-MM-dd hh:mm a" format
        return DateFormat("yyyy-MM-dd hh:mm a").parse(value);
      } catch (_) {
        return DateTime.now();
      }
    }

    List<OrderItems> parseItems(dynamic value) {
      if (value == null || value is! List) return [];
      return value.map<OrderItems>((item) => OrderItems.fromJson(item)).toList();
    }

    return KotModel(
      kotId: parseInt(json['id']),
      kotNumber: parseString(json['kot_number'], 'KOT#${json['id'] ?? DateTime.now().millisecondsSinceEpoch}'),
      time: parseTime(parseString(json['time'])),
      status: parseString(json['status'], 'Pending'),
      items: parseItems(json['line_items']),
      parentOrderId: parseInt(json['parent_order_id']),
      captainId: parseInt(json['captain_id']), // ✅ Correctly parsed
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': kotId,
      'kot_number': kotNumber,
      'time': DateFormat("yyyy-MM-dd hh:mm a").format(time),
      'status': status,
      'line_items': items.map((item) => item.toJson()).toList(),
      'parent_order_id': parentOrderId,
      'captain_id': captainId, // ✅ Include in KOT body
    };
  }
}
