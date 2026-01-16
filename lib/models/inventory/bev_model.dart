class Products {
  final int id;
  final String itemName;
  final String? sku;
  final int threshold;
  final String remaining;
  final int soldTotal;
  final String statusLabel;
  final String statusColor;
  final String image;

  Products({
    required this.id,
    required this.itemName,
    required this.sku,
    required this.threshold,
    required this.remaining,
    required this.soldTotal,
    required this.statusLabel,
    required this.statusColor,
    required this.image,
  });

  factory Products.fromJson(Map<String, dynamic> json) {
    return Products(
      id: json['id'] ?? 0,
      itemName: json['item_name'] ?? '',
      sku: json['sku']?.toString(),
      threshold: json['threshold'] ?? 0,
      remaining: json['remaining'] ?? '',
      soldTotal: json['sold_total'] ?? 0,
      statusLabel: json['status_label'] ?? '',
      statusColor: json['status_color'] ?? '',
      image: json['image'] is String ? json['image'] : '', // ✅ custom items fix
    );
  }
}

class Model {
  final List<Products> products;

  Model({required this.products});

  factory Model.fromJson(Map<String, dynamic> json) {
    return Model(
      products: (json['products'] as List<dynamic>? ?? [])
          .map((e) => Products.fromJson(e))
          .toList(),
    );
  }
}