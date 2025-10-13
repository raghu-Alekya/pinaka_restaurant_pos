import '../sidebar/category_model_.dart';
import 'KOT_model.dart';
import 'order_items.dart';

class OrderModel {
  final int orderId;
  final int tableId;
  final String tableName;
  final int zoneId;
  final String zoneName;
  final String status;

  final int guestCount; // ✅ Added guestCount
  final List<OrderItems> items;
  final List<KotModel> kotOrders;

  OrderModel({
    required this.orderId,
    required this.tableId,
    required this.tableName,
    required this.zoneId,
    required this.zoneName,
    required this.status,
    this.guestCount = 0, // default 0
    this.items = const [],
    this.kotOrders = const [],
  });

  /// Convenience getter
  int get id => orderId;

  /// Factory: parse JSON safely
  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;

    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    // 🔹 Parse KOTs
    List<KotModel> kotOrders = [];
    List<OrderItems> items = [];
    if (data['kot_orders'] != null) {
      kotOrders = (data['kot_orders'] as List<dynamic>)
          .map((k) => KotModel.fromJson(k))
          .toList();

      // Extract all line items from all KOTs
      for (var kot in kotOrders) {
        for (var lineItem in kot.items) {
          items.add(OrderItems(
            productId: lineItem.productId,
            name: lineItem.itemName,
            quantity: lineItem.quantity,
            price: lineItem.price,
            variantId: null,
            section: lineItem.section ??
                Category(
                  id: '0',
                  name: 'Default',
                  imagepath: '',
                  subCategories: [],
                ),
            modifiers: lineItem.modifiers,
            addOns: lineItem.addOns,
          ));
        }
      }
    }

    return OrderModel(
      orderId: parseInt(data['order_id']),
      tableId: parseInt(data['table_id']),
      tableName: data['table_name']?.toString() ?? '',
      zoneId: parseInt(data['zone_id']),
      zoneName: data['zone_name']?.toString() ?? '',
      status: data['status']?.toString() ?? '',
      guestCount: parseInt(data['guest_count']), // ✅ Load guest count
      items: items,
      kotOrders: kotOrders,
    );
  }

  /// Convert back to JSON
  Map<String, dynamic> toJson() {
    return {
      "order_id": orderId,
      "table_id": tableId,
      "table_name": tableName,
      "zone_id": zoneId,
      "zone_name": zoneName,
      "status": status,
      "guest_count": guestCount, // ✅ Include guest count
      "items": items.map((e) => e.toJson()).toList(),
      "kot_orders": kotOrders.map((e) => e.toJson()).toList(),
    };
  }

  /// Copy with optional updates
  OrderModel copyWith({
    int? orderId,
    int? tableId,
    String? tableName,
    int? zoneId,
    String? zoneName,
    String? status,
    int? guestCount, // ✅ Add guestCount
    List<OrderItems>? items,
    List<KotModel>? kotOrders,
  }) {
    return OrderModel(
      orderId: orderId ?? this.orderId,
      tableId: tableId ?? this.tableId,
      tableName: tableName ?? this.tableName,
      zoneId: zoneId ?? this.zoneId,
      zoneName: zoneName ?? this.zoneName,
      status: status ?? this.status,
      guestCount: guestCount ?? this.guestCount, // ✅ preserve guestCount
      items: items ?? this.items,
      kotOrders: kotOrders ?? this.kotOrders,
    );
  }
}
