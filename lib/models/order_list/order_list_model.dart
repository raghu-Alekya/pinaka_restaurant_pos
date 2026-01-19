class OrderlistModel {
  int? orderId;
  String? orderType;
  String? date;
  String? customerName;
  String? customerPhone;
  String? paymentType;
  num? amount;          // ✅ changed
  num? discount;        // ✅ changed
  num? total;           // ✅ changed
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
    this.amount,
    this.discount,
    this.total,
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
      amount: num.tryParse(json['amount'].toString()) ?? 0,
      discount: num.tryParse(json['discount'].toString()) ?? 0,
      total: num.tryParse(json['total'].toString()) ?? 0,
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
  int? lineItemId;
  int? itemId;
  String? name;
  num? quantity;        // ✅ changed
  num? amount;          // ✅ changed
  num? total;           // ✅ changed

  LineItem({
    this.lineItemId,
    this.itemId,
    this.name,
    this.quantity,
    this.amount,
    this.total,
  });

  factory LineItem.fromJson(Map<String, dynamic> json) {
    return LineItem(
      lineItemId: json['line_item_id'],
      itemId: json['item_id'],
      name: json['name'],
      quantity: num.tryParse(json['quantity'].toString()) ?? 0,
      amount: num.tryParse(json['amount'].toString()) ?? 0,
      total: num.tryParse(json['total'].toString()) ?? 0,
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
    };
  }
}