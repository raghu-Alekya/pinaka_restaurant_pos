abstract class TransferKotRepository {
  Future<void> transferKot({
    required int orderId,
    required int kotId,
    required int fromTableId,
    required int toTableId,
    required int restaurantId,
    required int zoneId,
  });
}