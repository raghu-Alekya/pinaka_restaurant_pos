class ProductStatusRequest {
  final int productId;
  final String status;
  final String pin;

  ProductStatusRequest({
    required this.productId,
    required this.status,
    required this.pin,
  });

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'status': status,
      'pin': pin,
    };
  }
}