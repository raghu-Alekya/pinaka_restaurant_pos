
import '../All_tables_list_data_layer/order_by_table_model.dart';
import 'order_by_table_entity.dart';

class GetOrderByTableUseCase {
  final OrderByTableRepository repository;

  GetOrderByTableUseCase({required this.repository});

  Future<OrderByTableResponse> call({
    required int restaurantId,
    required int tableId,
    required int zoneId,
  }) async {
    return await repository.getOrderByTable(
      restaurantId: restaurantId,
      tableId: tableId,
      zoneId: zoneId,
    );
  }
}