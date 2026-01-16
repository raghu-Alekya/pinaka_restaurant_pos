class UpdateStockResponse {
  final bool success;
  final int productId;
  final String productType;
  final String flagType;
  final String reason;
  final int qtyChanged;
  final int oldStock;
  final int newStock;
  final String stockStatus;
  final String productName;

  UpdateStockResponse({
    required this.success,
    required this.productId,
    required this.productType,
    required this.flagType,
    required this.reason,
    required this.qtyChanged,
    required this.oldStock,
    required this.newStock,
    required this.stockStatus,
    required this.productName,
  });

  factory UpdateStockResponse.fromJson(Map<String, dynamic> json) {
    return UpdateStockResponse(
      success: json['success'] ?? false,
      productId: json['product_id'],
      productType: json['product_type'],
      flagType: json['flag_type'],
      reason: json['reason'],
      qtyChanged: json['qty_changed'],
      oldStock: json['old_stock'],
      newStock: json['new_stock'],
      stockStatus: json['stock_status'],
      productName: json['product_name'],
    );
  }
}
class AddUpdateItemResponse {
  final String status;
  final String message;
  final int itemId;
  final int itemPrice;
  final int itemQty;
  final String itemNote;
  final int categoryId; // <-- Added category_id

  AddUpdateItemResponse({
    required this.status,
    required this.message,
    required this.itemId,
    required this.itemPrice,
    required this.itemQty,
    required this.itemNote,
    required this.categoryId,
  });

  factory AddUpdateItemResponse.fromJson(Map<String, dynamic> json, {int categoryId = 0}) {
    // categoryId is optional, default to 0 if not provided
    return AddUpdateItemResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      itemId: json['item_id'] ?? 0,
      itemPrice: json['item_price'] ?? 0,
      itemQty: json['item_qty'] ?? 0,
      itemNote: json['item_note'] ?? '',
      categoryId: categoryId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'item_id': itemId,
      'item_price': itemPrice,
      'item_qty': itemQty,
      'item_note': itemNote,
      'category_id': categoryId,
    };
  }

  bool get isCreated => status.toLowerCase() == 'created';
}