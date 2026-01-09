class TaxModel {
  final int id;
  final String rate;
  final String name;
  final String taxClass;
  final bool compound;
  final bool shipping;

  TaxModel({
    required this.id,
    required this.rate,
    required this.name,
    required this.taxClass,
    required this.compound,
    required this.shipping,
  });

  factory TaxModel.fromJson(Map<String, dynamic> json) {
    String rawClass = (json['class'] ?? '').toString();

    // 🔧 Normalize backend mistakes here
    final normalizedClass = rawClass
        .toLowerCase()
        .trim()
        .replaceAll('bewerages', 'beverages');

    return TaxModel(
      id: json['id'],
      rate: json['rate'],
      name: json['name'],
      taxClass: normalizedClass,
      compound: json['compound'],
      shipping: json['shipping'],
    );
  }

}
