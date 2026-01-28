class TableModel {
  final int tableId;
  final String tableName;
  final int restaurantId;
  final int capacity;
  final String tableShape;
  final int zoneId;
  final double posX;
  final double posY;
  final double rotation;

  TableModel({
    required this.tableId,
    required this.tableName,
    required this.restaurantId,
    required this.capacity,
    required this.tableShape,
    required this.zoneId,
    required this.posX,
    required this.posY,
    required this.rotation,
  });

  factory TableModel.fromJson(Map<String, dynamic> json) {
    return TableModel(
      tableId: json['table_id'],
      tableName: json['table_name'],
      restaurantId: int.parse(json['restaurant_id']),
      capacity: int.parse(json['capacity']),
      tableShape: json['table_shape'],
      zoneId: int.parse(json['zone_id']),
      posX: double.parse(json['pos_x'].toString()),
      posY: double.parse(json['pos_y'].toString()),
      rotation: double.parse(json['rotation'].toString()),
    );
  }
}
