import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrderItem {
  final int? lineItemId;
  final String name;
  final int qty;
  String status;

  // ============================================================
  // ITEM DETAILS
  // ============================================================

  final String note;
  final bool? isVeg;
  final String category;

  final List<Map<String, dynamic>> modifiers;
  final List<Map<String, dynamic>> addons;

  OrderItem({
    this.lineItemId,
    required this.name,
    required this.qty,
    this.status = 'New',
    this.note = '',
    this.isVeg,
    this.category = 'OTHER',
    this.modifiers = const [],
    this.addons = const [],
  });

  // ============================================================
  // FROM JSON
  // ============================================================

  factory OrderItem.fromJson(
      Map<String, dynamic> json,
      ) {
    debugPrint('');
    debugPrint('==============================================');
    debugPrint('           ORDER ITEM PARSING');
    debugPrint('==============================================');
    debugPrint('ITEM JSON => $json');

    // ==========================================================
    // VEG / NON-VEG
    // ==========================================================
// ==========================================================
// VEG / NON-VEG
//
// true  -> Veg
// false -> Non-Veg
// null  -> No icon
// ==========================================================

    final dynamic rawIsVeg;

    if (json.containsKey('is_veg')) {
      // IMPORTANT:
      // If backend sends is_veg: null,
      // preserve null. Do NOT fallback.
      rawIsVeg = json['is_veg'];
    } else if (json.containsKey('isVeg')) {
      rawIsVeg = json['isVeg'];
    } else if (json.containsKey('is_vegetarian')) {
      rawIsVeg = json['is_vegetarian'];
    } else if (json.containsKey('veg')) {
      rawIsVeg = json['veg'];
    } else {
      rawIsVeg = null;
    }

    final bool? isVeg;

    if (rawIsVeg == null) {
      isVeg = null;
    } else {
      final normalized =
      rawIsVeg.toString().trim().toLowerCase();

      if (rawIsVeg == true ||
          rawIsVeg == 1 ||
          normalized == 'true' ||
          normalized == '1' ||
          normalized == 'yes') {
        isVeg = true;
      } else if (
      rawIsVeg == false ||
          rawIsVeg == 0 ||
          normalized == 'false' ||
          normalized == '0' ||
          normalized == 'no') {
        isVeg = false;
      } else {
        isVeg = null;
      }
    }

    debugPrint('RAW IS VEG => $rawIsVeg');
    debugPrint('PARSED IS VEG => $isVeg');
    // ==========================================================
    // CATEGORY
    // ==========================================================

    String parsedCategory = 'OTHER';

    final categoryValues = [
      json['categoryName'],
      json['category_name'],
      json['category'],
      json['sectionName'],
      json['section_name'],
      json['section'],
    ];

    for (final value in categoryValues) {
      final categoryValue =
          value?.toString().trim() ?? '';

      if (categoryValue.isNotEmpty) {
        parsedCategory = categoryValue;
        break;
      }
    }

    debugPrint(
      'PARSED CATEGORY => $parsedCategory',
    );

    // ==========================================================
    // META DATA
    // ==========================================================

    final metaData = json['meta_data'];

    debugPrint(
      'META DATA => $metaData',
    );

    // ==========================================================
    // ADDONS
    // ==========================================================

    List<Map<String, dynamic>> parsedAddons = [];

    final rawAddons =
        json['addons'] ??
            json['addOns'] ??
            json['add_ons'];

    // ----------------------------------------------------------
    // DIRECT ADDONS
    // ----------------------------------------------------------

    if (rawAddons is Map) {
      rawAddons.forEach((key, value) {
        if (value is Map) {
          parsedAddons.add({
            'name': key.toString(),
            'qty':
            value['quantity'] ??
                value['qty'] ??
                1,
            'price':
            value['price'] ?? 0,
          });
        } else {
          parsedAddons.add({
            'name': key.toString(),
            'qty': 1,
            'price': 0,
          });
        }
      });
    } else if (rawAddons is List) {
      parsedAddons =
          rawAddons.map<Map<String, dynamic>>((e) {
            if (e is Map) {
              return Map<String, dynamic>.from(e);
            }

            return {
              'name': e.toString(),
              'qty': 1,
              'price': 0,
            };
          }).toList();
    }

    // ----------------------------------------------------------
    // ADDONS FROM META DATA
    // ----------------------------------------------------------

    if (parsedAddons.isEmpty &&
        metaData is List) {
      for (final meta in metaData) {
        if (meta is! Map) {
          continue;
        }

        final key =
        meta['key']?.toString().trim().toLowerCase();

        if (key == '_addons' ||
            key == 'addons' ||
            key == 'add_ons') {

          final value = meta['value'];

          if (value is List) {
            parsedAddons =
                value.map<Map<String, dynamic>>((e) {
                  if (e is Map) {
                    return {
                      'name':
                      e['name']?.toString() ?? '',
                      'qty':
                      e['quantity'] ??
                          e['qty'] ??
                          1,
                      'price':
                      e['price'] ?? 0,
                    };
                  }

                  return {
                    'name': e.toString(),
                    'qty': 1,
                    'price': 0,
                  };
                }).where((e) {
                  return e['name']
                      .toString()
                      .trim()
                      .isNotEmpty;
                }).toList();
          }

          break;
        }
      }
    }

    debugPrint(
      'PARSED ADDONS => $parsedAddons',
    );

    // ==========================================================
    // MODIFIERS
    // ==========================================================

    List<Map<String, dynamic>> parsedModifiers = [];

    final rawModifiers =
    json['modifiers'];

    // ----------------------------------------------------------
    // DIRECT MODIFIERS
    // ----------------------------------------------------------

    if (rawModifiers is List) {
      parsedModifiers =
          rawModifiers.map<Map<String, dynamic>>((e) {
            if (e is Map) {
              return {
                'name':
                e['name']?.toString() ??
                    e['modifier_name']?.toString() ??
                    '',
                'quantity':
                e['quantity'] ?? 1,
              };
            }

            return {
              'name': e.toString(),
              'quantity': 1,
            };
          }).where((e) {
            return e['name']
                .toString()
                .trim()
                .isNotEmpty;
          }).toList();
    }

    // ----------------------------------------------------------
    // MODIFIERS FROM META DATA
    // ----------------------------------------------------------

    if (parsedModifiers.isEmpty &&
        metaData is List) {
      for (final meta in metaData) {
        if (meta is! Map) {
          continue;
        }

        final key =
        meta['key']?.toString().trim().toLowerCase();

        if (key == '_modifiers' ||
            key == 'modifiers') {

          final value = meta['value'];

          if (value is List) {
            parsedModifiers =
                value.map<Map<String, dynamic>>((e) {
                  if (e is Map) {
                    return {
                      'name':
                      e['name']?.toString() ??
                          e['modifier_name']?.toString() ??
                          '',
                      'quantity':
                      e['quantity'] ?? 1,
                    };
                  }

                  return {
                    'name': e.toString(),
                    'quantity': 1,
                  };
                }).where((e) {
                  return e['name']
                      .toString()
                      .trim()
                      .isNotEmpty;
                }).toList();
          }

          break;
        }
      }
    }

    debugPrint(
      'PARSED MODIFIERS => $parsedModifiers',
    );

    // ==========================================================
    // NOTE
    // ==========================================================

    String parsedNote = '';

    // ----------------------------------------------------------
    // DIRECT NOTE
    // ----------------------------------------------------------

    final directNote =
        json['note'] ??
            json['notes'];

    if (directNote != null) {
      final value =
      directNote.toString().trim();

      if (value.isNotEmpty) {
        parsedNote = value;
      }
    }

    // ----------------------------------------------------------
    // NOTE FROM META DATA
    // ----------------------------------------------------------

    if (parsedNote.isEmpty &&
        metaData is List) {
      for (final meta in metaData) {
        if (meta is! Map) {
          continue;
        }

        final key =
        meta['key']?.toString().trim().toLowerCase();

        if (key == '_modifier_notes' ||
            key == 'modifier_notes' ||
            key == '_note' ||
            key == 'note' ||
            key == 'notes') {

          final value = meta['value'];

          if (value != null) {
            final noteValue =
            value.toString().trim();

            if (noteValue.isNotEmpty) {
              parsedNote = noteValue;
              break;
            }
          }
        }
      }
    }

    debugPrint(
      'PARSED NOTE => $parsedNote',
    );

    // ==========================================================
    // CREATE ORDER ITEM
    // ==========================================================

    final orderItem = OrderItem(
      lineItemId:
      (json['id'] as num?)?.toInt(),

      name:
      json['name']?.toString() ??
          json['item_name']?.toString() ??
          json['product_name']?.toString() ??
          'Unknown',

      qty:
      (json['qty'] as num?)?.toInt() ??
          (json['quantity'] as num?)?.toInt() ??
          1,

      status:
      json['status']?.toString() ??
          'New',

      note: parsedNote,

      isVeg: isVeg,

      category: parsedCategory,

      modifiers: parsedModifiers,

      addons: parsedAddons,
    );

    // ==========================================================
    // FINAL DEBUG
    // ==========================================================

    debugPrint(
      '----------------------------------------------',
    );
    debugPrint(
      'FINAL ITEM => ${orderItem.name}',
    );
    debugPrint(
      'FINAL VEG => ${orderItem.isVeg}',
    );
    debugPrint(
      'FINAL MODIFIERS => ${orderItem.modifiers}',
    );
    debugPrint(
      'FINAL ADDONS => ${orderItem.addons}',
    );
    debugPrint(
      'FINAL NOTE => ${orderItem.note}',
    );
    debugPrint(
      '==============================================',
    );

    return orderItem;
  }

  // ============================================================
  // TO JSON
  // ============================================================

  Map<String, dynamic> toJson() => {
    'id': lineItemId,
    'name': name,
    'qty': qty,
    'status': status,
    'note': note,
    'is_veg': isVeg,
    'category': category,
    'modifiers': modifiers,
    'addons': addons,
  };
}

// ==================================================================
// KITCHEN ORDER
// ==================================================================

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
  final String kotOrderStatus;

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
    this.kotOrderStatus = '',
    this.servedAt,
  });

  // ================================================================
  // HEADER COLOR
  // ================================================================

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

  // ================================================================
  // LOCATION
  // ================================================================

  String get locationLabel {
    final zone =
        zoneName?.trim() ?? '';

    final table =
        tableName?.trim() ?? '';

    if (zone.isEmpty &&
        table.isEmpty) {
      return type;
    }

    if (zone.isEmpty) {
      return '$type - $table';
    }

    if (table.isEmpty) {
      return '$type - $zone';
    }

    return '$type - $zone-$table';
  }

  // ================================================================
  // KOT NUMBER
  // ================================================================

  String get kotNo =>
      id.replaceAll('KOT#', '');

  // ================================================================
  // TIME
  // ================================================================

  static DateTime? _parseKotTime(
      String? value,
      ) {
    if (value == null ||
        value.isEmpty) {
      return DateTime.now();
    }

    try {
      return DateFormat(
        'yyyy-MM-dd hh:mm a',
      ).parse(value);
    } catch (_) {
      return DateTime.now();
    }
  }

  // ================================================================
  // MQTT
  // ================================================================

  factory KitchenOrder.fromMqttPayload(
      Map<String, dynamic> payload,
      ) {
    // ============================================================
    // KOT
    // ============================================================

    final kot = Map<String, dynamic>.from(
      payload['kot'] as Map? ?? {},
    );

    debugPrint('');
    debugPrint('############################################');
    debugPrint('          MQTT KOT RECEIVED');
    debugPrint('############################################');
    debugPrint('KOT PAYLOAD => $kot');

    // ============================================================
    // LINE ITEMS
    // ============================================================

    final dynamic rawItemsValue =
        kot['line_items'] ??
            kot['items'] ??
            kot['kot_items'];

    final List<dynamic> rawItems =
    rawItemsValue is List
        ? rawItemsValue
        : <dynamic>[];

    debugPrint(
      'MQTT TOTAL ITEMS => ${rawItems.length}',
    );

    // ============================================================
    // KOT NUMBER
    // ============================================================

    final kotNumber =
        kot['kot_number']?.toString() ??
            'KOT#${kot['id'] ?? DateTime.now().millisecondsSinceEpoch}';

    // ============================================================
    // CREATE ITEMS
    // ============================================================

    final parsedItems = <OrderItem>[];

    for (final rawItem in rawItems) {
      if (rawItem is! Map) {
        continue;
      }

      final item = Map<String, dynamic>.from(rawItem);

      // ========================================================
      // CATEGORY
      // ========================================================

      String category = 'OTHER';

      final categoryValues = [
        item['categoryName'],
        item['category_name'],
        item['category'],
        item['sectionName'],
        item['section_name'],
        item['section'],
      ];

      for (final value in categoryValues) {
        final valueString =
            value?.toString().trim() ?? '';

        if (valueString.isNotEmpty) {
          category = valueString;
          break;
        }
      }

      item['category'] = category;

      // ========================================================
      // VEG DEBUG - BEFORE MODEL
      // ========================================================

      debugPrint('');
      debugPrint('==============================================');
      debugPrint('KOT ITEM => '
          '${item['name'] ?? item['item_name']}');

      debugPrint(
        'PRODUCT ID => '
            '${item['product_id'] ?? item['productId']}',
      );

      debugPrint(
        'HAS is_veg => ${item.containsKey('is_veg')}',
      );

      debugPrint(
        'RAW is_veg => ${item['is_veg']}',
      );

      debugPrint(
        'RAW is_veg TYPE => '
            '${item['is_veg']?.runtimeType}',
      );

      debugPrint(
        'RAW isVeg => ${item['isVeg']}',
      );

      debugPrint(
        'RAW isVeg TYPE => '
            '${item['isVeg']?.runtimeType}',
      );

      debugPrint(
        'RAW MODIFIERS => ${item['modifiers']}',
      );

      debugPrint(
        'RAW ADDONS => ${item['addons']}',
      );

      debugPrint(
        'RAW NOTE => ${item['note']}',
      );

      debugPrint(
        'CATEGORY => $category',
      );

      debugPrint('==============================================');

      // ========================================================
      // PARSE ITEM
      // ========================================================

      final parsedItem = OrderItem.fromJson(item);

      // ========================================================
      // VEG DEBUG - AFTER MODEL
      // ========================================================

      debugPrint(
        'MODEL ITEM => ${parsedItem.name}',
      );

      debugPrint(
        'MODEL isVeg => ${parsedItem.isVeg}',
      );

      debugPrint(
        'MODEL isVeg TYPE => '
            '${parsedItem.isVeg?.runtimeType}',
      );

      debugPrint('==============================================');

      parsedItems.add(parsedItem);
    }

    // ============================================================
    // CREATE KITCHEN ORDER
    // ============================================================

    return KitchenOrder(
      id: kotNumber,

      kotId:
      (kot['id'] as num?)?.toInt(),

      parentOrderId:
      (payload['parent_order_id']
      as num?)?.toInt() ??
          (kot['parent_order_id']
          as num?)?.toInt(),

      zoneId:
      (payload['zone_id']
      as num?)?.toInt(),

      zoneName:
      payload['zone_name']
          ?.toString(),

      type:
      payload['order_type']
          ?.toString() ??
          'Dine-In',

      status: 'Pending',

      tableName:
      payload['table_name']
          ?.toString(),

      kotTime:
      _parseKotTime(
        kot['time']?.toString(),
      ),

      items: parsedItems,
    );
  }

  // ================================================================
  // LOAD FROM LOCAL STORAGE
  // ================================================================

  factory KitchenOrder.fromJson(
      Map<String, dynamic> json,
      ) {
    final kotStatus =
        json['kot_status']
            ?.toString()
            .trim()
            .toLowerCase() ??
            '';

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

    final rawItems =
        (json['kot_items'] ??
            json['items'])
        as List? ??
            [];

    return KitchenOrder(
      id: json['kot_number']?.toString() ?? '',

      kotId:
      (json['kot_id'] as num?)?.toInt(),

      parentOrderId:
      (json['order_id'] as num?)?.toInt(),

      zoneId:
      (json['zone_id'] as num?)?.toInt(),

      zoneName:
      json['zone_name']?.toString(),

      type:
      json['order_type']?.toString() ?? 'Dine In',

      status: uiStatus,

      // Preparing / Ready / Served
      kotStatus:
      json['kot_status']
          ?.toString() ??
          '',

      // New / Running
      kotOrderStatus:
      json['kot_order_status']
          ?.toString()
          .trim() ??
          '',

      tableName:
      json['table_name']?.toString(),

      kotTime:
      _parseKotTime(
        json['kot_time']?.toString(),
      ),

      items:
      rawItems.map((e) {
        return OrderItem.fromJson(
          Map<String, dynamic>.from(e),
        );
      }).toList(),

      servedAt:
      json['servedAt'] != null
          ? DateTime.tryParse(
        json['servedAt'].toString(),
      )
          : null,
    );
  }

  // ================================================================
  // SAVE TO LOCAL STORAGE
  // ================================================================

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
    'kotTime':
    kotTime?.toIso8601String(),

    'items':
    items.map(
          (item) => item.toJson(),
    ).toList(),

    'kotStatus': kotStatus,
    'kotOrderStatus': kotOrderStatus,

    'servedAt':
    servedAt?.toIso8601String(),
  };

  // ================================================================
  // UI MAP
  // ================================================================

  Map<String, dynamic> toUiMap() => {
    'id': id,
    'kotNumber': id,
    'kotNo': kotNo,
    'kotId': kotId,
    'parentOrderId': parentOrderId,
    'zoneId': zoneId,
    'zoneName': zoneName,
    'type': type,
    // 'status': status,
    // Overall UI status
    'status': status,

    // KOT preparation status
    'kot_status': kotStatus,

    // KOT order status: New / Running
    'kot_order_status': kotOrderStatus,
    'isCancelled': isCancelled,
    'tableName': tableName,
    'locationLabel': locationLabel,
    'kotTime': kotTime,
    'headerColor': headerColor,
    'servedAt': servedAt,

    // ========================================================
    // ITEMS
    // ========================================================

    'items': items.map(
          (item) {
        return {
          'id': item.lineItemId,
          'lineItemId':
          item.lineItemId,

          'name': item.name,

          'qty': item.qty,
          'quantity': item.qty,

          'status': item.status,

          // ==================================================
          // NOTE
          // ==================================================

          'note': item.note,

          // ==================================================
          // VEG / NON-VEG
          // ==================================================

          'is_veg': item.isVeg,
          'isVeg': item.isVeg,

          // ==================================================
          // CATEGORY
          // ==================================================

          'category':
          item.category,

          // ==================================================
          // MODIFIERS
          // ==================================================

          'modifiers':
          item.modifiers,

          // ==================================================
          // ADDONS
          // ==================================================

          'addons':
          item.addons,

          'addOns':
          item.addons,
        };
      },
    ).toList(),
  };
}