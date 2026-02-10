class Search_ProductModel {
  final int id;
  final String name;
  final String sku;
  final double price;
  final int stockQty;
  final String stockStatus;
  final String taxClass;
  final List<String> categories;
  final String? image;

  Search_ProductModel({
    required this.id,
    required this.name,
    required this.sku,
    required this.price,
    required this.stockQty,
    required this.stockStatus,
    required this.taxClass,
    required this.categories,
    this.image,
  });

  factory Search_ProductModel.fromJson(Map<String, dynamic> json) {
    return Search_ProductModel(
      id: json['id'],
      name: json['name'],
      sku: json['sku'],
      price: double.tryParse(json['price'] ?? '0') ?? 0,
      stockQty: json['stock_quantity'] ?? 0,
      stockStatus: json['stock_status'],
      taxClass: json['tax_class'] ?? '',
      categories: (json['categories'] as List)
          .map((e) => e['name'].toString())
          .toList(),
      image: (json['images'] != null && json['images'].isNotEmpty)
          ? json['images'][0]['src']
          : null,
    );
  }
}
