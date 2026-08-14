
import '../../ captain_pin_login/captain_login_data_layer/captain_local_storage.dart';
import '../../ merchant_login/merchant_login_data_layer/merchant_local_storage.dart';
import '../../home_screen/All_tables_list/All_tables_list_data_layer/order_by_table_model.dart';
import '../kots_list_domin/kots_list_repository.dart';
import 'kots_list_remote_data_source.dart';

class KotsListRepositoryImpl implements KotsListRepository {
  final KotsListRemoteDataSource remoteDataSource;
  final MerchantLocalStorage merchantStorage;
  final CaptainLocalStorage captainStorage;

  KotsListRepositoryImpl({
    required this.remoteDataSource,
    required this.merchantStorage,
    required this.captainStorage,
  });

  @override
  Future<List<KotOrder>> getKotsList({
    required int parentOrderId,
    required int restaurantId,
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

    final response = await remoteDataSource.getKotsList(
      baseUrl: baseUrl,
      token: token,
      parentOrderId: parentOrderId,
      restaurantId: restaurantId,
      zoneId: zoneId,
    );

    return response.kotOrders;
  }
}