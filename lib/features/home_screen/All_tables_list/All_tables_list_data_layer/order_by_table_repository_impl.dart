

import '../../../ captain_pin_login/captain_login_data_layer/captain_local_storage.dart';
import '../../../ merchant_login/merchant_login_data_layer/merchant_local_storage.dart';
import '../All_tables_list_domain/order_by_table_entity.dart';
import 'order_by_table_model.dart';
import 'order_by_table_remote_data_source.dart';

class OrderByTableRepositoryImpl implements OrderByTableRepository {
  final OrderByTableRemoteDataSource remoteDataSource;
  final MerchantLocalStorage merchantStorage;
  final CaptainLocalStorage captainStorage;

  OrderByTableRepositoryImpl({
    required this.remoteDataSource,
    required this.merchantStorage,
    required this.captainStorage,
  });

  @override
  Future<OrderByTableResponse> getOrderByTable({
    required int restaurantId,
    required int tableId,
    required int zoneId,
  }) async {
    final baseUrl = await merchantStorage.getStoreBaseUrl();
    if (baseUrl == null || baseUrl.isEmpty) {
      throw Exception('Store base URL not found.');
    }

    final captainData = await captainStorage.getCaptainData();
    final token = captainData?.data?.token;
    if (token == null || token.isEmpty) {
      throw Exception('Captain token not found.');
    }

    return await remoteDataSource.getOrderByTable(
      baseUrl: baseUrl,
      token: token,
      restaurantId: restaurantId,
      tableId: tableId,
      zoneId: zoneId,
    );
  }
}