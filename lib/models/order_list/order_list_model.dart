class OrderlistModel {
  int? orderId;
  String? orderType;
  String? date;
  String? customerName;
  String? customerPhone;
  String? paymentType;
  int? kotOrderId;
  // Payment fields
  num? grossTotal;
  num? subTotal;
  num? totalTax;
  num? netTotal;
  num? merchantDiscount;
  num? netPayable;
  num? roundOff; // ✅ new field
  num? amount;
  num? discount;
  num? total;
  num? orderPrevTotal;
  String? isUpdated;

  int? restaurantId;
  int? zoneId;
  int? tableId;
  String? tableStatus;
  String? zoneName;
  String? tableName;

  String? status;
  bool? isParent;

  List<KotOrder>? kotOrders;

  OrderlistModel({
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
    this.roundOff, // ✅ include in constructor
    this.amount,
    this.discount,
    this.total,
    this.orderPrevTotal,
    this.isUpdated,
    this.restaurantId,
    this.zoneId,
    this.tableId,
    this.tableStatus,
    this.zoneName,
    this.tableName,
    this.status,
    this.isParent,
    this.kotOrders,
  });

  factory OrderlistModel.fromJson(Map<String, dynamic> json) {
    return OrderlistModel(
      orderId: json['order_id'],
      orderType: json['order_type'],
      date: json['date'],
      customerName: json['customer_name'],
      customerPhone: json['customer_phone'],
      paymentType: json['payment_type'],
      kotOrderId: json['kot_order_id'],
      grossTotal: num.tryParse(json['gross_total'].toString()) ?? 0,
      subTotal: num.tryParse(json['sub_total'].toString()) ?? 0,
      totalTax: num.tryParse(json['total_tax'].toString()) ?? 0,
      netTotal: num.tryParse(json['net_total'].toString()) ?? 0,
      merchantDiscount: num.tryParse(json['merchant_discount'].toString()) ?? 0,
      netPayable: num.tryParse(json['net_payable'].toString()) ?? 0,
      roundOff: num.tryParse(json['round_off']?.toString() ?? "0") ?? 0,
      amount: num.tryParse((json['amount'] ?? 0).toString()) ?? 0,
      discount: num.tryParse((json['discount'] ?? 0).toString()) ?? 0,
      total: num.tryParse((json['total'] ?? 0).toString()) ?? 0,
      orderPrevTotal: json['order_prev_total'] != null
          ? (json['order_prev_total'] is num
          ? json['order_prev_total'] as num
          : num.tryParse(json['order_prev_total'].toString()) ?? 0)
          : 0,

      isUpdated: json['is_updated']?.toString(),
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
    );

  }
}



class KotOrder {
  int? kotOrderId;
  String? status;
  num? total;           // ✅ changed
  String? createdAt;
  bool? isParent;
  List<LineItem>? lineItems;

  KotOrder({
    this.kotOrderId,
    this.status,
    this.total,
    this.createdAt,
    this.isParent,
    this.lineItems,
  });

  factory KotOrder.fromJson(Map<String, dynamic> json) {
    return KotOrder(
      kotOrderId: json['kot_order_id'],
      status: json['status'],
      total: num.tryParse(json['total'].toString()) ?? 0,
      createdAt: json['created_at'],
      isParent: json['is_parent'],
      lineItems: (json['line_items'] as List?)
          ?.map((v) => LineItem.fromJson(v))
          .toList(),
    );
  }
}

class LineItem {
  int? lineItemId;   // <-- WooCommerce ORDER ITEM ID
  int? itemId;       // product id
  String? name;
  num? quantity;
  num? amount;
  num? total;
  num? modifierAmount;
  List<String>? modifiers;

  LineItem({
    this.lineItemId,
    this.itemId,
    this.name,
    this.quantity,
    this.amount,
    this.total,
    this.modifierAmount,
    this.modifiers,
  });

  factory LineItem.fromJson(Map<String, dynamic> json) {
    return LineItem(
      lineItemId: json['line_item_id'],    // ✅ Must come from backend
      itemId: json['product_id'] ?? json['item_id'],            // ✅ fix key
      name: json['name'],
      quantity: num.tryParse(json['quantity'].toString()) ?? 0,
      amount: num.tryParse(json['amount'].toString()) ?? 0,
      total: num.tryParse(json['total'].toString()) ?? 0,
      modifierAmount: num.tryParse(json['modifier_amount']?.toString() ?? "0") ?? 0,
      modifiers: (json['modifiers'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

}


// ===== Add extensions here =====

extension OrderModelMapping on OrderlistModel {
  Map<String, dynamic> toMapForView() {
    return {
      "id": orderId,
      "timestamp": date,
      "price": amount,
      "paymentType": paymentType,
      "orderType": orderType ?? "Shop Order",
      "additionalInfo": "",
      "customerName": customerName,
      "customerContact": customerPhone,
      "status": status,
      "order_prev_total": orderPrevTotal ?? 0,
      "kots": kotOrders?.map((k) => k.toMapForView()).toList() ?? [],
    };
  }
}

extension KotOrderMapping on KotOrder {
  Map<String, dynamic> toMapForView() {
    final parts = (createdAt ?? "").split(" ");
    final datePart = parts.isNotEmpty ? parts[0] : "-";
    final timePart = parts.length > 1 ? parts[1] : "-";

    return {
      "kotNo": kotOrderId,
      "date": datePart,
      "time": timePart,
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
    };
  }
}