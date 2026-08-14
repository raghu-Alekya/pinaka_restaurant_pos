import 'bill_summary_entity.dart';
import 'bill_summary_repository.dart';

class BillSummaryUseCase {
  final BillSummaryRepository repository;

  BillSummaryUseCase({required this.repository});

  Future<BillSummaryEntity> call({
    required int orderId,
    required int restaurantId,
    required String orderType,
    required int zoneId,
  }) async {
    return await repository.getBillSummary(
      orderId: orderId,
      restaurantId: restaurantId,
      orderType: orderType,
      zoneId: zoneId,
    );
  }
}