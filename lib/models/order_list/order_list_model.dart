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

  List<KotOrder>? kotOrders;
  num? serviceChargeValue;
  num? serviceChargePercentage;
  num? tipAmount;
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
    this.kotOrders,
    this.serviceChargeValue,
    this.serviceChargePercentage,
    this.tipAmount,
  });

  factory OrderlistModel.fromJson(Map<String, dynamic> json) {
    return OrderlistModel(
      completedByUserId: json['completed_by_user_id']?.toString(),
      orderId: json['order_id'],
      orderType: json['order_type'],
      date: json['date'],
      customerName: json['customer_name'],
      customerPhone: json['customer_phone'],
      paymentType: json['payment_type'],
      kotOrderId: json['kot_order_id'],

      grossTotal: num.tryParse(json['gross_total']?.toString() ?? "0") ?? 0,
      subTotal: num.tryParse(json['sub_total']?.toString() ?? "0") ?? 0,
      totalTax: num.tryParse(json['total_tax']?.toString() ?? "0") ?? 0,
      netTotal: num.tryParse(json['net_total']?.toString() ?? "0") ?? 0,
      merchantDiscount: num.tryParse(json['merchant_discount']?.toString() ?? "0") ?? 0,
      netPayable: num.tryParse(json['net_payable']?.toString() ?? "0") ?? 0,
      roundOff: num.tryParse(json['round_off']?.toString() ?? "0") ?? 0,

      amount: num.tryParse(json['amount']?.toString() ?? "0") ?? 0,
      discount: num.tryParse(json['discount']?.toString() ?? "0") ?? 0,
      total: num.tryParse(json['total']?.toString() ?? "0") ?? 0,

      orderPrevTotal: num.tryParse(json['order_prev_total']?.toString() ?? "0") ?? 0,

      isUpdated: json['is_updated']?.toString(),
      updated_remarks: json['updated_remarks']?.toString(),

      restaurantId: json['restaurant_id'],
      zoneId: json['zone_id'],
      tableId: json['table_id'],
      tableStatus: json['table_status'],
      zoneName: json['zone_name'],
      tableName: json['table_name'],

      status: json['status'],
      isParent: json['is_parent'],

      kotOrders: (json['kot_orders'] as List?)
          ?.map((v) => KotOrder.fromJson(v))
          .toList(),
      serviceChargeValue:
      num.tryParse(json['service_charge_value']?.toString() ?? "0") ?? 0,

      serviceChargePercentage:
      num.tryParse(json['service_charge_percentage']?.toString() ?? "0") ?? 0,
      tipAmount:
      num.tryParse(json['tip_amt']?.toString() ?? "0") ?? 0,
    );
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

    return LineItem(
      lineItemId: json['line_item_id'],
      itemId: json['product_id'] ?? json['item_id'],
      name: json['name'],
      quantity: num.tryParse(json['quantity']?.toString() ?? "0") ?? 0,
      amount: num.tryParse(json['amount']?.toString() ?? "0") ?? 0,
      total: num.tryParse(json['total']?.toString() ?? "0") ?? 0,
      modifierAmount: num.tryParse(json['modifier_amount']?.toString() ?? "0") ?? 0,
      itemPrice: num.tryParse(json['item_price']?.toString() ?? "0") ?? 0,
      modifiers: parsedModifiers,
      totalWoTax: num.tryParse(json['total_wo_tax']?.toString() ?? "0") ?? 0,
    );
  }

}

// ================== VIEW MAPPING =====================

extension OrderModelMapping on OrderlistModel {
  Map<String, dynamic> toMapForView() {
    return {
      "id": orderId,
      "timestamp": date,
      "price": amount,
      "paymentType": paymentType,
      "orderType": orderType ?? "Shop Order",
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
      "kotNo": kotOrderId,
      "date": parts.isNotEmpty ? parts[0] : "-",
      "time": parts.length > 1 ? parts[1] : "-",
      "items": lineItems?.map((l) => l.toMapForView()).toList() ?? [],
    };
  }
}

extension LineItemMapping on LineItem {
  Map<String, dynamic> toMapForView() {
    return {
      "name": name,
      "qty": quantity,
      "amount": amount,
      "modifiers": modifiers ?? [],
      "item_price": itemPrice,
      "total_wo_tax": totalWoTax,
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