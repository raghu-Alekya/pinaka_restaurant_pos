

import 'package:restaurant_captain_app/features/transfer_kot/transfer_kot_data_layer/transfer_kot_remote_data_source.dart';

import '../../ captain_pin_login/captain_login_data_layer/captain_local_storage.dart';
import '../../ merchant_login/merchant_login_data_layer/merchant_local_storage.dart';
import '../transfer_kot_domani/transfer_kot_repository.dart';

class TransferKotRepositoryImpl implements TransferKotRepository {
  final TransferKotRemoteDataSource remoteDataSource;
  final MerchantLocalStorage merchantStorage;
  final CaptainLocalStorage captainStorage;

  TransferKotRepositoryImpl({
    required this.remoteDataSource,
    required this.merchantStorage,
    required this.captainStorage,
  });

  @override
  Future<void> transferKot({
    required int orderId,
    required int kotId,
    required int fromTableId,
    required int toTableId,
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
    await remoteDataSource.transferKot(
      baseUrl: baseUrl,
      token: token,
      orderId: orderId,
      kotId: kotId,
      fromTableId: fromTableId,
      toTableId: toTableId,
      restaurantId: restaurantId,
      zoneId: zoneId,
    );
  }
}