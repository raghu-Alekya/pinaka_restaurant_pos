class BillSummaryEntity {
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
  final List<LineItemEntity> lineItems;
  final List<FeeDetailEntity> feeDetails;
  final List<dynamic> couponDetails;
  final int tableId;
  final int zoneId;

  BillSummaryEntity({
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
}

class LineItemEntity {
  final int productId;
  final int variationId;
  final String name;
  final int qty;
  final double total;
  final double price;
  final double? originalPrice; // 👈 nullable
  final double tax;
  final String taxClass;
  final List<dynamic> modifiers;
  final double modifierAmount;
  final List<dynamic> comboItems;

  LineItemEntity({
    required this.productId,
    required this.variationId,
    required this.name,
    required this.qty,
    required this.total,
    required this.price,
    this.originalPrice, // 👈 optional
    required this.tax,
    required this.taxClass,
    required this.modifiers,
    required this.modifierAmount,
    required this.comboItems,
  });
}

class FeeDetailEntity {
  final int id;
  final String name;
  final double total;
  final double tax;

  FeeDetailEntity({
    required this.id,
    required this.name,
    required this.total,
    required this.tax,
  });
}