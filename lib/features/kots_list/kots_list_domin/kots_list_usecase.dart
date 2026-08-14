
import '../../home_screen/All_tables_list/All_tables_list_data_layer/order_by_table_model.dart';
import 'kots_list_repository.dart';

class KotsListUseCase {
  final KotsListRepository repository;

  KotsListUseCase({required this.repository});

  Future<List<KotOrder>> call({
    required int parentOrderId,
    required int restaurantId,
    required int zoneId,
  }) async {
    return await repository.getKotsList(
      parentOrderId: parentOrderId,
      restaurantId: restaurantId,
      zoneId: zoneId,
    );
  }
}