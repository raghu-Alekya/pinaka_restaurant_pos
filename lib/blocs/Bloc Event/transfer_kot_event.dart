abstract class TransKotEvent {}

class TransferKotEvent extends TransKotEvent {
  final int orderId;
  final int kotId;
  final int fromTableId;
  final int toTableId;
  final int restaurantId;
  final int zoneId;
  final String token;

  TransferKotEvent({
    required this.orderId,
    required this.kotId,
    required this.fromTableId,
    required this.toTableId,
    required this.restaurantId,
    required this.zoneId,
    required this.token,
  });
}
