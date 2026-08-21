class ProductStatusRequest {
  final List<ProductStatusItem> products;
  final String pin;

  ProductStatusRequest({
    required this.products,
    required this.pin,
  });

  Map<String, dynamic> toJson() {
    return {
      'products': products.map((product) => product.toJson()).toList(),
      'pin': pin,
    };
  }
}

class ProductStatusItem {
  final int productId;
  final String oldStatus;
  final String newStatus;

  ProductStatusItem({
    required this.productId,
    required this.oldStatus,
    required this.newStatus,
  });

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'old_status': oldStatus,
      'new_status': newStatus,
    };
  }
}