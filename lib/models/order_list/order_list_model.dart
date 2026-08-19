import 'dart:convert';

class OrderlistModel {
  final String? completedByUserId;
  int? orderId;
  String? orderType;
  String? date;
  String? customerName;
  String? customerPhone;
  String? paymentType;
  int? kotOrderId;

  num? grossTotal;
  num? subTotal;
  num? totalTax;
  num? netTotal;
  num? merchantDiscount;
  num? netPayable;
  num? roundOff;
  num? amount;
  num? discount;
  num? total;
  num? orderPrevTotal;

  String? isUpdated;
  String? updated_remarks;

  int? restaurantId;
  int? zoneId;
  int? tableId;
  String? tableStatus;
  String? zoneName;
  String? tableName;

  String? status;
  bool? isParent;
  String? createdVia;
  String? externalOrderId;

  List<KotOrder>? kotOrders;
  num? serviceChargeValue;
  num? serviceChargePercentage;
  num? tipAmount;
  List<CouponDetail>? couponDetails;
  OrderlistModel({
    this.completedByUserId,
    this.orderId,
    this.orderType,
    this.date,
    this.customerName,
    this.customerPhone,
    this.paymentType,
    this.grossTotal,
    this.subTotal,
    this.totalTax,
    this.netTotal,
    this.kotOrderId,
    this.merchantDiscount,
    this.netPayable,
    this.roundOff,
    this.amount,
    this.discount,
    this.total,
    this.orderPrevTotal,
    this.isUpdated,
    this.updated_remarks,
    this.restaurantId,
    this.zoneId,
    this.tableId,
    this.tableStatus,
    this.zoneName,
    this.tableName,
    this.status,
    this.isParent,
    this.createdVia,
    this.externalOrderId,
    this.kotOrders,
    this.serviceChargeValue,
    this.serviceChargePercentage,
    this.tipAmount,
    this.couponDetails,
  });

  factory OrderlistModel.fromJson(Map<String, dynamic> json) {
    String? parsedOrderType = json['order_type'] ?? json['type'];
    final createdViaStr = json['created_via']?.toString().toLowerCase() ?? '';
    final isOnlineFlag = json['_online_order']?.toString().toLowerCase() == 'yes' ||
        json['is_pos_online']?.toString().toLowerCase() == 'yes';

    if (parsedOrderType == null || parsedOrderType.isEmpty) {
      if (json['external_order_id'] != null ||
          json['pos_system_type'] != null ||
          createdViaStr == 'online' ||
          createdViaStr == 'rest-api' ||
          isOnlineFlag) {
        parsedOrderType = 'Online Order';
      }
    }

    // ===== DEBUG: Print all keys for any order that looks like an online/woocommerce order =====
    final isOnlineLike = (parsedOrderType?.toLowerCase().contains('online') == true)
        || json['created_via']?.toString().toLowerCase() == 'rest-api'
        || json['pos_system_type'] != null
        || json['external_order_id'] != null;
    if (isOnlineLike) {
      print('🟡 [ONLINE ORDER RAW JSON KEYS]: ${json.keys.toList()}');
      print('🟡 order_id=${json["order_id"]} id=${json["id"]} status=${json["status"]} created_via=${json["created_via"]}');
      print('🟡 total=${json["total"]} order_total=${json["order_total"]} net_payable=${json["net_payable"]} amount=${json["amount"]} gross_total=${json["gross_total"]}');
      print('🟡 kot_orders=${json["kot_orders"]?.runtimeType} => ${json["kot_orders"]}');
      print('🟡 line_items=${json["line_items"]?.runtimeType} => ${json["line_items"]}');
      print('🟡 items=${json["items"]?.runtimeType} => ${json["items"]}');
    }
    // ============================================================================================


    String? parsedCustomerName = json['customer_name'];
    if ((parsedCustomerName == null || parsedCustomerName.isEmpty) && json['billing'] is Map) {
      final billing = json['billing'] as Map;
      final firstName = billing['first_name']?.toString() ?? '';
      final lastName = billing['last_name']?.toString() ?? '';
      parsedCustomerName = '$firstName $lastName'.trim();
    }
    if (parsedCustomerName == null || parsedCustomerName.isEmpty) {
      parsedCustomerName = json['external_order_id']?.toString();
    }

    String? parsedCustomerPhone = json['customer_phone'];
    if ((parsedCustomerPhone == null || parsedCustomerPhone.isEmpty) && json['billing'] is Map) {
      parsedCustomerPhone = (json['billing'] as Map)['phone']?.toString();
    }

    num parseAmount(dynamic val) {
      if (val == null) return 0;
      if (val is num) return val;
      final str = val.toString().trim();
      if (str.isEmpty) return 0;
      final cleaned = str.replaceAll(RegExp(r'[^0-9.]'), '');
      return num.tryParse(cleaned) ?? 0;
    }

    num parseFirstPositive(List<dynamic> candidates) {
      for (final item in candidates) {
        final parsed = parseAmount(item);
        if (parsed > 0) return parsed;
      }
      return 0;
    }

    final rawTotal = parseFirstPositive([
      json['total'],
      json['order_total'],
      json['total_amount'],
      json['grand_total'],
      json['net_payable'],
      json['net_total'],
      json['gross_total'],
      json['sub_total'],
      json['amount'],
      json['price'],
    ]);

    num itemsSum = 0;
    if (rawTotal == 0 && json['kot_orders'] is List) {
      for (final kot in json['kot_orders']) {
        if (kot is Map) {
          itemsSum += parseAmount(kot['total']);
        }
      }
    }

    num lineItemsSum = 0;
    if (rawTotal == 0 && itemsSum == 0) {
      final itemsList = json['line_items'] ?? json['items'] ?? json['initial_kot_items'];
      if (itemsList is List) {
        for (final item in itemsList) {
          if (item is Map) {
            lineItemsSum += parseAmount(
              item['total'] ??
              item['total_with_tax'] ??
              item['amount'] ??
              item['price'] ??
              item['line_total'] ??
              item['subtotal']
            );
          }
        }
      }
    }

    final effectiveAmount = rawTotal > 0 ? rawTotal : (itemsSum > 0 ? itemsSum : lineItemsSum);

    return OrderlistModel(
      completedByUserId: json['completed_by_user_id']?.toString(),
      orderId: json['order_id'] is int ? json['order_id'] : int.tryParse(json['order_id']?.toString() ?? json['id']?.toString() ?? ''),
      orderType: parsedOrderType,
      date: json['date'] ?? json['date_created'] ?? json['created_at'],
      customerName: parsedCustomerName,
      customerPhone: parsedCustomerPhone,
      paymentType: json['payment_type'] ?? json['payment_method_title'],
      kotOrderId: json['kot_order_id'] is int ? json['kot_order_id'] : int.tryParse(json['kot_order_id']?.toString() ?? json['id']?.toString() ?? ''),

      grossTotal: parseFirstPositive([json['gross_total'], effectiveAmount]),
      subTotal: parseFirstPositive([json['sub_total'], effectiveAmount]),
      totalTax: parseAmount(json['total_tax']),
      netTotal: parseFirstPositive([json['net_total'], effectiveAmount]),
      merchantDiscount: parseAmount(json['merchant_discount']),
      netPayable: effectiveAmount,
      roundOff: parseAmount(json['round_off']),

      amount: effectiveAmount,
      discount: parseAmount(json['discount']),
      total: effectiveAmount,

      orderPrevTotal: parseAmount(json['order_prev_total']),

      isUpdated: json['is_updated']?.toString(),
      updated_remarks: json['updated_remarks']?.toString(),

      restaurantId: json['restaurant_id'] is int ? json['restaurant_id'] : int.tryParse(json['restaurant_id']?.toString() ?? ''),
      zoneId: json['zone_id'] is int ? json['zone_id'] : int.tryParse(json['zone_id']?.toString() ?? ''),
      tableId: json['table_id'] is int ? json['table_id'] : int.tryParse(json['table_id']?.toString() ?? ''),
      tableStatus: json['table_status']?.toString(),
      zoneName: json['zone_name']?.toString(),
      tableName: json['table_name']?.toString(),

      status: json['status']?.toString(),
      isParent: json['is_parent'] is bool ? json['is_parent'] : true,
      createdVia: json['created_via']?.toString(),
      externalOrderId: json['external_order_id']?.toString(),

      kotOrders: () {
        List<KotOrder>? list = (json['kot_orders'] as List?)
            ?.map((v) => KotOrder.fromJson(v))
            .toList();
        if (list == null || list.isEmpty) {
          final rawItems = json['line_items'] ?? json['items'] ?? json['initial_kot_items'];
          if (rawItems is List && rawItems.isNotEmpty) {
            final lineItems = rawItems.map((itemJson) {
              if (itemJson is Map<String, dynamic>) {
                return LineItem.fromJson(itemJson);
              } else if (itemJson is Map) {
                return LineItem.fromJson(Map<String, dynamic>.from(itemJson));
              }
              return null;
            }).whereType<LineItem>().toList();

            if (lineItems.isNotEmpty) {
              final parentOrderId = json['order_id'] is int 
                  ? json['order_id'] 
                  : int.tryParse(json['order_id']?.toString() ?? json['id']?.toString() ?? '');

              list = [
                KotOrder(
                  kotOrderId: parentOrderId,
                  status: json['status']?.toString() ?? 'processing',
                  total: effectiveAmount,
                  createdAt: json['date']?.toString() ?? json['created_at']?.toString(),
                  isParent: false,
                  lineItems: lineItems,
                )
              ];
            }
          }
        }
        return list;
      }(),
      serviceChargeValue:
      num.tryParse(json['service_charge_value']?.toString() ?? "0") ?? 0,

      serviceChargePercentage:
      num.tryParse(json['service_charge_percentage']?.toString() ?? "0") ?? 0,
      tipAmount:
      num.tryParse(json['tip_amt']?.toString() ?? "0") ?? 0,
      couponDetails: (json['coupon_details'] as List?)
          ?.map((e) => CouponDetail.fromJson(e))
          .toList(),
    );
  }

// 👇 Add here
  num get displayTotal {
    if (netPayable != null && netPayable! > 0) return netPayable!;
    if (total != null && total! > 0) return total!;
    if (netTotal != null && netTotal! > 0) return netTotal!;
    if (amount != null && amount! > 0) return amount!;
    if (grossTotal != null && grossTotal! > 0) return grossTotal!;
    if (subTotal != null && subTotal! > 0) return subTotal!;
    return 0;
  }

  num get totalCouponDiscount {
    if (couponDetails == null || couponDetails!.isEmpty) {
      return 0;
    }

    return couponDetails!
        .fold<num>(0, (sum, item) => sum + (item.value ?? 0));
  }

}

// ================== KOT MODEL =====================

class KotOrder {
  int? kotOrderId;
  String? status;
  num? total;
  String? createdAt;
  bool? isParent;
  List<LineItem>? lineItems;
  List<Map<String, dynamic>>? metaData;

  KotOrder({
    this.kotOrderId,
    this.status,
    this.total,
    this.createdAt,
    this.isParent,
    this.lineItems,
    this.metaData,
  });

  factory KotOrder.fromJson(Map<String, dynamic> json) {
    return KotOrder(
      kotOrderId: json['id'] ?? json['kot_order_id'],
      status: json['status'],
      total: num.tryParse(json['total']?.toString() ?? "0") ?? 0,
      createdAt: json['created_at'],
      isParent: json['is_parent'],

      lineItems: (json['line_items'] as List?)
          ?.map((v) => LineItem.fromJson(v))
          .toList(),
      metaData: (json['meta_data'] as List?)
          ?.map((e) => Map<String, dynamic>.from(e))
          .toList(),
    );
  }
}

// ================== LINE ITEM MODEL =====================

class LineItem {
  int? lineItemId;
  int? itemId;
  String? name;
  num? quantity;
  num? maxQty;
  num? amount;
  num? total;
  num? modifierAmount;
  num? itemPrice;
  List<String>? modifiers;
  double? originalAmount;
  double? unitPrice;
  num? totalWoTax;

  LineItem({
    this.lineItemId,
    this.itemId,
    this.name,
    this.quantity,
    this.maxQty,
    this.amount,
    this.total,
    this.modifierAmount,
    this.modifiers,
    this.itemPrice,
    this.originalAmount,
    this.unitPrice,
    this.totalWoTax,
  });

  factory LineItem.fromJson(Map<String, dynamic> json) {
    List<String> parsedModifiers = [];

    // Case 1: direct array
    if (json['modifiers'] != null && (json['modifiers'] as List).isNotEmpty) {
      parsedModifiers = (json['modifiers'] as List)
          .map((e) => e is Map ? e['name'].toString() : e.toString())
          .toList();
    }
    // Case 2: in meta_data
    else if (json['meta_data'] != null && json['meta_data'] is List) {
      for (var meta in json['meta_data']) {
        if (meta['key'] == 'modifiers' && meta['value'] != null) {
          try {
            final decoded = jsonDecode(meta['value']);
            if (decoded is List) {
              parsedModifiers.addAll(decoded
                  .map<String>((e) => e is Map ? e['name'].toString() : e.toString())
                  .toList());
            }
          } catch (e) {
            print("⚠️ Failed to parse modifiers from meta_data: $e");
          }
        }
      }
    }

    final qty = num.tryParse(json['quantity']?.toString() ?? json['qty']?.toString() ?? "0") ?? 0;
    final itemTotal = num.tryParse(json['total']?.toString() ?? json['amount']?.toString() ?? json['price']?.toString() ?? "0") ?? 0;
    final unitPrice = num.tryParse(json['item_price']?.toString() ?? json['price']?.toString() ?? "0") ?? 0;

    return LineItem(
      lineItemId: json['line_item_id'] ?? json['id'],
      itemId: json['product_id'] ?? json['item_id'] ?? json['id'],
      name: json['name'] ?? json['product_name'] ?? 'Item',
      quantity: qty,
      amount: itemTotal,
      total: itemTotal,
      modifierAmount: num.tryParse(json['modifier_amount']?.toString() ?? "0") ?? 0,
      itemPrice: unitPrice > 0 ? unitPrice : (qty > 0 ? itemTotal / qty : itemTotal),
      modifiers: parsedModifiers,
      totalWoTax: num.tryParse(json['total_wo_tax']?.toString() ?? itemTotal.toString()) ?? itemTotal,
    );
  }

}

// ================== VIEW MAPPING =====================

extension OrderModelMapping on OrderlistModel {
  Map<String, dynamic> toMapForView() {
    return {
      "id": orderId,
      "timestamp": date,
      "price": displayTotal,
      "paymentType": paymentType,
      "orderType": orderType ?? "Online Order",
      "customerName": customerName,
      "customerContact": customerPhone,
      "status": status,
      "order_prev_total": orderPrevTotal ?? 0,
      "updatedRemarks": updated_remarks,
      "kots": kotOrders?.map((k) => k.toMapForView()).toList() ?? [],
    };
  }
}

extension KotOrderMapping on KotOrder {
  Map<String, dynamic> toMapForView() {
    final parts = (createdAt ?? "").split(" ");
    return {
      "kotNo": kotOrderId ?? 1,
      "date": parts.isNotEmpty ? parts[0] : "-",
      "time": parts.length > 1 ? parts[1] : "-",
      "items": lineItems?.map((l) => l.toMapForView()).toList() ?? [],
    };
  }
}

extension LineItemMapping on LineItem {
  Map<String, dynamic> toMapForView() {
    final effectiveItemAmount = (amount != null && amount! > 0)
        ? amount!
        : ((total != null && total! > 0)
            ? total!
            : ((itemPrice != null && quantity != null && itemPrice! > 0 && quantity! > 0)
                ? itemPrice! * quantity!
                : 0));

    return {
      "name": name ?? 'Item',
      "qty": quantity ?? 1,
      "amount": effectiveItemAmount,
      "modifiers": modifiers ?? [],
      "item_price": (itemPrice != null && itemPrice! > 0) ? itemPrice! : (quantity != null && quantity! > 0 ? effectiveItemAmount / quantity! : effectiveItemAmount),
      "total_wo_tax": (totalWoTax != null && totalWoTax! > 0) ? totalWoTax! : effectiveItemAmount,
    };
  }
}

// ================== UPDATE API MAPPING =====================

extension OrderUpdateMapping on OrderlistModel {
  Map<String, dynamic> toMapForUpdate() {
    return {
      "order_id": orderId,
      "gross_total": grossTotal,
      "sub_total": subTotal,
      "total_tax": totalTax,
      "net_total": netTotal,
      "round_off": roundOff ?? 0,
      "net_payable": netPayable,

      "kot_orders":
      kotOrders?.map((k) => k.toMapForUpdate()).toList() ?? [],
    };
  }
}

extension KotOrderUpdateMapping on KotOrder {
  Map<String, dynamic> toMapForUpdate() {
    return {
      "kot_order_id": kotOrderId,
      "status": status,
      "total": total,

      "line_items":
      lineItems?.map((l) => l.toMapForUpdate()).toList() ?? [],
    };
  }
}

extension LineItemUpdateMapping on LineItem {
  Map<String, dynamic> toMapForUpdate() {
    return {
      "line_item_id": lineItemId,
      "product_id": itemId,
      "quantity": quantity,
      "amount": amount,
      "total": total,
      "modifier_amount": modifierAmount ?? 0,
      "item_price": itemPrice ?? 0,
      "modifier_amount": modifierAmount ?? 0,
      // // 🔥 MODIFIER SAFE FORMAT
      // "modifiers": modifiers
      //     ?.map((m) => {
      //   "name": m,
      //   "amount": 0,
      // })
      //     .toList() ??
      //     [],
    };
  }
}
class CouponDetail {
  final String? code;
  final num? value;

  CouponDetail({
    this.code,
    this.value,
  });

  factory CouponDetail.fromJson(Map<String, dynamic> json) {
    return CouponDetail(
      code: json["code"],
      value: num.tryParse(json["value"].toString()) ?? 0,
    );
  }
}