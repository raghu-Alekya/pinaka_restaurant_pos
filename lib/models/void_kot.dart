class KotLineItemsResponse {
  final int restaurantId;
  final int zoneId;
  final int kotId;
  final double kotTotal;
  final String kotNumber;
  final List<KotItem> items;

  KotLineItemsResponse({
    required this.restaurantId,
    required this.zoneId,
    required this.kotId,
    required this.kotTotal,
    required this.kotNumber,
    required this.items,
  });

  factory KotLineItemsResponse.fromJson(Map<String, dynamic> json) {
    return KotLineItemsResponse(
      restaurantId: json["restaurant_id"] ?? 0,
      zoneId: json["zone_id"] ?? 0,
      kotId: json["kot_id"] ?? 0,
      kotTotal: (json["kot_total"] ?? 0).toDouble(),
      kotNumber: json["kot_number"] ?? "",
      items: (json["items"] as List? ?? [])
          .map((e) => KotItem.fromJson(e))
          .toList(),
    );
  }
}

class KotItem {
  final int id;
  final int productId;
  final String productName;
  final List<dynamic> attributes;
  int quantity;
  final double price;
  double amount;
  final List<String> modifiers;

  KotItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.attributes,
    required this.quantity,
    required this.price,
    required this.amount,
    required this.modifiers,
  });

  factory KotItem.fromJson(Map<String, dynamic> json) {
    return KotItem(
      id: json["id"] ?? 0,
      productId: json["product_id"] ?? 0,
      productName: json["product_name"] ?? "",
      attributes: json["attributes"] ?? [],
      quantity: json["quantity"] ?? 0,
      price: (json["price"] ?? 0).toDouble(),
      amount: (json["amount"] ?? 0).toDouble(),
      modifiers: (json["modifiers"] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  KotItem copyWith({
    int? id,
    int? productId,
    String? productName,
    List<dynamic>? attributes,
    int? quantity,
    double? price,
    double? amount,
    List<String>? modifiers,
  }) {
    return KotItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      attributes: attributes ?? List<dynamic>.from(this.attributes),
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      amount: amount ?? this.amount,
      modifiers: modifiers ?? List<String>.from(this.modifiers),
    );
  }


}
// class VoidItemSelectionRequest {
//   final int kotId;
//   final int restaurantId;
//   final int zoneId;
//   final List<VoidItemRequest> items;
//   final String remarks;
//
//   VoidItemSelectionRequest({
//     required this.kotId,
//     required this.restaurantId,
//     required this.zoneId,
//     required this.items,
//     required this.remarks,
//   });
//
//   Map<String, dynamic> toJson() {
//     return {
//       "kot_id": kotId,
//       "restaurant_id": restaurantId,
//       "zone_id": zoneId,
//       "items": items.map((e) => e.toJson()).toList(),
//       "remarks": remarks,
//     };
//   }
// }
//
// class VoidItemRequest {
//   final int itemId;
//   final bool isVoid;
//
//   VoidItemRequest({
//     required this.itemId,
//     required this.isVoid,
//   });
//
//   Map<String, dynamic> toJson() {
//     return {
//       "item_id": itemId,
//       "void": isVoid,
//     };
//   }
// }
// class VoidItemSelectionResponse {
//   final int restaurantId;
//   final int zoneId;
//   final int kotId;
//   final String kotNumber;
//   final String newKotTotal;
//   final VoidPayload payload;
//
//   VoidItemSelectionResponse({
//     required this.restaurantId,
//     required this.zoneId,
//     required this.kotId,
//     required this.kotNumber,
//     required this.newKotTotal,
//     required this.payload,
//   });
//
//   factory VoidItemSelectionResponse.fromJson(Map<String, dynamic> json) {
//     return VoidItemSelectionResponse(
//       restaurantId: json["restaurant_id"] ?? 0,
//       zoneId: json["zone_id"] ?? 0,
//       kotId: json["kot_id"] ?? 0,
//       kotNumber: json["kot_number"] ?? "",
//       newKotTotal: json["new_kot_total"]?.toString() ?? "0",
//       payload: VoidPayload.fromJson(json["payload"] ?? {}),
//     );
//   }
// }
//
// class VoidPayload {
//   final String flagType;
//   final int restaurantId;
//   final int zoneId;
//   final List<dynamic> lineItems; // you can change to model later
//   final String remarks;
//
//   VoidPayload({
//     required this.flagType,
//     required this.restaurantId,
//     required this.zoneId,
//     required this.lineItems,
//     required this.remarks,
//   });
//
//   factory VoidPayload.fromJson(Map<String, dynamic> json) {
//     return VoidPayload(
//       flagType: json["flag_type"] ?? "",
//       restaurantId: json["restaurant_id"] ?? 0,
//       zoneId: json["zone_id"] ?? 0,
//       lineItems: json["line_items"] ?? [],
//       remarks: json["remarks"] ?? "",
//     );
//   }
// }
//
class UpdatekotRequest {
  final List<LineItemUpdate> lineItems;
  final List<MetaDataItem> metaData;

  UpdatekotRequest({
    required this.lineItems,
    required this.metaData,
  });

  Map<String, dynamic> toJson() {
    return {
      "line_items": lineItems.map((e) => e.toJson()).toList(),
      "meta_data": metaData.map((e) => e.toJson()).toList(),
    };
  }
}

class LineItemUpdate {
  final int id;
  final int productId;
  final int quantity;

  LineItemUpdate({
    required this.id,
    required this.productId,
    required this.quantity,
  });

  Map<String, dynamic> toJson() => {
    "id": id,
    "product_id": productId,
    "quantity": quantity,
  };
}


class MetaDataItem {
  final String key;
  final dynamic value;

  MetaDataItem({
    required this.key,
    required this.value,
  });

  Map<String, dynamic> toJson() => {
    "key": key,
    "value": value,
  };
}
class UpdatekotResponse {
  final int id;
  final String status;
  final List<dynamic> lineItems;

  UpdatekotResponse({
    required this.id,
    required this.status,
    required this.lineItems,
  });

  factory UpdatekotResponse.fromJson(Map<String, dynamic> json) {
    return UpdatekotResponse(
      id: json["id"] ?? 0,
      status: json["status"] ?? "",
      lineItems: json["line_items"] ?? [],
    );
  }
}
