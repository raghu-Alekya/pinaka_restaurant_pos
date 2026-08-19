class TableEntity {
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
  final int? orderId;
  final String? orderAmount; // 👈 new

  TableEntity({
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
    this.orderId,
    this.orderAmount,
  });
}