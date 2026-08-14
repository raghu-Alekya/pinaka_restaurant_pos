
import '../addons_domin/addon_entity.dart';

class AddOnModel {
  final int id;
  final int restaurantId;
  final String name;
  final double price;
  final String type;

  AddOnModel({
    required this.id,
    required this.restaurantId,
    required this.name,
    required this.price,
    required this.type,
  });

  factory AddOnModel.fromJson(Map<String, dynamic> json) {
    return AddOnModel(
      id: json['id'] ?? 0,
      restaurantId: json['restaurant_id'] ?? 0,
      name: json['name'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      type: json['type'] ?? '',
    );
  }

  AddOnEntity toEntity() => AddOnEntity(
    id: id,
    restaurantId: restaurantId,
    name: name,
    price: price,
    type: type,
  );
}

class AddOnsResponse {
  final String status;
  final List<AddOnModel> data;

  AddOnsResponse({
    required this.status,
    required this.data,
  });

  factory AddOnsResponse.fromJson(Map<String, dynamic> json) {
    return AddOnsResponse(
      status: json['status'] ?? '',
      data: (json['data'] as List?)
          ?.map((e) => AddOnModel.fromJson(e))
          .toList() ??
          [],
    );
  }
}