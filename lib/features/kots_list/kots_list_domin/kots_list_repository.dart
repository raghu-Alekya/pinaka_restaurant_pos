import '../../home_screen/All_tables_list/All_tables_list_data_layer/order_by_table_model.dart';

abstract class KotsListRepository {
  Future<List<KotOrder>> getKotsList({
    required int parentOrderId,
    required int restaurantId,
    required int zoneId,
  });
}