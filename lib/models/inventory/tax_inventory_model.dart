class TaxInventoryModel {
  final int id;
  final String name;

  TaxInventoryModel({
    required this.id,
    required this.name,
  });

  factory TaxInventoryModel.fromJson(Map<String, dynamic> json) {
    return TaxInventoryModel(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}