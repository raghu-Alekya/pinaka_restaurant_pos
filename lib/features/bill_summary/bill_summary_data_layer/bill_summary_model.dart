import '../bill_summary_domain/bill_summary_entity.dart';

// --- Helper: safely convert any value to double ---
double _toDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

class BillSummaryResponse {
  final int restaurantId;
  final String tableName;
  final int orderId;
  final double grossTotal;
  final double serviceChargePercentage;
  final double serviceChargeValue;
  final double couponTotal;
  final String modifiersTaxable;
  final double tax;
  final double coupons;
  final String isNc;
  final double merchantDiscount;
  final double roundOff;
  final double netTotal;
  final double tip;
  final List<LineItemModel> lineItems;
  final List<FeeDetailModel> feeDetails;
  final List<dynamic> couponDetails;
  final int tableId;
  final int zoneId;

  BillSummaryResponse({
    required this.restaurantId,
    required this.tableName,
    required this.orderId,
    required this.grossTotal,
    required this.serviceChargePercentage,
    required this.serviceChargeValue,
    required this.couponTotal,
    required this.modifiersTaxable,
    required this.tax,
    required this.coupons,
    required this.isNc,
    required this.merchantDiscount,
    required this.roundOff,
    required this.netTotal,
    required this.tip,
    required this.lineItems,
    required this.feeDetails,
    required this.couponDetails,
    required this.tableId,
    required this.zoneId,
  });

  factory BillSummaryResponse.fromJson(Map<String, dynamic> json) {
    return BillSummaryResponse(
      restaurantId: json['restaurant_id'] ?? 0,
      tableName: json['table_name'] ?? '',
      orderId: json['order_id'] ?? 0,
      grossTotal: _toDouble(json['gross_total']),
      serviceChargePercentage: _toDouble(json['service_charge_percentage']),
      serviceChargeValue: _toDouble(json['service_charge_value']),
      couponTotal: _toDouble(json['coupon_total']),
      modifiersTaxable: json['modifiers_taxable'] ?? 'no',
      tax: _toDouble(json['tax']),
      coupons: _toDouble(json['coupons']),
      isNc: json['is_nc'] ?? 'no',
      merchantDiscount: _toDouble(json['merchant_discount']),
      roundOff: _toDouble(json['round_off']),
      netTotal: _toDouble(json['net_total']),
      tip: _toDouble(json['tip']),
      lineItems: (json['line_items'] as List?)
          ?.map((e) => LineItemModel.fromJson(e))
          .toList() ??
          [],
      feeDetails: (json['fee_details'] as List?)
          ?.map((e) => FeeDetailModel.fromJson(e))
          .toList() ??
          [],
      couponDetails: json['coupon_details'] ?? [],
      tableId: json['table_id'] ?? 0,
      zoneId: json['zone_id'] ?? 0,
    );
  }

  BillSummaryEntity toEntity() => BillSummaryEntity(
    restaurantId: restaurantId,
    tableName: tableName,
    orderId: orderId,
    grossTotal: grossTotal,
    serviceChargePercentage: serviceChargePercentage,
    serviceChargeValue: serviceChargeValue,
    couponTotal: couponTotal,
    modifiersTaxable: modifiersTaxable,
    tax: tax,
    coupons: coupons,
    isNc: isNc,
    merchantDiscount: merchantDiscount,
    roundOff: roundOff,
    netTotal: netTotal,
    tip: tip,
    lineItems: lineItems.map((e) => e.toEntity()).toList(),
    feeDetails: feeDetails.map((e) => e.toEntity()).toList(),
    couponDetails: couponDetails,
    tableId: tableId,
    zoneId: zoneId,
  );
}

class LineItemModel {
  final int productId;
  final int variationId;
  final String name;
  final int qty;
  final double total;
  final double price;
  final double originalPrice; // 👈 non-nullable with default
  final double tax;
  final String taxClass;
  final List<dynamic> modifiers;
  final double modifierAmount;
  final List<dynamic> comboItems;

  LineItemModel({
    required this.productId,
    required this.variationId,
    required this.name,
    required this.qty,
    required this.total,
    required this.price,
    required this.originalPrice,
    required this.tax,
    required this.taxClass,
    required this.modifiers,
    required this.modifierAmount,
    required this.comboItems,
  });

  factory LineItemModel.fromJson(Map<String, dynamic> json) {
    return LineItemModel(
      productId: json['product_id'] ?? 0,
      variationId: json['variation_id'] ?? 0,
      name: json['name'] ?? '',
      qty: json['qty'] ?? 0,
      total: _toDouble(json['total']),
      price: _toDouble(json['price']),
      originalPrice: _toDouble(json['original_price']), // 👈 uses helper
      tax: _toDouble(json['tax']),
      taxClass: json['tax_class'] ?? '',
      modifiers: json['modifiers'] ?? [],
      modifierAmount: _toDouble(json['modifier_amount']),
      comboItems: json['combo_items'] ?? [],
    );
  }

  LineItemEntity toEntity() => LineItemEntity(
    productId: productId,
    variationId: variationId,
    name: name,
    qty: qty,
    total: total,
    price: price,
    originalPrice: originalPrice,
    tax: tax,
    taxClass: taxClass,
    modifiers: modifiers,
    modifierAmount: modifierAmount,
    comboItems: comboItems,
  );
}

class FeeDetailModel {
  final int id;
  final String name;
  final double total;
  final double tax;

  FeeDetailModel({
    required this.id,
    required this.name,
    required this.total,
    required this.tax,
  });

  factory FeeDetailModel.fromJson(Map<String, dynamic> json) {
    return FeeDetailModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      total: _toDouble(json['total']),
      tax: _toDouble(json['tax']),
    );
  }

  FeeDetailEntity toEntity() => FeeDetailEntity(
    id: id,
    name: name,
    total: total,
    tax: tax,
  );
}