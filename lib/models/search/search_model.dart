class Search_ProductModel {
  final int id;
  final String name;
  final String sku;
  final String type;
  final double price;
  final bool inStock;   // ✅ Add this
  final int? parentId;
  final String? parentName;

  Search_ProductModel({
    required this.id,
    required this.name,
    required this.sku,
    required this.type,
    required this.price,
    required this.inStock,
    this.parentId,
    this.parentName,
  });

  factory Search_ProductModel.fromJson(Map<String, dynamic> json) {
    return Search_ProductModel(
      id: json['id'],
      name: json['name'] ?? '',
      sku: json['sku'] ?? '',
      type: json['type'] ?? 'simple',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
      inStock: (json['in_stock'] ?? 'Yes')
          .toString()
          .toLowerCase() == 'yes',
      parentId: json['parent_id'],
      parentName: json['parent_name'],
    );
  }
}