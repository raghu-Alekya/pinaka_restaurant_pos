import 'bill_summary_entity.dart';

abstract class BillSummaryRepository {
  Future<BillSummaryEntity> getBillSummary({
    required int orderId,
    required int restaurantId,
    required String orderType,
    required int zoneId,
  });
}