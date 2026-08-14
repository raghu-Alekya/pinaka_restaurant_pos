import '../All_tables_list_data_layer/order_by_table_model.dart';

abstract class OrderByTableRepository {
  Future<OrderByTableResponse> getOrderByTable({
    required int restaurantId,
    required int tableId,
    required int zoneId,
  });
}