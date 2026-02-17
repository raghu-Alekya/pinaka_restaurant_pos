class InventoryAlert {
  final int id;
  final String name;
  final String? quantity;
  final String status;
  final String type;

  InventoryAlert({
    required this.id,
    required this.name,
    required this.quantity,
    required this.status,
    required this.type,
  });

  factory InventoryAlert.fromJson(Map<String, dynamic> json) {
    return InventoryAlert(
      id: json['id'],
      name: json['name'] ?? '',
      quantity: json['quantity']?.toString(),
      status: json['status'] ?? '',
      type: json['type'] ?? '',
    );
  }
}