class PaymentSummary {
  final int restaurantId;
  final int orderId;
  final double grossTotal;
  final double tax;
  final double fees;
  final double coupons;
  final double discount;
  final double tipAmount;
  final double netTotal;
  final List<LineItem> lineItems;
  final int tableId;
  final String tableName;
  final int zoneId;
  final bool modifiersTaxable;
  final bool isNoCharge;
  final List<CouponDetail> couponDetails;
  final double serviceChargePercentage;
  final double serviceChargeValue;
  final double roundOff;



  PaymentSummary({
    required this.restaurantId,
    required this.orderId,
    required this.grossTotal,
    required this.tax,
    required this.fees,
    required this.discount,
    required this.coupons,
    required this.tipAmount,
    required this.netTotal,
    required this.lineItems,
    required this.tableId,
    required this.tableName,
    required this.zoneId,
    required this.modifiersTaxable,
    required this.isNoCharge,
    required this.couponDetails,
    required this.serviceChargePercentage,
    required this.serviceChargeValue,
    required this.roundOff,
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
      tipAmount: double.tryParse(
        (json['tip'] ?? 0).toString(),
      ) ?? 0.0,

      coupons: (json['coupons'] ?? 0).toDouble(),
      netTotal: (json['net_total'] ?? 0).toDouble(),
      couponDetails: (json['coupon_details'] as List? ?? [])
          .map((e) => CouponDetail.fromJson(e))
          .toList(),

      lineItems: (json['line_items'] as List? ?? [])
          .map((e) => LineItem.fromJson(e))
          .toList(),

      tableId: (json['table_id'] ?? 0).toInt(),
      tableName: json['table_name']?.toString() ?? '',
      zoneId: (json['zone_id'] ?? 0).toInt(),
      // ✅ ADD THIS
      modifiersTaxable:
      (json['modifiers_taxable'] ?? 'no').toString().toLowerCase() == 'yes',
      // 👇 new: NC comes from backend, not UI
      // ✅ CORRECT mapping of NC flag
      isNoCharge:
      (json['is_nc'] ?? 'no')
          .toString()
          .toLowerCase() == 'yes',
      serviceChargePercentage:
      (json['service_charge_percentage'] ?? 0).toDouble(),

      serviceChargeValue:
      (json['service_charge_value'] ?? 0).toDouble(),
      roundOff: double.tryParse(
        (json['round_off'] ?? 0).toString(),
      ) ?? 0.0,
    );
  }
}



class LineItem {
  final int productId;
  final int variationId;
  final String name;
  final int qty;
  final double price;


  /// Backend totals (SOURCE OF TRUTH)
  final double total;
  final double tax;
  final String taxClass;

  /// Modifiers
  final List<String> modifiers;
  final double modifierAmount;

  /// 👇 Derived (NOT from API)
  late final double basePrice;

  LineItem({
    required this.productId,
    required this.variationId,
    required this.name,
    required this.qty,
    required this.total,
    required this.tax,
    required this.taxClass,
    required this.price,
    required this.modifiers,
    required this.modifierAmount,
  }) {
    // base price = total - tax - modifier amount
    basePrice = (total - tax - modifierAmount).clamp(0, double.infinity);
  }

  /// 🔢 Tax %
  double get taxPercent {
    if (basePrice == 0) return 0;
    return (tax / basePrice) * 100;
  }

  /// 💰 Taxable amount based on modifier rule
  double taxableAmount({required bool modifiersTaxable}) {
    return modifiersTaxable
        ? basePrice + modifierAmount
        : basePrice;
  }

  /// 🧮 Calculated tax (UI / validation ONLY)
  double calculatedTax({required bool modifiersTaxable}) {
    final taxable = taxableAmount(modifiersTaxable: modifiersTaxable);
    return (taxable * taxPercent) / 100;
  }

  factory LineItem.fromJson(Map<String, dynamic> json) {
    return LineItem(
      productId: (json['product_id'] ?? 0).toInt(),
      variationId: (json['variation_id'] ?? 0).toInt(),
      name: json['name'] ?? '',
      qty: (json['qty'] ?? 0).toInt(),
      total: (json['total'] ?? 0).toDouble(),
      price: double.tryParse(
        (json['price'] ?? 0).toString(),
      ) ?? 0.0,
      tax: (json['tax'] ?? 0).toDouble(),
      taxClass: (json['tax_class'] ?? 'food').toString().toLowerCase(),
      modifiers: List<String>.from(json['modifiers'] ?? []),
      modifierAmount: (json['modifier_amount'] ?? 0).toDouble(),
    );
  }
}
class CouponDetail {
  final String code;
  final double value;

  CouponDetail({
    required this.code,
    required this.value,
  });

  factory CouponDetail.fromJson(Map<String,dynamic> json) {
    return CouponDetail(
      code: json['code'] ?? '',
      value: (json['value'] ?? 0).toDouble(),
    );
  }
}
