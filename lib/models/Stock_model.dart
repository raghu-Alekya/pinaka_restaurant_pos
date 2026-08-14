class StockProduct {
  final int id;
  final String name;

  final int? stockQuantity;
  final String stockStatus;

  final int? categoryId;
  final String? categoryName;

  // VEG / NON-VEG
  final bool isVeg;

  StockProduct({
    required this.id,
    required this.name,
    this.stockQuantity,
    required this.stockStatus,
    this.categoryId,
    this.categoryName,
    required this.isVeg,
  });

  factory StockProduct.fromJson(
      Map<String, dynamic> json,
      ) {
    // ======================================================
    // CATEGORY
    // ======================================================

    String? categoryName;

    final category = json['category'];

    if (category is List &&
        category.isNotEmpty) {
      categoryName =
          category.first.toString().trim();
    } else if (category is String &&
        category.trim().isNotEmpty) {
      categoryName = category.trim();
    }

    // ======================================================
    // STOCK QUANTITY
    // ======================================================

    int? stockQuantity;

    final rawQuantity =
    json['stock_quantity'];

    if (rawQuantity != null) {
      stockQuantity = int.tryParse(
        rawQuantity.toString(),
      );
    }

    // ======================================================
    // STOCK STATUS
    // ======================================================

    final stockStatus =
        json['stock_status']
            ?.toString()
            .trim()
            .toLowerCase() ??
            '';

    // ======================================================
    // VEG / NON-VEG
    // ======================================================

    final bool isVeg =
        json['is_veg'] == true ||
            json['is_veg']
                ?.toString()
                .toLowerCase() ==
                'true';

    return StockProduct(
      id:
      (json['id'] as num?)?.toInt() ?? 0,

      name:
      json['name']?.toString() ?? '',

      stockQuantity:
      stockQuantity,

      stockStatus:
      stockStatus,

      categoryId:
      (json['category_id'] as num?)?.toInt(),

      categoryName:
      categoryName,

      isVeg:
      isVeg,
    );
  }

  // ======================================================
  // ENABLE / DISABLE
  // ======================================================

  bool get isEnabled {
    if (stockStatus == 'outofstock') {
      return false;
    }

    if (stockQuantity != null &&
        stockQuantity! <= 0) {
      return false;
    }

    return stockStatus == 'instock';
  }
}