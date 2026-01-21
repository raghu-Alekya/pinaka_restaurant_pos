class PaymentSummary {
  final int restaurantId;
  final int orderId;
  final double grossTotal;
  final double tax;
  final double fees;
  final double coupons;
  final double discount;
  final double netTotal;
  final List<LineItem> lineItems;
  final int tableId;
  final int zoneId;

  PaymentSummary({
    required this.restaurantId,
    required this.orderId,
    required this.grossTotal,
    required this.tax,
    required this.fees,
    required this.discount,
    required this.coupons,
    required this.netTotal,
    required this.lineItems,
    required this.tableId,
    required this.zoneId,
  });

  factory PaymentSummary.fromJson(Map<String, dynamic> json) {
    return PaymentSummary(
      restaurantId: (json['restaurant_id'] ?? 0).toInt(),
      orderId: (json['order_id'] ?? 0).toInt(),

      grossTotal: (json['gross_total'] ?? 0).toDouble(),
      tax: (json['tax'] ?? 0).toDouble(),

      // 🔥 backend uses "Fees" (capital F)
      fees: (json['Fees'] ?? 0).toDouble(),

      // ✅ FIXED: read merchant_discount
      discount: double.tryParse(
        (json['merchant_discount'] ?? json['discount'] ?? 0).toString(),
      ) ?? 0.0,

      coupons: (json['coupons'] ?? 0).toDouble(),
      netTotal: (json['net_total'] ?? 0).toDouble(),

      lineItems: (json['line_items'] as List? ?? [])
          .map((e) => LineItem.fromJson(e))
          .toList(),

      tableId: (json['table_id'] ?? 0).toInt(),
      zoneId: (json['zone_id'] ?? 0).toInt(),
    );
  }
}



class LineItem {
  final int productId;
  final int variationId;
  final String name;
  final int qty;
  final double total;
  final double tax;
  final String taxClass;

  final List<String> modifiers;
  final double modifierAmount; // ✅ ADD THIS

  LineItem({
    required this.productId,
    required this.variationId,
    required this.name,
    required this.qty,
    required this.total,
    required this.tax,
    required this.taxClass,
    required this.modifiers,
    required this.modifierAmount, // ✅ ADD THIS
  });

  factory LineItem.fromJson(Map<String, dynamic> json) {
    return LineItem(
      productId: (json['product_id'] ?? 0).toInt(),
      variationId: (json['variation_id'] ?? 0).toInt(),
      name: json['name'] ?? '',
      qty: (json['qty'] ?? 0).toInt(),
      total: (json['total'] ?? 0).toDouble(),
      tax: (json['tax'] ?? 0).toDouble(),
      taxClass: (json['tax_class'] ?? 'food').toString().toLowerCase(),

      modifiers: List<String>.from(json['modifiers'] ?? []),

      // ✅ parse modifier_amount
      modifierAmount: (json['modifier_amount'] ?? 0).toDouble(),
    );
  }
}


