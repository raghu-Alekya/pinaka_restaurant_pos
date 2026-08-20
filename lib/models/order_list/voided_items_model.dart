class VoidedItem {
  String? itemId;
  int? newQty;
  String? remarks;
  DateTime? voidedAt;

  // ADD
  num? orderPrevTotal;
  num? netPayable;
  num? diffInTotal;

  VoidedItem({
    this.itemId,
    this.newQty,
    this.remarks,
    this.voidedAt,
    this.orderPrevTotal,
    this.netPayable,
    this.diffInTotal,
  });

  factory VoidedItem.fromJson(Map<String, dynamic> json) {
    return VoidedItem(
      itemId: json['item_id']?.toString(),
      newQty: json['new_qty'],
      remarks: json['remarks'],
      voidedAt: json['voided_at'] != null
          ? DateTime.tryParse(json['voided_at'].toString())
          : null,

      orderPrevTotal: num.tryParse(
        json['order_prev_total']?.toString() ?? '',
      ),

      netPayable: num.tryParse(
        json['net_payable']?.toString() ?? '',
      ),

      diffInTotal: num.tryParse(
        json['diff_in_total']?.toString() ?? '',
      ),
    );
  }
}
