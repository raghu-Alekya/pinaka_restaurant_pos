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
  final String? mergeRole;           // "parent" | "child"
  final List<String>? childTableIds; // present when merge_role == "parent"
  final int? parentTableId;          // present when merge_role == "child"
  final String? mergedTables;
  final int? orderId;
  final String? orderAmount;

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
    this.mergeRole,
    this.childTableIds,
    this.parentTableId,
    this.mergedTables,
    this.orderId,
    this.orderAmount,
  });
}