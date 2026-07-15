import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrderItem {
  final int? lineItemId;
  final String name;
  final int qty;
  String status;
  final String note;
  final bool isVeg;

  final List<Map<String, dynamic>> modifiers;
  final List<Map<String, dynamic>> addons;

  OrderItem({
    this.lineItemId,
    required this.name,
    required this.qty,
    this.status = 'New',
    this.note = '',
    this.isVeg = true,
    this.modifiers = const [],
    this.addons = const [],
  });


  factory OrderItem.fromJson(Map<String, dynamic> json) {
    debugPrint("ITEM JSON => $json");
    debugPrint("MODIFIERS => ${json['modifiers']}");
    debugPrint("ADDONS => ${json['addons']}");
    debugPrint("ADDONS (MQTT) => ${json['addOns']}");

    final rawIsVeg = json['is_veg'] ?? json['isVeg'] ?? json['veg'];

    final bool isVeg = rawIsVeg == null
        ? true
        : (rawIsVeg == true ||
        rawIsVeg == 1 ||
        rawIsVeg.toString().toLowerCase() == 'true' ||
        rawIsVeg.toString() == '1');

    // Handle both API and MQTT addon formats
    final rawAddons = json['addons'] ?? json['addOns'];

    List<Map<String, dynamic>> parsedAddons = [];

    if (rawAddons is Map) {
      rawAddons.forEach((key, value) {
        parsedAddons.add({
          'name': key.toString(),
          'qty': value['quantity'] ?? 1,
          'price': value['price'] ?? 0,
        });
      });
    } else if (rawAddons is List) {
      parsedAddons = rawAddons.map<Map<String, dynamic>>((e) {
        if (e is Map) {
          return Map<String, dynamic>.from(e);
        }
        return {
          'name': e.toString(),
          'qty': 1,
        };
      }).toList();
    }

    final parsedModifiers =
    (json['modifiers'] as List? ?? []).map<Map<String, dynamic>>((e) {
      if (e is Map) {
        return Map<String, dynamic>.from(e);
      }
      return {
        'name': e.toString(),
      };
    }).toList();

    debugPrint("PARSED MODIFIERS => $parsedModifiers");
    debugPrint("PARSED ADDONS => $parsedAddons");


    return OrderItem(
      lineItemId: (json['id'] as num?)?.toInt(),
      name: json['name']?.toString() ??
          json['item_name']?.toString() ??
          'Unknown',

      qty: (json['qty'] as num?)?.toInt() ??
          (json['quantity'] as num?)?.toInt() ??
          1,

      status: json['status']?.toString() ?? 'New',

      note: json['note']?.toString() ?? '',

      isVeg: isVeg,

      modifiers: parsedModifiers,

      addons: parsedAddons,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': lineItemId,
    'name': name,
    'qty': qty,
    'status': status,
    'note': note,
    'is_veg': isVeg,
    'modifiers': modifiers,
    'addons': addons,
  };
}
class KitchenOrder {
  final String id;
  final int? kotId;
  final int? parentOrderId;
  final int? zoneId;
  final String? zoneName;
  final String type;
  String status;
  bool isCancelled;
  final String? tableName;
  final DateTime? kotTime;
  final List<OrderItem> items;
  final String kotStatus;
  DateTime? servedAt;

  KitchenOrder({
    required this.id,
    this.kotId,
    this.parentOrderId,
    this.zoneId,
    this.zoneName,
    required this.type,
    this.status = 'Pending',
    this.isCancelled = false,
    this.tableName,
    this.kotTime,
    required this.items,
    this.kotStatus = '',
    this.servedAt,
  });

  Color get headerColor {
    switch (type) {
      case 'Takeaway':
        return const Color(0xffE67E50);
      case 'Online':
        return const Color(0xff4CAF50);
      default:
        return const Color(0xff6C74B8);
    }
  }

  String get locationLabel {
    final zone = zoneName?.trim() ?? '';
    final table = tableName?.trim() ?? '';
    if (zone.isEmpty && table.isEmpty) return type;
    if (zone.isEmpty) return '$type - $table';
    if (table.isEmpty) return '$type - $zone';
    return '$type - $zone-$table';
  }

  String get kotNo => id.replaceAll('KOT#', '');

  static DateTime? _parseKotTime(String? value) {
    if (value == null || value.isEmpty) return DateTime.now();
    try {
      return DateFormat('yyyy-MM-dd hh:mm a').parse(value);
    } catch (_) {
      return DateTime.now();
    }
  }

  factory KitchenOrder.fromMqttPayload(Map<String, dynamic> payload) {
    final kot = Map<String, dynamic>.from(payload['kot'] as Map? ?? {});
    final rawItems = kot['line_items'] as List<dynamic>? ?? [];
    final kotNumber = kot['kot_number']?.toString() ??
        'KOT#${kot['id'] ?? DateTime.now().millisecondsSinceEpoch}';

    return KitchenOrder(
      id: kotNumber,
      kotId: (kot['id'] as num?)?.toInt(),
      parentOrderId: (payload['parent_order_id'] as num?)?.toInt() ??
          (kot['parent_order_id'] as num?)?.toInt(),
      zoneId: (payload['zone_id'] as num?)?.toInt(),
      zoneName: payload['zone_name']?.toString(),
      type: payload['order_type']?.toString() ?? 'Dine-In',
      status: 'Pending',
      tableName: payload['table_name']?.toString(),
      kotTime: _parseKotTime(kot['time']?.toString()),
      items: rawItems
          .map((item) => OrderItem.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }

  /// Load from local storage (SharedPreferences)
  factory KitchenOrder.fromJson(Map<String, dynamic> json) {
    final kotStatus =
        json['kot_status']?.toString().trim().toLowerCase() ?? '';

    String uiStatus;

    switch (kotStatus) {
      case 'processing':
        uiStatus = 'Pending';
        break;

      case 'preparing':
        uiStatus = 'Preparing';
        break;

      case 'ready':
        uiStatus = 'Ready';
        break;

      case 'served':
      case 'completed':
        uiStatus = 'Served';
        break;

      default:
        uiStatus = 'Pending';
    }
    final rawItems = (json['kot_items'] ?? json['items']) as List? ?? [];

    return KitchenOrder(
      id: json['kot_number']?.toString() ?? '',
      kotId: (json['kot_id'] as num?)?.toInt(),
      parentOrderId: (json['order_id'] as num?)?.toInt(),
      zoneId: (json['zone_id'] as num?)?.toInt(),
      zoneName: json['zone_name']?.toString(),
      type: json['order_type']?.toString() ?? 'Dine In',
      status: uiStatus,
      kotStatus: json['kot_status']?.toString() ?? '',
      tableName: json['table_name']?.toString(),
      kotTime: _parseKotTime(json['kot_time']?.toString()),
      items: rawItems
          .map((e) => OrderItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      servedAt: json['servedAt'] != null
          ? DateTime.tryParse(json['servedAt'].toString())
          : null,
    );
  }
  /// Save to local storage
  Map<String, dynamic> toJson() => {
    'id': id,
    'kotId': kotId,
    'parentOrderId': parentOrderId,
    'zoneId': zoneId,
    'zoneName': zoneName,
    'type': type,
    'status': status,
    'isCancelled': isCancelled,
    'tableName': tableName,
    'kotTime': kotTime?.toIso8601String(),
    'items': items.map((item) => item.toJson()).toList(),
    'kotStatus': kotStatus,
    'servedAt': servedAt?.toIso8601String(),
  };

  /// For UI widgets
  Map<String, dynamic> toUiMap() => {
    'id': id,
    'kotNumber': id,
    'kotNo': kotNo,
    'kotId': kotId,
    'parentOrderId': parentOrderId,
    'zoneId': zoneId,
    'zoneName': zoneName,
    'type': type,
    'status': status,
    'isCancelled': isCancelled,
    'tableName': tableName,
    'locationLabel': locationLabel,
    'kotTime': kotTime,
    'headerColor': headerColor,
    'servedAt': servedAt,
    'items': items.map((item) => {
      'id': item.lineItemId,          // <-- Add this
      'lineItemId': item.lineItemId,  // <-- Optional but recommended
      'name': item.name,
      'qty': item.qty,
      'status': item.status,
      'note': item.note,
      'is_veg': item.isVeg,
      'modifiers': item.modifiers,
      'addons': item.addons,
    }).toList(),
  };

  // static Future<void> fromJson(e) {}
}