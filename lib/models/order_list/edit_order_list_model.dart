class OrderListLineItems {
  final int id;
  final int quantity;

  OrderListLineItems({required this.id, required this.quantity});

  Map<String, dynamic> toJson() => {
    'id': id,
    'quantity': quantity,
  };
}

class OrderListMetaData {
  final String key;
  final String value;

  OrderListMetaData({required this.key, required this.value});

  Map<String, dynamic> toJson() => {
    'key': key,
    'value': value,
  };
}



class EditOrderRequest {
  final List<OrderListLineItems> lineItems;
  final List<OrderListMetaData> metaData;

  EditOrderRequest({required this.lineItems, required this.metaData});

  Map<String, dynamic> toJson() => {
    'line_items': lineItems.map((e) => e.toJson()).toList(),
    'meta_data': metaData.map((e) => e.toJson()).toList(),
  };
}