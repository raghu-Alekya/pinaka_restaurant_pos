
import '../All_tables_list_domain/all_tables_list_entity.dart';

class AllTablesResponse {
  final bool success;
  final String? message;
  final List<TableModel>? tableDetails;

  AllTablesResponse({
    required this.success,
    this.message,
    this.tableDetails,
  });

  factory AllTablesResponse.fromJson(Map<String, dynamic> json) {
    return AllTablesResponse(
      success: json['success'] ?? false,
      message: json['message'],
      tableDetails: json['table_details'] != null
          ? List<TableModel>.from(
          json['table_details'].map((x) => TableModel.fromJson(x)))
          : [],
    );
  }

  Map<String, dynamic> toJson() => {
    'success': success,
    'message': message,
    'table_details': tableDetails?.map((e) => e.toJson()).toList(),
  };

  List<TableEntity> toEntityList() =>
      tableDetails?.map((e) => e.toEntity()).toList() ?? [];
}

class TableModel {
  final int? tableId;
  final String? tableName;
  final int? restaurantId;
  final String? capacity;
  final String? shape;
  final int? zoneId;
  final String? posX;
  final String? posY;
  final String? rotation;
  final String? dineInTime;
  final String? status;
  final bool? isMerged;
  final String? mergedTables;

  TableModel({
    this.tableId,
    this.tableName,
    this.restaurantId,
    this.capacity,
    this.shape,
    this.zoneId,
    this.posX,
    this.posY,
    this.rotation,
    this.dineInTime,
    this.status,
    this.isMerged,
    this.mergedTables,
  });

  factory TableModel.fromJson(Map<String, dynamic> json) {
    return TableModel(
      tableId: json['table_id'] is int
          ? json['table_id']
          : int.tryParse(json['table_id']?.toString() ?? ''),

      tableName: json['table_name']?.toString(),

      restaurantId: json['restaurant_id'] is int
          ? json['restaurant_id']
          : int.tryParse(json['restaurant_id']?.toString() ?? ''),

      capacity: json['capacity']?.toString(),
      shape: json['shape']?.toString(),

      zoneId: json['zone_id'] is int
          ? json['zone_id']
          : int.tryParse(json['zone_id']?.toString() ?? ''),

      posX: json['pos_x']?.toString(),
      posY: json['pos_y']?.toString(),
      rotation: json['rotation']?.toString(),
      dineInTime: json['dine_in_time']?.toString(),
      status: json['status']?.toString(),

      isMerged: json['is_merged'] is bool
          ? json['is_merged']
          : json['is_merged']?.toString().toLowerCase() == 'true',

      mergedTables: json['merged_tables']?.toString(),
    );
  }


  Map<String, dynamic> toJson() => {
    'table_id': tableId,
    'table_name': tableName,
    'restaurant_id': restaurantId,
    'capacity': capacity,
    'shape': shape,
    'zone_id': zoneId,
    'pos_x': posX,
    'pos_y': posY,
    'rotation': rotation,
    'dine_in_time': dineInTime,
    'status': status,
    'is_merged': isMerged,
    'merged_tables': mergedTables,
  };

  TableEntity toEntity() => TableEntity(
    tableId: tableId,
    tableName: tableName,
    restaurantId: restaurantId,
    capacity: capacity,
    shape: shape,
    zoneId: zoneId,
    posX: posX,
    posY: posY,
    rotation: rotation,
    dineInTime: dineInTime,
    status: status,
    isMerged: isMerged,
    mergedTables: mergedTables,
  );
}