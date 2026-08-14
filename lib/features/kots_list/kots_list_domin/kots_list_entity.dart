class KotOrder {
  final int id;
  final String time;
  final String status;
  final double total;
  final String kotNumber;
  final String? orderBy;
  final List<LineItem> lineItems;

  KotOrder({
    required this.id,
    required this.time,
    required this.status,
    required this.total,
    required this.kotNumber,
    this.orderBy,
    this.lineItems = const [],
  });
}

class LineItem {
  final int id;
  final int productId;
  final String itemName;
  final int quantity;
  final double price;
  final double amount;
  final List<dynamic> modifiers;
  final List<dynamic> combos;
  final String isCancelled;

  LineItem({
    required this.id,
    required this.productId,
    required this.itemName,
    required this.quantity,
    required this.price,
    required this.amount,
    required this.modifiers,
    required this.combos,
    this.isCancelled = 'no',
  });
}