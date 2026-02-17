class TaxInventoryModel {
  final int id;
  final String name;
  final String taxClass; // 👈 REQUIRED for backend

  TaxInventoryModel({
    required this.id,
    required this.name,
    required this.taxClass,
  });

  factory TaxInventoryModel.fromJson(Map<String, dynamic> json) {
    return TaxInventoryModel(
      id: json['id'] as int,
      name: json['name'] as String,
      taxClass: json['class'] as String? ?? '', // WooCommerce tax class
    );
  }
}