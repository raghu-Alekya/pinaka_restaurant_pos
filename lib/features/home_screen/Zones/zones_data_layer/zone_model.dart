import '../zones_domain/zone_entity.dart';

class ZoneResponse {
  final bool success;
  final String? message;
  final List<ZoneModel>? zoneDetails;

  ZoneResponse({
    required this.success,
    this.message,
    this.zoneDetails,
  });

  factory ZoneResponse.fromJson(Map<String, dynamic> json) {
    return ZoneResponse(
      success: json['success'] ?? false,
      message: json['message'],
      zoneDetails: json['zone_details'] != null
          ? List<ZoneModel>.from(
          json['zone_details'].map((x) => ZoneModel.fromJson(x)))
          : [],
    );
  }

  Map<String, dynamic> toJson() => {
    'success': success,
    'message': message,
    'zone_details': zoneDetails?.map((e) => e.toJson()).toList(),
  };

  List<ZoneEntity> toEntityList() =>
      zoneDetails?.map((e) => e.toEntity()).toList() ?? [];
}

class ZoneModel {
  final int? zoneId;
  final String? zoneName;
  final String? zoneStatus;
  final String? restaurantId;

  ZoneModel({
    this.zoneId,
    this.zoneName,
    this.zoneStatus,
    this.restaurantId,
  });

  factory ZoneModel.fromJson(Map<String, dynamic> json) {
    return ZoneModel(
      zoneId: json['zone_id'],
      zoneName: json['zone_name'],
      zoneStatus: json['zone_status'],
      restaurantId: json['restaurant_id'],
    );
  }

  Map<String, dynamic> toJson() => {
    'zone_id': zoneId,
    'zone_name': zoneName,
    'zone_status': zoneStatus,
    'restaurant_id': restaurantId,
  };

  ZoneEntity toEntity() => ZoneEntity(
    zoneId: zoneId,
    zoneName: zoneName,
    zoneStatus: zoneStatus,
    restaurantId: restaurantId,
  );
}