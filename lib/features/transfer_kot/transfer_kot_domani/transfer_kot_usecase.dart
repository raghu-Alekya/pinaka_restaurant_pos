import 'package:restaurant_captain_app/features/transfer_kot/transfer_kot_domani/transfer_kot_repository.dart';

class TransferKotUseCase {
  final TransferKotRepository repository;

  TransferKotUseCase({required this.repository});

  Future<void> call({
    required int orderId,
    required int kotId,
    required int fromTableId,
    required int toTableId,
    required int restaurantId,
    required int zoneId,
  }) async {
    return await repository.transferKot(
      orderId: orderId,
      kotId: kotId,
      fromTableId: fromTableId,
      toTableId: toTableId,
      restaurantId: restaurantId,
      zoneId: zoneId,
    );
  }
}